-- Migration Cleanup: Xóa các function và trigger cũ nếu cần
-- Chạy file này nếu gặp lỗi với các function/trigger đã tồn tại

-- Drop functions
DROP FUNCTION IF EXISTS join_couple(TEXT);
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop triggers
DROP TRIGGER IF EXISTS update_couples_updated_at ON couples;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;

-- Drop policies (nếu cần reset)
DROP POLICY IF EXISTS "Users can view couples they belong to" ON couples;
DROP POLICY IF EXISTS "Users can create couples" ON couples;
DROP POLICY IF EXISTS "Users can view their own couple memberships" ON couple_members;
DROP POLICY IF EXISTS "Users can view members of their couple" ON couple_members;
DROP POLICY IF EXISTS "Users can join couples" ON couple_members;
DROP POLICY IF EXISTS "Owners can remove members" ON couple_members;
DROP POLICY IF EXISTS "Users can view tasks from their couple" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their couple" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks in their couple" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks in their couple" ON tasks;

-- Disable RLS (nếu cần reset)
ALTER TABLE couples DISABLE ROW LEVEL SECURITY;
ALTER TABLE couple_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
