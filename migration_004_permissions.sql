-- Migration 4: Grant permissions
-- Chạy migration này cuối cùng

-- Grant permissions cho các role
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON couples TO anon, authenticated;
GRANT ALL ON couple_members TO anon, authenticated;
GRANT ALL ON tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION join_couple(TEXT) TO anon, authenticated;
