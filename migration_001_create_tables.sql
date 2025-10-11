-- Migration 1: Tạo các bảng cơ bản
-- Chạy migration này trước tiên

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
