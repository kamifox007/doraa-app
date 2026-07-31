-- ====================================================
-- Migration: Create ride_locations table for live tracking
-- ====================================================

CREATE TABLE IF NOT EXISTS ride_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  heading DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- فهرس لسرعة استرجاع أحدث المواقع لكل رحلة
CREATE INDEX IF NOT EXISTS idx_ride_locations_ride_id
  ON ride_locations (ride_id, created_at DESC);

-- تفعيل RLS (Row Level Security)
ALTER TABLE ride_locations ENABLE ROW LEVEL SECURITY;

-- السماح للمشاركين في الرحلة (الراكبة والسائقة) بقراءة الموقع
CREATE POLICY "ride_participants_can_read_location"
  ON ride_locations FOR SELECT
  USING (
    auth.uid() IN (
      SELECT rider_id FROM rides WHERE id = ride_id
      UNION
      SELECT driver_id FROM rides WHERE id = ride_id
    )
  );

-- السماح للسائقة فقط بإدراج المواقع الجديدة
CREATE POLICY "drivers_can_insert_location"
  ON ride_locations FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT driver_id FROM rides WHERE id = ride_id
    )
  );

-- تفعيل Realtime على الجدول لتتمكن الراكبة من الاستماع للتحديثات
ALTER PUBLICATION supabase_realtime ADD TABLE ride_locations;
