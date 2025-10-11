-- Migration 3: Tạo triggers và RLS policies
-- Chạy migration này sau migration_002_indexes_functions.sql

-- 1. Tạo triggers để tự động cập nhật updated_at
CREATE TRIGGER update_couples_updated_at 
    BEFORE UPDATE ON couples 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Enable Row Level Security (RLS) cho tất cả bảng
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 3. Policies cho couples table
CREATE POLICY "Users can view couples they belong to" ON couples
    FOR SELECT USING (
        id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create couples" ON couples
    FOR INSERT WITH CHECK (true);

-- 4. Policies cho couple_members table
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

-- 5. Policies cho tasks table
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
