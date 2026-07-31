-- تفعيل إضافة PostGIS للتعامل مع الخرائط والإحداثيات
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. جدول المستخدمين (الراكبات والسائقات)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE, -- المرتبط بحساب Supabase Auth
  full_name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  role TEXT CHECK (role IN ('rider', 'driver')),
  wilaya TEXT,
  fcm_token TEXT,
  verification_status TEXT DEFAULT 'pending', -- pending, approved, rejected
  total_rides INTEGER DEFAULT 0,
  average_rating NUMERIC(3, 2) DEFAULT 5.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. جدول بيانات السائقات والسيارات
CREATE TABLE IF NOT EXISTS public.driver_profiles (
  user_id UUID PRIMARY KEY REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
  car_brand TEXT,
  car_model TEXT,
  car_year TEXT,
  car_color TEXT,
  car_plate TEXT,
  car_photo_url TEXT,
  vehicle_approval_status TEXT DEFAULT 'pending',
  is_online BOOLEAN DEFAULT false,
  current_lat DOUBLE PRECISION,
  current_lng DOUBLE PRECISION,
  current_geom geometry(Point, 4326),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 3. جدول المستندات (الهوية، رخصة القيادة، إلخ)
CREATE TABLE IF NOT EXISTS public.documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
  type TEXT, -- cni_front, cni_back, selfie, license
  file_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  admin_notes TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 4. جدول الرحلات
CREATE TABLE IF NOT EXISTS public.rides (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  rider_id UUID REFERENCES public.user_profiles(user_id),
  driver_id UUID REFERENCES public.user_profiles(user_id),
  status TEXT DEFAULT 'searching', -- searching, negotiating, accepted, arrived_pickup, started, completed, cancelled
  ride_type TEXT DEFAULT 'solo_city', -- solo_city, shared_city, solo_intercity, shared_intercity
  
  -- مسار الرحلة
  pickup_address TEXT,
  dropoff_address TEXT,
  pickup_lat DOUBLE PRECISION,
  pickup_lng DOUBLE PRECISION,
  dropoff_lat DOUBLE PRECISION,
  dropoff_lng DOUBLE PRECISION,
  
  -- الإحداثيات المكانية للبحث (PostGIS)
  pickup_geom geometry(Point, 4326),
  dropoff_geom geometry(Point, 4326),
  
  -- الأسعار
  proposed_fare NUMERIC,
  agreed_fare NUMERIC,
  
  -- ربط الرحلات التشاركية
  is_shared BOOLEAN DEFAULT false,
  matched_ride_id UUID REFERENCES public.rides(id),
  
  -- تفاصيل أخرى
  ride_pin TEXT,
  negotiation_history JSONB DEFAULT '[]'::jsonb,
  last_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- إنشاء Index لتسريع البحث الجغرافي
CREATE INDEX IF NOT EXISTS rides_pickup_geom_idx ON public.rides USING GIST (pickup_geom);
CREATE INDEX IF NOT EXISTS rides_dropoff_geom_idx ON public.rides USING GIST (dropoff_geom);
CREATE INDEX IF NOT EXISTS drivers_geom_idx ON public.driver_profiles USING GIST (current_geom);

-- 5. تحديث الإحداثيات تلقائياً عند الإدخال في جدول الرحلات
CREATE OR REPLACE FUNCTION update_ride_geom()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.pickup_lat IS NOT NULL AND NEW.pickup_lng IS NOT NULL THEN
    NEW.pickup_geom = ST_SetSRID(ST_MakePoint(NEW.pickup_lng, NEW.pickup_lat), 4326);
  END IF;
  IF NEW.dropoff_lat IS NOT NULL AND NEW.dropoff_lng IS NOT NULL THEN
    NEW.dropoff_geom = ST_SetSRID(ST_MakePoint(NEW.dropoff_lng, NEW.dropoff_lat), 4326);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_geom_trigger
BEFORE INSERT OR UPDATE ON public.rides
FOR EACH ROW EXECUTE FUNCTION update_ride_geom();

-- 6. جدول مواقع الرحلة (Live Tracking)
CREATE TABLE IF NOT EXISTS public.ride_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  geom geometry(Point, 4326),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 7. جدول تقارير السلامة (الشكاوى)
CREATE TABLE IF NOT EXISTS public.safety_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id UUID REFERENCES public.user_profiles(user_id),
  reported_id UUID REFERENCES public.user_profiles(user_id),
  ride_id UUID REFERENCES public.rides(id),
  reason TEXT,
  details TEXT,
  status TEXT DEFAULT 'open', -- open, reviewing, resolved, dismissed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 8. خوارزمية ربط الرحلات التشاركية (Smart Matching RPC)
-- تقوم هذه الدالة بالبحث عن رحلة قيد الانتظار تناسب مسار الراكبة الجديدة
CREATE OR REPLACE FUNCTION find_shared_ride(
  p_ride_type TEXT, 
  p_pickup_lng DOUBLE PRECISION, 
  p_pickup_lat DOUBLE PRECISION, 
  p_dropoff_lng DOUBLE PRECISION, 
  p_dropoff_lat DOUBLE PRECISION
)
RETURNS TABLE (
  matched_id UUID,
  rider_name TEXT,
  detour_distance_meters FLOAT
) AS $$
DECLARE
  new_pickup geometry := ST_SetSRID(ST_MakePoint(p_pickup_lng, p_pickup_lat), 4326);
  new_dropoff geometry := ST_SetSRID(ST_MakePoint(p_dropoff_lng, p_dropoff_lat), 4326);
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS matched_id,
    u.full_name AS rider_name,
    -- حساب الانحراف عن المسار (Triangle Inequality)
    -- المسافة من انطلاق1 إلى انطلاق2 + من انطلاق2 إلى وصول2 + من وصول2 إلى وصول1
    (ST_DistanceSphere(r.pickup_geom, new_pickup) + 
     ST_DistanceSphere(new_pickup, new_dropoff) + 
     ST_DistanceSphere(new_dropoff, r.dropoff_geom)) AS detour_distance_meters
  FROM public.rides r
  JOIN public.user_profiles u ON r.rider_id = u.user_id
  WHERE r.status = 'searching' 
    AND r.is_shared = true
    AND r.ride_type = p_ride_type
    -- فلترة مبدئية: يجب أن تكون نقطة الانطلاق والوصول ضمن مسافة قريبة نسبياً (لتخفيف العبء على الخوارزمية)
    -- 200 كم كحد أقصى للبحث بين الولايات، و 15 كم داخل المدينة
    AND ST_DistanceSphere(r.pickup_geom, new_pickup) < CASE WHEN p_ride_type = 'shared_intercity' THEN 200000 ELSE 15000 END
  ORDER BY detour_distance_meters ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;
