-- Emergency Fix: Disable RLS temporarily để test
-- Chạy file này nếu muốn test nhanh mà không bị RLS block

-- 1. Disable RLS cho tất cả bảng
ALTER TABLE couples DISABLE ROW LEVEL SECURITY;
ALTER TABLE couple_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

-- 2. Drop tất cả policies
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

-- 3. Grant permissions để đảm bảo access
GRANT ALL ON couples TO anon, authenticated;
GRANT ALL ON couple_members TO anon, authenticated;
GRANT ALL ON tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION join_couple(TEXT) TO anon, authenticated;
