-- ============================================================
-- Migration: Cleanup + Missing Features
-- ============================================================
-- الخطوة 1: إزالة الجداول المكررة
-- ============================================================

-- حذف جدول support_tickets (مكرر من safety_reports)
DROP TABLE IF EXISTS support_tickets CASCADE;

-- حذف جدول emergency_alerts (يمكن الاستغناء عنه مع safety_reports)
DROP TABLE IF EXISTS emergency_alerts CASCADE;

-- ============================================================
-- الخطوة 2: تحسين جدول safety_reports الأصلي
-- (إضافة حقل admin_resolution إذا لم يكن موجوداً)
-- ============================================================

ALTER TABLE safety_reports
  ADD COLUMN IF NOT EXISTS admin_resolution TEXT;

-- تأكد أن enum safety_status يحتوي على كل الحالات
-- (إذا فشل الأمر بعدم وجود القيمة، يمكن تجاهله)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'dismissed'
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'safety_status')
  ) THEN
    ALTER TYPE safety_status ADD VALUE 'dismissed';
  END IF;
END$$;

-- ============================================================
-- الخطوة 3: إضافة حقول مفقودة في user_profiles
-- ============================================================

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS subscription_expiry TIMESTAMPTZ;

-- ============================================================
-- الخطوة 4: RLS - السماح للإدارة بقراءة جميع الشكاوى
-- ============================================================

-- إضافة سياسة للإدارة لقراءة كل الشكاوى
DROP POLICY IF EXISTS safety_reports_admin_select ON safety_reports;
CREATE POLICY safety_reports_admin_select ON safety_reports
  FOR SELECT
  USING (
    reporter_id = auth.uid()
    OR EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- إضافة سياسة للإدارة لتعديل حالة الشكوى
DROP POLICY IF EXISTS safety_reports_admin_update ON safety_reports;
CREATE POLICY safety_reports_admin_update ON safety_reports
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- الخطوة 5: RLS - السماح للإدارة برؤية وثائق السائقات
-- ============================================================

DROP POLICY IF EXISTS documents_admin_read ON documents;
CREATE POLICY documents_admin_read ON documents
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS documents_admin_update ON documents;
CREATE POLICY documents_admin_update ON documents
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- الخطوة 6: RLS - السماح للإدارة برؤية driver_profiles
-- ============================================================

DROP POLICY IF EXISTS driver_profiles_admin_read ON driver_profiles;
CREATE POLICY driver_profiles_admin_read ON driver_profiles
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS driver_profiles_admin_update ON driver_profiles;
CREATE POLICY driver_profiles_admin_update ON driver_profiles
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- الخطوة 7: RLS - الإدارة ترى كل الرحلات النشطة
-- ============================================================

DROP POLICY IF EXISTS rides_admin_select ON rides;
CREATE POLICY rides_admin_select ON rides
  FOR SELECT
  USING (
    rider_id = auth.uid()
    OR driver_id = auth.uid()
    OR EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- الخطوة 8: fare_settings - السماح للإدارة بالتعديل عبر user_profiles
-- ============================================================

DROP POLICY IF EXISTS fare_settings_admin_update ON fare_settings;
CREATE POLICY fare_settings_admin_update ON fare_settings
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- الخطوة 9: notifications - السماح للإدارة بالإدراج
-- ============================================================

DROP POLICY IF EXISTS notifications_admin_insert ON notifications;
CREATE POLICY notifications_admin_insert ON notifications
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- ✅ انتهت الترحيلات
-- ============================================================
