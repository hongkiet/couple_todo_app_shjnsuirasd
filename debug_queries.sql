-- Debug queries để kiểm tra Supabase setup
-- Chạy các query này trong Supabase SQL Editor để debug

-- 1. Kiểm tra user hiện tại
SELECT auth.uid() as current_user_id;

-- 2. Kiểm tra các bảng có tồn tại không
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('couples', 'couple_members', 'tasks');

-- 3. Kiểm tra RLS có enabled không
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('couples', 'couple_members', 'tasks');

-- 4. Kiểm tra policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('couples', 'couple_members', 'tasks');

-- 5. Kiểm tra function join_couple có tồn tại không
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'join_couple';

-- 6. Test query couple_members (giống như trong app)
-- Thay 'your-user-id' bằng user_id thật từ query 1
SELECT couple_id 
FROM couple_members 
WHERE user_id = 'your-user-id' 
LIMIT 1;

-- 7. Kiểm tra permissions
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name IN ('couples', 'couple_members', 'tasks')
AND grantee IN ('anon', 'authenticated');
