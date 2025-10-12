-- Migration để thêm bảng weekly_tasks
-- Chạy file này trong Supabase SQL Editor

-- 1. Tạo bảng weekly_tasks
CREATE TABLE IF NOT EXISTS weekly_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    note TEXT,
    week_start DATE NOT NULL, -- Ngày đầu tuần (Thứ 2)
    week_end DATE NOT NULL,   -- Ngày cuối tuần (Chủ nhật)
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7), -- 1=Thứ 2, 7=Chủ nhật
    is_done BOOLEAN DEFAULT FALSE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tạo indexes để tối ưu performance
CREATE INDEX IF NOT EXISTS idx_weekly_tasks_couple_id ON weekly_tasks(couple_id);
CREATE INDEX IF NOT EXISTS idx_weekly_tasks_week_start ON weekly_tasks(week_start);
CREATE INDEX IF NOT EXISTS idx_weekly_tasks_day_of_week ON weekly_tasks(day_of_week);
CREATE INDEX IF NOT EXISTS idx_weekly_tasks_created_by ON weekly_tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_weekly_tasks_is_done ON weekly_tasks(is_done);

-- 3. Tạo composite index để query theo couple và tuần
CREATE INDEX IF NOT EXISTS idx_weekly_tasks_couple_week ON weekly_tasks(couple_id, week_start);

-- 4. Tạo trigger để tự động cập nhật updated_at
CREATE TRIGGER update_weekly_tasks_updated_at 
    BEFORE UPDATE ON weekly_tasks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Enable RLS
ALTER TABLE weekly_tasks ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies cho weekly_tasks table
CREATE POLICY "Users can view weekly tasks from their couple" ON weekly_tasks
    FOR SELECT USING (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create weekly tasks in their couple" ON weekly_tasks
    FOR INSERT WITH CHECK (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        ) AND created_by = auth.uid()
    );

CREATE POLICY "Users can update weekly tasks in their couple" ON weekly_tasks
    FOR UPDATE USING (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete weekly tasks in their couple" ON weekly_tasks
    FOR DELETE USING (
        couple_id IN (
            SELECT couple_id FROM couple_members 
            WHERE user_id = auth.uid()
        )
    );

-- 7. Grant permissions
GRANT ALL ON weekly_tasks TO anon, authenticated;

-- 8. Function để lấy tuần hiện tại
CREATE OR REPLACE FUNCTION get_current_week()
RETURNS TABLE(week_start DATE, week_end DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Tính ngày Thứ 2 của tuần hiện tại
    RETURN QUERY
    SELECT 
        (CURRENT_DATE - INTERVAL '1 day' * (EXTRACT(DOW FROM CURRENT_DATE) - 1))::DATE as week_start,
        (CURRENT_DATE - INTERVAL '1 day' * (EXTRACT(DOW FROM CURRENT_DATE) - 1) + INTERVAL '6 days')::DATE as week_end;
END;
$$;

-- 9. Function để lấy tuần của một ngày cụ thể
CREATE OR REPLACE FUNCTION get_week_for_date(input_date DATE)
RETURNS TABLE(week_start DATE, week_end DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (input_date - INTERVAL '1 day' * (EXTRACT(DOW FROM input_date) - 1))::DATE as week_start,
        (input_date - INTERVAL '1 day' * (EXTRACT(DOW FROM input_date) - 1) + INTERVAL '6 days')::DATE as week_end;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_current_week() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_week_for_date(DATE) TO anon, authenticated;
