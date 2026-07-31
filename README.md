# تطبيق درة (Doraa App) 📱🌐

تطبيق **Doraa** مخصص لخدمات النقل الذكي بالجزائر (للركاب والسائقات) مدمج مع Supabase وخدمات الخرائط.

---

## 🚀 طريقة استخراج وتصدير النسخ المنفصلة (Build & Export Instructions)

يوفر المشروع كوداً موحداً ودقيقاً يمكن من خلاله استخراج **نسخة الهاتف (Android APK/Bundle)** و **نسخة الويب (Web Deployment)** بشكل منفصل تماً:

### 1. استخراج نسخة الويب (Web Release Build)
لتوليد نسخة الويب الجاهزة للرفع على أي سيرفر أو استضافة (مثل Vercel, Netlify, أو Firebase Hosting):
```bash
flutter build web --release
```
- **مكان المخرجات:** يتم توليد جميع ملفات الويب داخل المجلد: `build/web/`

---

### 2. استخراج نسخة تطبيق الهاتف (Android APK / App Bundle)

#### أ) استخراج ملف APK المباشر للتثبيت على الهواتف (Android APK):
```bash
flutter build apk --release
```
- **مكان المخرجات:** تجد ملف الـ APK المباشر في: `build/app/outputs/flutter-apk/app-release.apk`

#### ب) استخراج ملف App Bundle للرفع على متجر Google Play:
```bash
flutter build appbundle --release
```
- **مكان المخرجات:** تجد ملف الـ AAB في: `build/app/outputs/bundle/release/app-release.aab`

---

### 3. التشغيل في البيئة التطويرية مع بيانات Supabase
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://zszqfbiomkfevkmtnoho.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

---

## 🗄️ إعداد قاعدة البيانات (Database Setup)
تأكد من تنفيذ ملف الـ SQL المرفق في [supabase_setup.sql](supabase_setup.sql) داخل محرر Supabase SQL لإنشاء وتجهيز كافة الجداول والمحافط والـ RPC.
