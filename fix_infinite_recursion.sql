-- Fix infinite recursion trong RLS policies
-- Chạy file này để sửa lỗi infinite recursion

-- 1. Drop policies có vấn đề
DROP POLICY IF EXISTS "Users can view couples they belong to" ON couples;
DROP POLICY IF EXISTS "Users can view members of their couple" ON couple_members;
DROP POLICY IF EXISTS "Users can view tasks from their couple" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their couple" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks in their couple" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks in their couple" ON tasks;

-- 2. Tạo lại policies đơn giản hơn, tránh infinite recursion

-- Policy cho couples - chỉ cho phép xem couples mà user là member
CREATE POLICY "Users can view their couples" ON couples
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM couple_members 
            WHERE couple_members.couple_id = couples.id 
            AND couple_members.user_id = auth.uid()
        )
    );

-- Policy cho couple_members - chỉ cho phép xem records của chính user
CREATE POLICY "Users can view own memberships" ON couple_members
    FOR SELECT USING (user_id = auth.uid());

-- Policy cho tasks - sử dụng EXISTS để tránh infinite recursion
CREATE POLICY "Users can view tasks from their couple" ON tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM couple_members 
            WHERE couple_members.couple_id = tasks.couple_id 
            AND couple_members.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create tasks in their couple" ON tasks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM couple_members 
            WHERE couple_members.couple_id = tasks.couple_id 
            AND couple_members.user_id = auth.uid()
        ) AND created_by = auth.uid()
    );

CREATE POLICY "Users can update tasks in their couple" ON tasks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM couple_members 
            WHERE couple_members.couple_id = tasks.couple_id 
            AND couple_members.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete tasks in their couple" ON tasks
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM couple_members 
            WHERE couple_members.couple_id = tasks.couple_id 
            AND couple_members.user_id = auth.uid()
        )
    );
