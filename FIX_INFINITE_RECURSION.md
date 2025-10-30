# Fix Infinite Recursion Error

## Vấn đề

Sau khi pairing, ứng dụng gặp lỗi:

```
infinite recursion detected in policy for relation "couple_members"
```

## Nguyên nhân

RLS policy trong database đang tạo vòng lặp vô hạn khi query từ bảng `couple_members`.

## Giải pháp

### Bước 1: Chạy file SQL fix trong Supabase

1. Mở [Supabase Dashboard](https://supabase.com/dashboard)
2. Vào SQL Editor
3. Chạy file `fix_infinite_recursion.sql` từ database.zip
4. Hoặc chạy SQL sau:

```sql
-- Tạo RPC functions để tránh infinite recursion
CREATE OR REPLACE FUNCTION get_my_couple_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT couple_id
  FROM couple_members
  WHERE user_id = auth.uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION has_couple()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS(
    SELECT 1
    FROM couple_members
    WHERE user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION is_couple_complete(p_couple_id UUID)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COUNT(*) >= 2
  FROM couple_members
  WHERE couple_id = p_couple_id;
$$;

-- Drop policy gây infinite recursion
DROP POLICY IF EXISTS "Users can view members of their couple" ON couple_members;
```

### Bước 2: Fix infinite recursion cho `weekly_tasks` table

HomePage cũng bị infinite recursion khi query `weekly_tasks`. Chạy SQL sau:

```sql
-- Drop policies cũ có vấn đề
DROP POLICY IF EXISTS "Users can view weekly tasks from their couple" ON weekly_tasks;
DROP POLICY IF EXISTS "Users can create weekly tasks in their couple" ON weekly_tasks;
DROP POLICY IF EXISTS "Users can update weekly tasks in their couple" ON weekly_tasks;
DROP POLICY IF EXISTS "Users can delete weekly tasks in their couple" ON weekly_tasks;

-- Tạo policies mới sử dụng RPC function
CREATE POLICY "Users can view weekly tasks from their couple" ON weekly_tasks
    FOR SELECT USING (
        couple_id = (SELECT get_my_couple_id())
    );

CREATE POLICY "Users can create weekly tasks in their couple" ON weekly_tasks
    FOR INSERT WITH CHECK (
        couple_id = (SELECT get_my_couple_id())
        AND created_by = auth.uid()
    );

CREATE POLICY "Users can update weekly tasks in their couple" ON weekly_tasks
    FOR UPDATE USING (
        couple_id = (SELECT get_my_couple_id())
    );

CREATE POLICY "Users can delete weekly tasks in their couple" ON weekly_tasks
    FOR DELETE USING (
        couple_id = (SELECT get_my_couple_id())
    );
```

### Bước 3: Fix unpair function

Chức năng rời couple cũng bị infinite recursion. Chạy SQL sau:

```sql
-- Tạo RPC function để unpair mà không gặp infinite recursion
CREATE OR REPLACE FUNCTION leave_couple()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_couple_id UUID;
    v_remaining_user UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Lấy couple_id của user
    SELECT couple_id INTO v_couple_id
    FROM couple_members
    WHERE user_id = v_user_id
    LIMIT 1;

    IF v_couple_id IS NULL THEN
        RETURN; -- User chưa trong couple nào
    END IF;

    -- Xóa membership
    DELETE FROM couple_members WHERE user_id = v_user_id;

    -- Không còn ai -> xóa couple
    IF NOT EXISTS (SELECT 1 FROM couple_members WHERE couple_id = v_couple_id) THEN
        DELETE FROM couples WHERE id = v_couple_id;
        RETURN;
    END IF;

    -- Còn đúng 1 người -> gán owner cho người còn lại
    SELECT user_id INTO v_remaining_user
    FROM couple_members
    WHERE couple_id = v_couple_id
    LIMIT 1;

    IF v_remaining_user IS NOT NULL THEN
        UPDATE couple_members
        SET role = 'owner'
        WHERE couple_id = v_couple_id AND user_id = v_remaining_user;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION leave_couple() TO anon, authenticated;
```

### Bước 4: Test lại app

1. Chạy `flutter run`
2. Thử pairing lại
3. App sẽ tự động chuyển vào HomePage sau khi pairing thành công
4. HomePage sẽ load tasks bình thường, không còn infinite loading

## Thay đổi trong code

- Sử dụng RPC functions (`get_my_couple_id`, `has_couple`) thay vì query trực tiếp
- Tránh infinite recursion trong RLS policies
- **Flow mới**: Chỉ vào HomePage khi couple đã có đủ 2 members
  - Người tạo code: Vẫn ở PairingPage, chờ người kia join
  - Người join: Chuyển vào HomePage ngay sau khi join
  - Cả hai: Chuyển vào HomePage khi đủ 2 members (qua realtime listener)
- Code đã được cập nhật trong:
  - `lib/features/couple/couple_repository.dart` - Sửa `unpairCouple()` và `myCoupleId()` để dùng RPC functions, thêm `isCoupleComplete()`
  - `lib/features/auth/auth_gate.dart` - Sửa `_hasCouple()` để dùng RPC function
  - `lib/app/main_navigation.dart` - Kiểm tra `isCoupleComplete` trước khi vào HomePage
  - `lib/features/couple/pairing_page.dart` - Thêm polling backup, chỉ reload khi có đủ 2 members

## Xem thêm

- `database.zip` - Chứa tất cả file migration
- `README_SUPABASE_SETUP.md` - Hướng dẫn setup đầy đủ
