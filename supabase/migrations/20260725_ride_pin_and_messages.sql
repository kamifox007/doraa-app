-- ====================================================
-- Migration: Ride PIN + Real-time Chat Messages
-- ====================================================

-- 1. إضافة حقل ride_pin لجدول الرحلات
ALTER TABLE rides
  ADD COLUMN IF NOT EXISTS ride_pin TEXT DEFAULT '';

-- 2. إنشاء جدول رسائل الدردشة
CREATE TABLE IF NOT EXISTS ride_messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id     UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  sender_id   UUID NOT NULL REFERENCES auth.users(id),
  content     TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text', -- 'text' أو 'voice'
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- فهرس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_ride_messages_ride_id
  ON ride_messages (ride_id, created_at ASC);

-- 3. تفعيل RLS لجدول الرسائل
ALTER TABLE ride_messages ENABLE ROW LEVEL SECURITY;

-- يمكن للمرسل والمستقبل (السائقة أو الراكبة) قراءة الرسائل
CREATE POLICY "ride_participants_can_read_messages"
  ON ride_messages FOR SELECT
  USING (
    auth.uid() = sender_id OR
    auth.uid() IN (
      SELECT rider_id FROM rides WHERE id = ride_id
      UNION
      SELECT driver_id FROM rides WHERE id = ride_id
    )
  );

-- فقط المشاركون في الرحلة يمكنهم إرسال رسائل
CREATE POLICY "ride_participants_can_insert_messages"
  ON ride_messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND
    auth.uid() IN (
      SELECT rider_id FROM rides WHERE id = ride_id
      UNION
      SELECT driver_id FROM rides WHERE id = ride_id
    )
  );

-- 4. تفعيل Realtime للجدول
ALTER PUBLICATION supabase_realtime ADD TABLE ride_messages;

-- ====================================================
-- Storage: إنشاء bucket للملاحظات الصوتية
-- ====================================================
-- يجب تنفيذ هذا من لوحة Supabase Dashboard أو CLI:
--
--   supabase storage create voice_notes --public
--
-- أو من SQL بعد تفعيل امتداد pg_net:
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('voice_notes', 'voice_notes', true)
-- ON CONFLICT (id) DO NOTHING;
