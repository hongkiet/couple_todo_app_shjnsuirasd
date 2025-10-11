# Hướng dẫn setup Supabase cho Couple Todo App

## Cách chạy migrations

### Bước 1: Tạo project Supabase

1. Đăng nhập vào [Supabase Dashboard](https://supabase.com/dashboard)
2. Tạo project mới
3. Lưu lại URL và anon key để config trong Flutter app

### Bước 2: Chạy migrations theo thứ tự

Chạy các file migration theo thứ tự sau trong Supabase SQL Editor:

1. **migration_001_create_tables.sql** - Tạo các bảng cơ bản
2. **migration_002_indexes_functions.sql** - Tạo indexes và functions
3. **migration_003_triggers_policies.sql** - Tạo triggers và RLS policies
4. **migration_004_permissions.sql** - Grant permissions

### Bước 3: Cấu hình Authentication

1. Vào Authentication > Settings
2. Enable Email authentication
3. Có thể thêm Google/GitHub OAuth nếu muốn

### Bước 4: Test schema

Chạy các query test sau để kiểm tra:

```sql
-- Test tạo couple
INSERT INTO couples (code) VALUES ('ABC123');

-- Test function join_couple
SELECT join_couple('ABC123');

-- Test tạo task
INSERT INTO tasks (couple_id, title, created_by)
VALUES ('your-couple-id', 'Test task', 'your-user-id');
```

## Cấu trúc Database

### Bảng `couples`

- `id`: UUID primary key
- `code`: Mã 6 ký tự để ghép đôi
- `created_at`, `updated_at`: Timestamps

### Bảng `couple_members`

- `id`: UUID primary key
- `couple_id`: Foreign key đến couples
- `user_id`: Foreign key đến auth.users
- `role`: 'owner' hoặc 'member'
- `joined_at`: Timestamp khi join

### Bảng `tasks`

- `id`: UUID primary key
- `couple_id`: Foreign key đến couples
- `title`: Tiêu đề task
- `note`: Ghi chú (optional)
- `due_at`: Deadline (optional)
- `is_done`: Trạng thái hoàn thành
- `created_by`: User tạo task
- `created_at`, `updated_at`: Timestamps

## Row Level Security (RLS)

Tất cả bảng đều có RLS enabled với các policies:

- Users chỉ có thể xem/sửa data của couple họ tham gia
- Chỉ owner có thể remove members
- Tasks được chia sẻ trong couple

## Functions

### `join_couple(p_code TEXT)`

Function để join couple bằng code:

- Kiểm tra code hợp lệ
- Kiểm tra user chưa trong couple nào
- Thêm user vào couple với role 'member'
- Trả về couple_id

## Troubleshooting

### Lỗi thường gặp:

1. **"User not authenticated"**: Kiểm tra Supabase client config
2. **"Invalid couple code"**: Code không tồn tại hoặc sai format
3. **"User already in another couple"**: User đã trong couple khác
4. **RLS policy errors**: Kiểm tra policies và user permissions

### Debug queries:

```sql
-- Kiểm tra user hiện tại
SELECT auth.uid();

-- Kiểm tra couples của user
SELECT c.* FROM couples c
JOIN couple_members cm ON c.id = cm.couple_id
WHERE cm.user_id = auth.uid();

-- Kiểm tra tasks của couple
SELECT t.* FROM tasks t
JOIN couple_members cm ON t.couple_id = cm.couple_id
WHERE cm.user_id = auth.uid();
```
