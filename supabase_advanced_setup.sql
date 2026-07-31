-- ==============================================================================
-- 1. سياسات الأمان لمساحات التخزين (Storage Policies)
-- ملاحظة: نفترض أنك قمت بإنشاء الصناديق (avatars, vehicles, documents) من الواجهة.
-- ==============================================================================

-- السماح للمستخدمين برفع صورهم الشخصية
DROP POLICY IF EXISTS "Allow users to upload avatars" ON storage.objects;
CREATE POLICY "Allow users to upload avatars" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (bucket_id = 'avatars');

-- السماح للجميع بقراءة الصور الشخصية (لأنها عامة)
DROP POLICY IF EXISTS "Allow public to read avatars" ON storage.objects;
CREATE POLICY "Allow public to read avatars" ON storage.objects
FOR SELECT TO public USING (bucket_id = 'avatars');

-- السماح للسائقات برفع صور سياراتهن
DROP POLICY IF EXISTS "Allow drivers to upload vehicle photos" ON storage.objects;
CREATE POLICY "Allow drivers to upload vehicle photos" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (bucket_id = 'vehicles');

-- السماح للجميع (أو المستخدمين) برؤية صور السيارات
DROP POLICY IF EXISTS "Allow public to read vehicle photos" ON storage.objects;
CREATE POLICY "Allow public to read vehicle photos" ON storage.objects
FOR SELECT TO public USING (bucket_id = 'vehicles');

-- السماح للمستخدمين برفع وثائقهم (رخصة، بطاقة هوية)
DROP POLICY IF EXISTS "Allow users to upload documents" ON storage.objects;
CREATE POLICY "Allow users to upload documents" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (bucket_id = 'documents');

-- الوثائق خاصة جداً: لا يمكن لأحد قراءتها إلا صاحبها (والمشرفين لاحقاً)
DROP POLICY IF EXISTS "Allow users to read own documents" ON storage.objects;
CREATE POLICY "Allow users to read own documents" ON storage.objects
FOR SELECT TO authenticated USING (bucket_id = 'documents' AND auth.uid() = owner);


-- ==============================================================================
-- 2. دالة البحث عن أقرب السائقات (RPC: get_nearby_drivers)
-- تستخدم خوارزمية (Haversine) لحساب المسافة الدقيقة بناءً على خطوط الطول والعرض.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.get_nearby_drivers(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_km DOUBLE PRECISION DEFAULT 10
)
RETURNS TABLE (
  driver_id UUID,
  full_name TEXT,
  car_brand TEXT,
  car_model TEXT,
  car_color TEXT,
  car_plate TEXT,
  distance_km DOUBLE PRECISION
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    dp.user_id as driver_id,
    up.full_name,
    dp.car_brand,
    dp.car_model,
    dp.car_color,
    dp.car_plate,
    -- خوارزمية Haversine لحساب المسافة بالكيلومتر
    (6371 * acos(
      cos(radians(p_lat)) * cos(radians(dp.current_lat)) *
      cos(radians(dp.current_lng) - radians(p_lng)) +
      sin(radians(p_lat)) * sin(radians(dp.current_lat))
    )) AS distance_km
  FROM public.driver_profiles dp
  JOIN public.user_profiles up ON dp.user_id = up.user_id
  WHERE dp.is_online = true 
    AND dp.vehicle_approval_status = 'approved'
    AND dp.current_lat IS NOT NULL 
    AND dp.current_lng IS NOT NULL
    -- تصفية السائقات ليكونوا داخل النطاق المحدد فقط (مثلاً 10 كم)
    AND (6371 * acos(
      cos(radians(p_lat)) * cos(radians(dp.current_lat)) *
      cos(radians(dp.current_lng) - radians(p_lng)) +
      sin(radians(p_lat)) * sin(radians(dp.current_lat))
    )) <= p_radius_km
  ORDER BY distance_km ASC;
$$;


-- ==============================================================================
-- 3. المشغل الآلي للمستخدمين الجدد (Auth Trigger)
-- لإنشاء ملف شخصي تلقائياً بمجرد التسجيل بدلاً من الاعتماد على التطبيق.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- إنشاء صف افتراضي للمستخدم الجديد في جدول user_profiles
  INSERT INTO public.user_profiles (user_id, role)
  VALUES (new.id, 'rider') -- نفترض مبدئياً أنه راكب إلى أن يثبت العكس
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ربط المشغل (Trigger) بجدول auth.users الخاص بـ Supabase
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
