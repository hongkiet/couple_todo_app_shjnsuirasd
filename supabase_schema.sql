-- Schema cho Couple Todo App
-- Tạo các bảng và function cần thiết cho ứng dụng

-- 1. Bảng couples - Lưu thông tin cặp đôi
CREATE TABLE IF NOT EXISTS couples (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(6) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Bảng couple_members - Lưu thông tin thành viên của cặp đôi
CREATE TABLE IF NOT EXISTS couple_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(couple_id, user_id)
);

-- 3. Bảng tasks - Lưu thông tin nhiệm vụ
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    note TEXT,
    due_at TIMESTAMP WITH TIME ZONE,
    is_done BOOLEAN DEFAULT FALSE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tạo indexes để tối ưu performance
CREATE INDEX IF NOT EXISTS idx_couples_code ON couples(code);
CREATE INDEX IF NOT EXISTS idx_couple_members_couple_id ON couple_members(couple_id);
CREATE INDEX IF NOT EXISTS idx_couple_members_user_id ON couple_members(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_couple_id ON tasks(couple_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_is_done ON tasks(is_done);

-- 5. Function để join couple bằng code
CREATE OR REPLACE FUNCTION join_couple(p_code TEXT)
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

-- 6. Function để tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Tạo triggers để tự động cập nhật updated_at
CREATE TRIGGER update_couples_updated_at 
    BEFORE UPDATE ON couples 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Row Level Security (RLS) Policies

-- Enable RLS cho tất cả bảng
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policies cho couples table
CREATE POLICY "Users can view couples they belong to" ON couples
    FOR SELECT USING (
        id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create couples" ON couples
    FOR INSERT WITH CHECK (true);

-- Policies cho couple_members table
CREATE POLICY "Users can view their own couple memberships" ON couple_members
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view members of their couple" ON couple_members
    FOR SELECT USING (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can join couples" ON couple_members
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Owners can remove members" ON couple_members
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM couple_members cm 
            WHERE cm.couple_id = couple_members.couple_id 
            AND cm.user_id = auth.uid() 
            AND cm.role = 'owner'
        )
    );

-- Policies cho tasks table
CREATE POLICY "Users can view tasks from their couple" ON tasks
    FOR SELECT USING (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create tasks in their couple" ON tasks
    FOR INSERT WITH CHECK (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        ) AND created_by = auth.uid()
    );

CREATE POLICY "Users can update tasks in their couple" ON tasks
    FOR UPDATE USING (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete tasks in their couple" ON tasks
    FOR DELETE USING (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

-- 9. Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON couples TO anon, authenticated;
GRANT ALL ON couple_members TO anon, authenticated;
GRANT ALL ON tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION join_couple(TEXT) TO anon, authenticated;
