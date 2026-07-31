-- ====================================================
-- Migration: Support Tickets (Complaints System)
-- ====================================================

CREATE TABLE IF NOT EXISTS support_tickets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ride_id     UUID REFERENCES rides(id) ON DELETE SET NULL, -- اختياري، قد تكون شكوى عامة
  target_id   UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- الشخص المشتكى عليه (سائقة أو راكبة)
  category    TEXT NOT NULL, -- نوع الشكوى (تأخير، سلوك، سيارة، دفع، أخرى)
  description TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'closed')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- فهرس لسرعة استرجاع تذاكر مستخدم معين أو شكاوى رحلة معينة
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets (user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_ride_id ON support_tickets (ride_id);

-- تفعيل RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- يمكن للمستخدم قراءة التذاكر التي فتحها بنفسه
CREATE POLICY "users_can_read_own_tickets"
  ON support_tickets FOR SELECT
  USING (auth.uid() = user_id);

-- يمكن للمستخدم إنشاء تذكرة
CREATE POLICY "users_can_create_tickets"
  ON support_tickets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- الإدارة يمكنها قراءة وتعديل كل التذاكر
-- (بافتراض أن هناك طريقة لمعرفة أن المستخدم admin، يمكنك استخدامها هنا. حالياً نسمح بالتحديث للإدارة فقط إذا تجاوزنا RLS)
-- سنستخدم Bypass RLS لحسابات الـ Service Role الخاصة بالـ Admin، أو ننشئ سياسة:
CREATE POLICY "admins_can_manage_tickets"
  ON support_tickets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ====================================================
-- SOS / Emergency Alerts (اختياري لاحقاً)
-- ====================================================
-- ميزة طوارئ سريعة لحفظ إنذارات الخطر التي يرسلها الراكب/السائق لأرقام الطوارئ
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ride_id     UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  latitude    DOUBLE PRECISION NOT NULL,
  longitude   DOUBLE PRECISION NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_can_create_alerts" ON emergency_alerts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "admins_can_read_alerts" ON emergency_alerts FOR SELECT USING (true);
