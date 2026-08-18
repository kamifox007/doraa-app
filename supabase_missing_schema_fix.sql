-- =========================================================================
-- Supabase Schema Fix & Missing Tables (Idempotent Script)
-- =========================================================================
-- هذا الملف مبرمج بطريقة آمنة، يمكن تشغيله مئات المرات ولن يظهر أي خطأ بفضل
-- استخدام IF NOT EXISTS و DROP POLICY IF EXISTS.

-- --------------------------------------------------------
-- 1. جدول الإشعارات (Notifications)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'SYSTEM',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" 
ON public.notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" 
ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
CREATE POLICY "Users can insert their own notifications" 
ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- --------------------------------------------------------
-- 2. تحديث جدول المستخدمين (FCM Token)
-- --------------------------------------------------------
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- --------------------------------------------------------
-- 3. جدول إعدادات التطبيق (App Settings)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    latest_version TEXT NOT NULL,
    min_version TEXT NOT NULL,
    force_update BOOLEAN DEFAULT false,
    maintenance_mode BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read app settings" ON public.app_settings;
CREATE POLICY "Anyone can read app settings" 
ON public.app_settings FOR SELECT USING (true);

-- إدخال إعدادات مبدئية فقط في حال كان الجدول فارغاً
INSERT INTO public.app_settings (latest_version, min_version, force_update, maintenance_mode)
SELECT '1.0.0', '1.0.0', false, false
WHERE NOT EXISTS (SELECT 1 FROM public.app_settings);

-- --------------------------------------------------------
-- 4. جدول تنبيهات الطوارئ (SOS Alerts)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sos_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    status TEXT DEFAULT 'pending',
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create sos alerts" ON public.sos_alerts;
CREATE POLICY "Users can create sos alerts" 
ON public.sos_alerts FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view sos alerts" ON public.sos_alerts;
CREATE POLICY "Admins can view sos alerts" 
ON public.sos_alerts FOR SELECT 
USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE user_profiles.user_id = auth.uid() AND user_profiles.role = 'admin'));

-- --------------------------------------------------------
-- 5. جدول رسوم الإلغاء (Cancellation Fees)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cancellation_fees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    amount NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    status TEXT DEFAULT 'unpaid',
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.cancellation_fees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own cancellation fees" ON public.cancellation_fees;
CREATE POLICY "Users can view their own cancellation fees" 
ON public.cancellation_fees FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert cancellation fees" ON public.cancellation_fees;
CREATE POLICY "System can insert cancellation fees" 
ON public.cancellation_fees FOR INSERT WITH CHECK (auth.uid() = user_id);

-- --------------------------------------------------------
-- 6. حاويات الملفات وسياسات الأمان (Storage Buckets)
-- --------------------------------------------------------

-- إنشاء الحاويات بشكل آمن (لا تتأثر إذا كانت موجودة مسبقاً)
INSERT INTO storage.buckets (id, name, public) VALUES ('public_profiles', 'public_profiles', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('identity_documents', 'identity_documents', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('voice_notes', 'voice_notes', true) ON CONFLICT (id) DO NOTHING;

-- سياسات الصور الشخصية
DROP POLICY IF EXISTS "Public profiles are publicly accessible." ON storage.objects;
CREATE POLICY "Public profiles are publicly accessible." 
ON storage.objects FOR SELECT USING (bucket_id = 'public_profiles');

DROP POLICY IF EXISTS "Users can upload their own profile images." ON storage.objects;
CREATE POLICY "Users can upload their own profile images." 
ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'public_profiles' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own profile images." ON storage.objects;
CREATE POLICY "Users can update their own profile images." 
ON storage.objects FOR UPDATE USING (bucket_id = 'public_profiles' AND auth.role() = 'authenticated');

-- سياسات الوثائق الثبوتية
DROP POLICY IF EXISTS "Users can upload identity documents." ON storage.objects;
CREATE POLICY "Users can upload identity documents." 
ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'identity_documents' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users and Admins can view documents." ON storage.objects;
CREATE POLICY "Users and Admins can view documents." 
ON storage.objects FOR SELECT 
USING (
    bucket_id = 'identity_documents' AND (
        auth.uid() = owner OR 
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_profiles.user_id = auth.uid() AND user_profiles.role = 'admin')
    )
);

-- سياسات الملاحظات الصوتية
DROP POLICY IF EXISTS "Voice notes are accessible." ON storage.objects;
CREATE POLICY "Voice notes are accessible." 
ON storage.objects FOR SELECT USING (bucket_id = 'voice_notes');

DROP POLICY IF EXISTS "Users can upload voice notes." ON storage.objects;
CREATE POLICY "Users can upload voice notes." 
ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'voice_notes' AND auth.role() = 'authenticated');
