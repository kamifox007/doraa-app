-- ==============================================================================
-- 1. تفعيل الامتدادات المطلوبة (Extensions)
-- ==============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. جدول المستخدمين (User Profiles)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    phone TEXT UNIQUE,
    role TEXT CHECK (role IN ('rider', 'driver', 'admin')),
    avatar_url TEXT,
    gender TEXT CHECK (gender IN ('female', 'male')),
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 3. جدول بيانات السائقات (Driver Profiles)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.driver_profiles (
    user_id UUID PRIMARY KEY REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    car_brand TEXT,
    car_model TEXT,
    car_year TEXT,
    car_color TEXT,
    car_plate TEXT,
    car_photo_url TEXT,
    vehicle_approval_status TEXT DEFAULT 'pending' CHECK (vehicle_approval_status IN ('pending', 'approved', 'rejected')),
    is_online BOOLEAN DEFAULT false,
    current_lat DOUBLE PRECISION,
    current_lng DOUBLE PRECISION,
    rating DOUBLE PRECISION DEFAULT 5.0,
    total_rides INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 4. جدول المستندات (الوثائق الشخصية ورخص القيادة)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('id_card', 'driving_license', 'carte_grise', 'selfie')),
    file_url TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 5. جدول الرحلات (Rides)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.rides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id UUID REFERENCES public.user_profiles(user_id),
    driver_id UUID REFERENCES public.driver_profiles(user_id),
    pickup_address TEXT,
    pickup_lat DOUBLE PRECISION,
    pickup_lng DOUBLE PRECISION,
    dropoff_address TEXT,
    dropoff_lat DOUBLE PRECISION,
    dropoff_lng DOUBLE PRECISION,
    status TEXT DEFAULT 'searching' CHECK (status IN ('searching', 'negotiating', 'accepted', 'arrived_pickup', 'started', 'completed', 'cancelled')),
    proposed_fare DOUBLE PRECISION,
    agreed_fare DOUBLE PRECISION,
    distance_km DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ==============================================================================
-- 6. جدول تسعيرة الولايات (Fare Settings)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.fare_settings (
    wilaya TEXT PRIMARY KEY,
    base_fare DOUBLE PRECISION DEFAULT 100,
    per_km_rate DOUBLE PRECISION DEFAULT 25,
    per_min_rate DOUBLE PRECISION DEFAULT 5,
    min_fare DOUBLE PRECISION DEFAULT 150,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

INSERT INTO public.fare_settings (wilaya, base_fare, per_km_rate, per_min_rate, min_fare)
VALUES 
('Alger', 100, 30, 5, 200),
('Oran', 100, 25, 5, 150),
('Constantine', 90, 25, 4, 150)
ON CONFLICT (wilaya) DO NOTHING;

-- ==============================================================================
-- 7. جدول أكواد الخصم (Promo Codes)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.promo_codes (
    code TEXT PRIMARY KEY,
    discount_amount DOUBLE PRECISION NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 8. جدول الشكاوى وبلاغات الأمان (Safety Reports)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.safety_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES public.user_profiles(user_id),
    reported_id UUID REFERENCES public.user_profiles(user_id),
    ride_id UUID REFERENCES public.rides(id),
    reason TEXT NOT NULL,
    details TEXT,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'reviewing', 'resolved', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 9. جدول المفقودات (Lost Items)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lost_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES public.rides(id),
    reporter_id UUID REFERENCES public.user_profiles(user_id),
    description TEXT NOT NULL,
    status TEXT DEFAULT 'reported' CHECK (status IN ('reported', 'found', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 10. جدول النزاعات المالية (Disputes)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES public.rides(id),
    reporter_id UUID REFERENCES public.user_profiles(user_id),
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'reviewing', 'refunded', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 11. جدول الإشعارات (Notifications)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.user_profiles(user_id),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- إعداد صلاحيات الوصول (RLS)
-- ==============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fare_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lost_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
CREATE POLICY "Users can view their own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can select profiles" ON public.user_profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can select driver profiles" ON public.driver_profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update driver profiles" ON public.driver_profiles FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can select rides" ON public.rides FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert rides" ON public.rides FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update rides" ON public.rides FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Anyone can select fares" ON public.fare_settings FOR SELECT USING (true);
CREATE POLICY "Anyone can select promos" ON public.promo_codes FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert documents" ON public.documents FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert reports" ON public.safety_reports FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can view notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);
