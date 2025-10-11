-- Migration 2: Tạo indexes và function
-- Chạy migration này sau migration_001_create_tables.sql

-- 1. Tạo indexes để tối ưu performance
CREATE INDEX IF NOT EXISTS idx_couples_code ON couples(code);
CREATE INDEX IF NOT EXISTS idx_couple_members_couple_id ON couple_members(couple_id);
CREATE INDEX IF NOT EXISTS idx_couple_members_user_id ON couple_members(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_couple_id ON tasks(couple_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_is_done ON tasks(is_done);

-- 2. Function để join couple bằng code
-- Drop function nếu đã tồn tại để tránh lỗi thay đổi return type
DROP FUNCTION IF EXISTS join_couple(TEXT);

CREATE FUNCTION join_couple(p_code TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_couple_id UUID;
    v_user_id UUID;
BEGIN
    -- Lấy user_id hiện tại
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Tìm couple với code
    SELECT id INTO v_couple_id 
    FROM couples 
    WHERE code = UPPER(p_code);
    
    IF v_couple_id IS NULL THEN
        RAISE EXCEPTION 'Invalid couple code';
    END IF;

    -- Kiểm tra user đã trong couple này chưa
    IF EXISTS (
        SELECT 1 FROM couple_members 
        WHERE couple_id = v_couple_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User already in this couple';
    END IF;

    -- Kiểm tra user đã trong couple khác chưa
    IF EXISTS (
        SELECT 1 FROM couple_members 
        WHERE user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User already in another couple';
    END IF;

    -- Thêm user vào couple
    INSERT INTO couple_members (couple_id, user_id, role)
    VALUES (v_couple_id, v_user_id, 'member');

    RETURN v_couple_id::TEXT;
END;
$$;

-- 3. Function để tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
