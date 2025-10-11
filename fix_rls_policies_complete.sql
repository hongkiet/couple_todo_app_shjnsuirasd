-- Fix RLS policies - Thêm policies còn thiếu
-- Chạy file này để sửa lỗi "new row violates row-level security policy for table couples"

-- 1. Drop tất cả policies cũ để reset
DROP POLICY IF EXISTS "Users can view couples they belong to" ON couples;
DROP POLICY IF EXISTS "Users can create couples" ON couples;
DROP POLICY IF EXISTS "Users can view their couples" ON couples;
DROP POLICY IF EXISTS "Users can view their own couple memberships" ON couple_members;
DROP POLICY IF EXISTS "Users can view members of their couple" ON couple_members;
DROP POLICY IF EXISTS "Users can view own memberships" ON couple_members;
DROP POLICY IF EXISTS "Users can join couples" ON couple_members;
DROP POLICY IF EXISTS "Owners can remove members" ON couple_members;
DROP POLICY IF EXISTS "Users can view tasks from their couple" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their couple" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks in their couple" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks in their couple" ON tasks;

-- 2. Tạo policies đầy đủ và đơn giản

-- Policies cho couples table
CREATE POLICY "Users can create couples" ON couples
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their couples" ON couples
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM couple_members 
            WHERE couple_members.couple_id = couples.id 
            AND couple_members.user_id = auth.uid()
        )
    );

-- Policies cho couple_members table
CREATE POLICY "Users can view own memberships" ON couple_members
    FOR SELECT USING (user_id = auth.uid());

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
