-- إضافة عمود FCM Token لحفظ رمز جهاز المستخدم لإرسال الإشعارات
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT DEFAULT NULL;
