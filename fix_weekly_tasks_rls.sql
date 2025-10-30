-- Fix infinite recursion trong RLS policies cho weekly_tasks
-- File này sửa policies của weekly_tasks để tránh infinite recursion

-- 1. Drop policies cũ có vấn đề
DROP POLICY IF EXISTS "Users can view weekly tasks from their couple" ON weekly_tasks;
DROP POLICY IF EXISTS "Users can create weekly tasks in their couple" ON weekly_tasks;
DROP POLICY IF EXISTS "Users can update weekly tasks in their couple" ON weekly_tasks;
DROP POLICY IF EXISTS "Users can delete weekly tasks in their couple" ON weekly_tasks;

-- 2. Tạo RPC function để lấy couple_id mà không gặp recursion
-- (Đã tạo trong migration_002, nhưng tạo lại để chắc chắn)
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

-- 3. Tạo policies mới sử dụng RPC function thay vì query trực tiếp
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

-- 4. Fix unpair function - Tạo RPC function để xóa membership mà không gặp infinite recursion
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

    -- Xóa membership của user hiện tại
    DELETE FROM couple_members WHERE user_id = v_user_id;

    -- Nếu không còn member nào -> xóa couple
    IF NOT EXISTS (SELECT 1 FROM couple_members WHERE couple_id = v_couple_id) THEN
        DELETE FROM couples WHERE id = v_couple_id;
        RETURN;
    END IF;

    -- Nếu còn đúng 1 member -> set người đó thành owner
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

-- Grant permission
GRANT EXECUTE ON FUNCTION leave_couple() TO anon, authenticated;

