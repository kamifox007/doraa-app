-- ====================================================
-- Migration: Add fcm_token to profiles
-- ====================================================

-- 1. إضافة الحقل لملف السائقات
ALTER TABLE driver_profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. إضافة الحقل لملف الراكبات
ALTER TABLE rider_profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;
