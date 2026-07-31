-- ==============================================================================
-- إصلاح الجداول: إضافة الأعمدة الجديدة التي لم تكن موجودة في الجداول القديمة
-- ==============================================================================

-- إضافة الأعمدة لجدول السائقات
ALTER TABLE public.driver_profiles 
  ADD COLUMN IF NOT EXISTS vehicle_approval_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS total_rides INTEGER DEFAULT 0;

-- إضافة الأعمدة لجدول المستندات
ALTER TABLE public.documents 
  ADD COLUMN IF NOT EXISTS admin_notes TEXT;
