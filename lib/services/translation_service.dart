import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

final translationProvider = Provider<TranslationService>((ref) {
  final lang = ref.watch(localeProvider);
  return TranslationService(lang);
});

class TranslationService {
  final String currentLang;
  TranslationService(this.currentLang);

  String tr(String key) {
    return _dict[key]?[currentLang] ?? key;
  }

  // القاموس المركزي للتطبيق
  static const Map<String, Map<String, String>> _dict = {
    'app_name': {
      'ar': 'Doraa - دورة',
      'fr': 'Doraa',
      'en': 'Doraa'
    },
    'app_subtitle': {
      'ar': 'تطبيق التوصيل الآمن للسيدات',
      'fr': 'L\'application de transport sécurisé pour les femmes',
      'en': 'Secure ride-hailing app for women'
    },
    'skip': {
      'ar': 'تخطي',
      'fr': 'Passer',
      'en': 'Skip'
    },
    'resend_code': {
      'ar': 'إعادة إرسال الرمز',
      'fr': 'Renvoyer le code',
      'en': 'Resend Code'
    },
    'resend_in': {
      'ar': 'إعادة إرسال خلال',
      'fr': 'Renvoyer dans',
      'en': 'Resend in'
    },
    'splash_subtitle': {
      'ar': 'توصيل آمن وموثوق.. من النساء وإلى النساء',
      'fr': 'Transport sûr et fiable.. Par des femmes, pour des femmes',
      'en': 'Safe and reliable transport.. By women, for women'
    },
    'db_status': {
      'ar': 'قاعدة البيانات (Supabase)',
      'fr': 'Base de données (Supabase)',
      'en': 'Database (Supabase)'
    },
    'backend_status': {
      'ar': 'الخوادم الخلفية (Stitch)',
      'fr': 'Serveurs backend (Stitch)',
      'en': 'Backend Servers (Stitch)'
    },
    'checking': {
      'ar': 'جاري الفحص...',
      'fr': 'Vérification...',
      'en': 'Checking...'
    },
    'start_app': {
      'ar': 'ابدأ تجربة التطبيق',
      'fr': 'Commencer l\'expérience',
      'en': 'Start App Experience'
    },
    
    // AuthFlow - Welcome
    'welcome_title': {
      'ar': 'مرحباً بكِ في دورة',
      'fr': 'Bienvenue chez Doraa',
      'en': 'Welcome to Doraa'
    },
    'welcome_subtitle': {
      'ar': 'الوجهة الأولى للسيدات، بكل أمان وراحة.',
      'fr': 'La première destination pour les femmes, en toute sécurité.',
      'en': 'The first destination for women, safely and comfortably.'
    },
    'login_btn': {
      'ar': 'تسجيل الدخول',
      'fr': 'Connexion',
      'en': 'Log In'
    },
    'signup_btn': {
      'ar': 'إنشاء حساب جديد',
      'fr': 'Créer un compte',
      'en': 'Sign Up'
    },
    'skip_demo': {
      'ar': 'تخطي للنسخة التجريبية',
      'fr': 'Passer à la démo',
      'en': 'Skip to Demo'
    },

      'ar': 'توصيل آمن وموثوق.. من النساء وإلى النساء',
      'fr': 'Transport sûr et fiable.. Par des femmes, pour des femmes',
      'en': 'Safe and reliable transport.. By women, for women'
    },
    'lets_go': {
      'ar': 'لننطلق',
      'fr': 'C\'est parti',
      'en': 'Let\'s Go'
    },
    'onboarding_title_1': {
      'ar': 'أمان تام لكِ ولعائلتك',
      'fr': 'Sécurité totale pour vous et votre famille',
      'en': 'Complete safety for you and your family'
    },
    'onboarding_desc_1': {
      'ar': 'نحرص على التحقق من هوية السائقات وتوفير مزايا تتبع الرحلة ومشاركة مسارها مع من تحبين.',
      'fr': 'Nous vérifions l\'identité des conductrices et offrons le suivi du trajet partagé avec vos proches.',
      'en': 'We verify driver identities and provide ride tracking features to share with your loved ones.'
    },
    'onboarding_title_2': {
      'ar': 'سائقات معتمدات',
      'fr': 'Conductrices certifiées',
      'en': 'Certified female drivers'
    },
    'onboarding_desc_2': {
      'ar': 'نوفر لكِ بيئة مريحة 100% مع سائقات إناث فقط، لضمان أعلى مستويات الراحة والطمأنينة.',
      'fr': 'Un environnement 100% confortable avec uniquement des femmes conductrices pour votre tranquillité.',
      'en': 'A 100% comfortable environment with female drivers only, ensuring maximum peace of mind.'
    },
    'onboarding_title_3': {
      'ar': 'أسعار تنافسية',
      'fr': 'Prix compétitifs',
      'en': 'Competitive prices'
    },
    'onboarding_desc_3': {
      'ar': 'فاوضي على سعر الرحلة مباشرة مع السائقة، وادفعي بالطريقة التي تناسبك.',
      'fr': 'Négociez le prix du trajet directement avec la conductrice et payez comme il vous convient.',
      'en': 'Negotiate the ride fare directly with the driver and pay the way that suits you.'
    },
    'demo_mode_skip': {
      'ar': 'وضع تجريبي - تم تخطي الإرسال',
      'fr': 'Mode démo - Envoi ignoré',
      'en': 'Demo mode - Send skipped'
    },
    'invalid_phone': {
      'ar': 'رقم الهاتف غير صالح',
      'fr': 'Numéro de téléphone invalide',
      'en': 'Invalid phone number'
    },
    'sent_success': {
      'ar': 'تم الإرسال',
      'fr': 'Envoyé avec succès',
      'en': 'Sent successfully'
    },
    'invalid_otp_length': {
      'ar': 'يرجى إدخال الرمز المكوّن من 6 أرقام',
      'fr': 'Veuillez entrer le code à 6 chiffres',
      'en': 'Please enter the 6-digit code'
    },
    'confirm_phone_title': {
      'ar': 'تأكيد رقم الهاتف',
      'fr': 'Confirmer le numéro',
      'en': 'Confirm phone number'
    },
    'confirm_phone_desc': {
      'ar': 'سنرسل رمز تأكيد على رقمك للتحقق.',
      'fr': 'Nous enverrons un code de confirmation pour vérifier.',
      'en': 'We will send a confirmation code to verify.'
    },
    'phone_label': {
      'ar': 'رقم الهاتف',
      'fr': 'Numéro de téléphone',
      'en': 'Phone number'
    },
    'send_code_btn': {
      'ar': 'إرسال الرمز',
      'fr': 'Envoyer le code',
      'en': 'Send Code'
    },
    'otp_label': {
      'ar': 'رمز التحقق (OTP)',
      'fr': 'Code de vérification (OTP)',
      'en': 'Verification Code (OTP)'
    },
    'verify_code_btn': {
      'ar': 'تحقق من الرمز',
      'fr': 'Vérifier le code',
      'en': 'Verify Code'
    },
    'personal_info_title': {
      'ar': 'المعلومات الشخصية',
      'fr': 'Informations personnelles',
      'en': 'Personal Information'
    },
    'personal_info_desc': {
      'ar': 'دعينا نتعرف عليكِ أكثر.',
      'fr': 'Faisons mieux connaissance.',
      'en': 'Let\'s get to know you better.'
    },
    'full_name_label': {
      'ar': 'الاسم الكامل',
      'fr': 'Nom complet',
      'en': 'Full Name'
    },
    'wilaya_label': {
      'ar': 'الولاية',
      'fr': 'Wilaya (Province)',
      'en': 'Wilaya (Province)'
    },
    'role_question': {
      'ar': 'كيف ترغبين باستخدام التطبيق؟',
      'fr': 'Comment souhaitez-vous utiliser l\'application?',
      'en': 'How would you like to use the app?'
    },
    'role_rider': {
      'ar': 'زبونة',
      'fr': 'Cliente',
      'en': 'Rider'
    },
    'role_driver': {
      'ar': 'سائقة',
      'fr': 'Conductrice',
      'en': 'Driver'
    },
    'next_btn': {
      'ar': 'التالي',
      'fr': 'Suivant',
      'en': 'Next'
    },
    'invalid_name': {
      'ar': 'الاسم غير صالح',
      'fr': 'Nom invalide',
      'en': 'Invalid name'
    },
    'select_wilaya': {
      'ar': 'يرجى اختيار الولاية',
      'fr': 'Veuillez sélectionner une Wilaya',
      'en': 'Please select a Wilaya'
    },
    'setup_password_title': {
      'ar': 'إنشاء كلمة المرور',
      'fr': 'Créer un mot de passe',
      'en': 'Create Password'
    },
    'setup_password_desc': {
      'ar': 'الخطوة الأخيرة! أدخلي بريدك وعيّني كلمة مرور.',
      'fr': 'Dernière étape ! Entrez votre email et créez un mot de passe.',
      'en': 'Last step! Enter your email and create a password.'
    },
    'email_optional': {
      'ar': 'البريد الإلكتروني (اختياري)',
      'fr': 'Email (Optionnel)',
      'en': 'Email (Optional)'
    },
    'password_label': {
      'ar': 'كلمة المرور',
      'fr': 'Mot de passe',
      'en': 'Password'
    },
    'confirm_password_label': {
      'ar': 'تأكيد كلمة المرور',
      'fr': 'Confirmer le mot de passe',
      'en': 'Confirm Password'
    },
    'continue_registration': {
      'ar': 'متابعة التسجيل',
      'fr': 'Continuer l\'inscription',
      'en': 'Continue Registration'
    },
    'vehicle_data_title': {
      'ar': 'بيانات السيارة',
      'fr': 'Détails du véhicule',
      'en': 'Vehicle Details'
    },
    'vehicle_data_desc': {
      'ar': 'هذه البيانات ستظهر للزبائن للتعرف على سيارتك.',
      'fr': 'Ces détails seront visibles par les clientes pour identifier votre voiture.',
      'en': 'These details will be visible to riders to identify your car.'
    },
    'vehicle_brand': {
      'ar': 'الماركة (مثل تويوتا)',
      'fr': 'Marque (ex: Toyota)',
      'en': 'Brand (e.g. Toyota)'
    },
    'vehicle_model': {
      'ar': 'الموديل (مثل ياريس)',
      'fr': 'Modèle (ex: Yaris)',
      'en': 'Model (e.g. Yaris)'
    },
    'vehicle_year': {
      'ar': 'سنة الصنع',
      'fr': 'Année de fabrication',
      'en': 'Year of manufacture'
    },
    'vehicle_color': {
      'ar': 'اللون',
      'fr': 'Couleur',
      'en': 'Color'
    },
    'vehicle_plate': {
      'ar': 'رقم اللوحة',
      'fr': 'Numéro d\'immatriculation',
      'en': 'License Plate'
    },
    'next_docs_btn': {
      'ar': 'التالي: المستندات',
      'fr': 'Suivant : Documents',
      'en': 'Next: Documents'
    },
    'verify_identity_title': {
      'ar': 'التحقق من الهوية',
      'fr': 'Vérification d\'identité',
      'en': 'Identity Verification'
    },
    'id_card_img': {
      'ar': 'صورة بطاقة الهوية',
      'fr': 'Photo de la carte d\'identité',
      'en': 'ID Card Photo'
    },
    'upload_clear_img': {
      'ar': 'يرجى رفع صورة واضحة',
      'fr': 'Veuillez télécharger une image claire',
      'en': 'Please upload a clear image'
    },
    'driving_license': {
      'ar': 'رخصة القيادة',
      'fr': 'Permis de conduire',
      'en': 'Driving License'
    },
    'drivers_only': {
      'ar': 'للسائقات فقط',
      'fr': 'Pour les conductrices uniquement',
      'en': 'For drivers only'
    },
    'live_selfie': {
      'ar': 'صورة السيلفي المباشرة',
      'fr': 'Selfie en direct',
      'en': 'Live Selfie'
    },
    'verify_face_match': {
      'ar': 'للتحقق من مطابقة وجهك للهوية',
      'fr': 'Pour vérifier que votre visage correspond à la pièce d\'identité',
      'en': 'To verify your face matches the ID'
    },
    'skip_demo_btn': {
      'ar': 'تخطي في الوضع التجريبي',
      'fr': 'Passer en mode démo',
      'en': 'Skip in Demo Mode'
    },
    'emergency_contacts_title': {
      'ar': 'جهات الطوارئ',
      'fr': 'Contacts d\'urgence',
      'en': 'Emergency Contacts'
    },
    'emergency_contacts_desc': {
      'ar': 'اختاري شخصاً موثوقاً للاتصال به في حالات الطوارئ أثناء الرحلات.',
      'fr': 'Choisissez une personne de confiance à contacter en cas d\'urgence pendant les trajets.',
      'en': 'Choose a trusted person to contact in emergencies during rides.'
    },
    'contact_name': {
      'ar': 'الاسم',
      'fr': 'Nom',
      'en': 'Name'
    },
    'contact_relation': {
      'ar': 'صلة القرابة (أب، أخت...)',
      'fr': 'Lien de parenté (père, sœur...)',
      'en': 'Relationship (father, sister...)'
    },
    'finish_registration_btn': {
      'ar': 'إتمام التسجيل',
      'fr': 'Terminer l\'inscription',
      'en': 'Finish Registration'
    },
    'login_title': {
      'ar': 'تسجيل الدخول',
      'fr': 'Connexion',
      'en': 'Log In'
    },
    'login_desc': {
      'ar': 'مرحباً بعودتك! أدخلي بريدك وكلمة المرور.',
      'fr': 'Ravi de vous revoir ! Entrez votre email et votre mot de passe.',
      'en': 'Welcome back! Enter your email and password.'
    },
    'email_label': {
      'ar': 'البريد الإلكتروني',
      'fr': 'Email',
      'en': 'Email'
    },
    'forgot_password': {
      'ar': 'نسيت كلمة المرور؟',
      'fr': 'Mot de passe oublié ?',
      'en': 'Forgot Password?'
    },
    'enter_btn': {
      'ar': 'دخول',
      'fr': 'Entrer',
      'en': 'Enter'
    },
    'request_received_title': {
      'ar': 'تم استلام طلبك!',
      'fr': 'Votre demande a été reçue !',
      'en': 'Request Received!'
    },
    'request_received_desc': {
      'ar': 'حسابك قيد المراجعة لضمان أمان مجتمعنا. سنقوم بالتواصل معك قريباً عند تفعيل الحساب.',
      'fr': 'Votre compte est en cours de révision. Nous vous contacterons une fois activé.',
      'en': 'Your account is under review. We will contact you once activated.'
    },
    'where_to_go': {
      'ar': 'إلى أين نذهب اليوم؟',
      'fr': 'Où allons-nous aujourd\'hui ?',
      'en': 'Where to today?'
    },
    'available_drivers': {
      'ar': 'السائقات المتاحات',
      'fr': 'Conductrices disponibles',
      'en': 'Available Drivers'
    },
    'near_you_now': {
      'ar': 'قريباً منكِ الآن',
      'fr': 'Près de chez vous maintenant',
      'en': 'Near you right now'
    },
    'online_drivers_count': {
      'ar': 'متصلات 🟢',
      'fr': 'en ligne 🟢',
      'en': 'online 🟢'
    },
    'inside_city': {
      'ar': 'داخل المدينة',
      'fr': 'En ville',
      'en': 'Inside City'
    },
    'intercity_travel': {
      'ar': 'سفر (ولايات)',
      'fr': 'Voyage (Inter-wilayas)',
      'en': 'Travel (Intercity)'
    },
    'driver_mode': {
      'ar': 'وضع السائقة',
      'fr': 'Mode conductrice',
      'en': 'Driver Mode'
    },
    'earnings': {
      'ar': 'الأرباح',
      'fr': 'Gains',
      'en': 'Earnings'
    },
    'title_pickup': {
      'ar': 'تحديد الانطلاق',
      'fr': 'Point de départ',
      'en': 'Set Pickup'
    },
    'title_dropoff': {
      'ar': 'تحديد الوجهة',
      'fr': 'Point d\'arrivée',
      'en': 'Set Dropoff'
    },
    'title_fare': {
      'ar': 'تقدير الأجرة',
      'fr': 'Estimation du prix',
      'en': 'Fare Estimate'
    },
    'title_drivers': {
      'ar': 'اختيار السائق',
      'fr': 'Choisir une conductrice',
      'en': 'Choose Driver'
    },
    'title_negotiation': {
      'ar': 'المفاوضة',
      'fr': 'Négociation',
      'en': 'Negotiation'
    },
    'title_active_ride': {
      'ar': 'الرحلة الحالية',
      'fr': 'Trajet en cours',
      'en': 'Active Ride'
    },
    'title_payment': {
      'ar': 'تأكيد الدفع',
      'fr': 'Confirmer le paiement',
      'en': 'Confirm Payment'
    },
    'title_rating': {
      'ar': 'تقييم الرحلة',
      'fr': 'Évaluer le trajet',
      'en': 'Rate Ride'
    },
    'title_receipt': {
      'ar': 'الإيصال',
      'fr': 'Reçu',
      'en': 'Receipt'
    },
    'title_history': {
      'ar': 'سجل الرحلات',
      'fr': 'Historique',
      'en': 'Ride History'
    },
    'title_requests': {
      'ar': 'طلبات الرحلات',
      'fr': 'Demandes de trajets',
      'en': 'Ride Requests'
    },
    'title_home': {
      'ar': 'طلب رحلة',
      'fr': 'Demander un trajet',
      'en': 'Request Ride'
    },
    'drag_map_or_select': {
      'ar': 'اسحب الخريطة أو اختر الموقع',
      'fr': 'Faites glisser la carte ou choisissez',
      'en': 'Drag map or select location'
    },
    'confirm_pickup_btn': {
      'ar': '📍 تأكيد موقع الانطلاق',
      'fr': '📍 Confirmer le point de départ',
      'en': '📍 Confirm Pickup Location'
    },
    'choose_dropoff': {
      'ar': 'اختر الوجهة',
      'fr': 'Choisissez la destination',
      'en': 'Choose Destination'
    },
    'search_destination': {
      'ar': 'بحث عن وجهة',
      'fr': 'Rechercher une destination',
      'en': 'Search for a destination'
    },
    'recent_destinations': {
      'ar': 'الوجهات الأخيرة',
      'fr': 'Destinations récentes',
      'en': 'Recent Destinations'
    },
    'airport': {
      'ar': 'المطار',
      'fr': 'Aéroport',
      'en': 'Airport'
    },
    'university': {
      'ar': 'جامعة الملك خالد',
      'fr': 'Université',
      'en': 'University'
    },
    'central_market': {
      'ar': 'السوق المركزي',
      'fr': 'Marché central',
      'en': 'Central Market'
    },
    'favorites': {
      'ar': 'المفضلة',
      'fr': 'Favoris',
      'en': 'Favorites'
    },
    'home_place': {
      'ar': 'المنزل',
      'fr': 'Maison',
      'en': 'Home'
    },
    'work_place': {
      'ar': 'العمل',
      'fr': 'Travail',
      'en': 'Work'
    },
    'center_place': {
      'ar': 'المركز',
      'fr': 'Centre-ville',
      'en': 'Center'
    },
    'route_preview': {
      'ar': 'معاينة المسار',
      'fr': 'Aperçu de l\'itinéraire',
      'en': 'Route Preview'
    },
    'confirm_dropoff_btn': {
      'ar': 'تأكيد الوجهة',
      'fr': 'Confirmer la destination',
      'en': 'Confirm Dropoff'
    },
    'solo_ride': {
      'ar': 'فردية 🚗',
      'fr': 'Solo 🚗',
      'en': 'Solo 🚗'
    },
    'shared_ride': {
      'ar': 'تشاركية 👯‍♀️',
      'fr': 'Partagée 👯‍♀️',
      'en': 'Shared 👯‍♀️'
    },
    'shared_ride_desc': {
      'ar': 'سيتم مشاركة الرحلة مع راكبة أخرى على نفس الطريق. ستدفعين نصف السعر فقط!',
      'fr': 'Trajet partagé avec une autre passagère. Vous ne payez que la moitié !',
      'en': 'Ride shared with another passenger on the same route. You pay half!'
    },
    'base_fare': {
      'ar': 'رسوم الانطلاق',
      'fr': 'Frais de prise en charge',
      'en': 'Base Fare'
    },
    'distance_cost': {
      'ar': 'تكلفة المسافة',
      'fr': 'Coût de la distance',
      'en': 'Distance Cost'
    },
    'time_cost': {
      'ar': 'تكلفة الوقت',
      'fr': 'Coût du temps',
      'en': 'Time Cost'
    },
    'discounted_shared_fare': {
      'ar': 'السعر المخفض (رحلة تشاركية)',
      'fr': 'Prix réduit (trajet partagé)',
      'en': 'Discounted Fare (Shared)'
    },
    'total_fare': {
      'ar': 'إجمالي الأجرة',
      'fr': 'Tarif total',
      'en': 'Total Fare'
    },
    'dora_commission': {
      'ar': 'عمولة DORA (10%)',
      'fr': 'Commission DORA (10%)',
      'en': 'DORA Commission (10%)'
    },
    'driver_net': {
      'ar': 'صافي دخل السائقة',
      'fr': 'Revenu net conductrice',
      'en': 'Driver Net Income'
    },
    'suggest_fare_label': {
      'ar': 'اقترحي سعرك (اختياري)',
      'fr': 'Suggérez votre prix (Optionnel)',
      'en': 'Suggest your price (Optional)'
    },
    'suggest_fare_helper': {
      'ar': 'يمكنك تعديل الأجرة قبل إرسال الطلب لجذب السائقات',
      'fr': 'Modifiez le prix pour attirer plus de conductrices',
      'en': 'Adjust fare to attract more drivers'
    },
    'acceptable_range': {
      'ar': 'النطاق المقبول:',
      'fr': 'Fourchette acceptable :',
      'en': 'Acceptable range:'
    },
    'raise_price_hint': {
      'ar': '(ارفعي السعر لسرعة القبول)',
      'fr': '(Augmentez le prix pour une acceptation plus rapide)',
      'en': '(Raise price for faster acceptance)'
    },
    'send_request_btn': {
      'ar': 'إرسال الطلب',
      'fr': 'Envoyer la demande',
      'en': 'Send Request'
    },
    'send_voice_note_label': {
      'ar': 'لإرسال رسالة صوتية:',
      'fr': 'Pour envoyer un message vocal :',
      'en': 'To send a voice note:'
    },
    'recording_in_progress': {
      'ar': 'جاري التسجيل...',
      'fr': 'Enregistrement...',
      'en': 'Recording...'
    },
    'send_btn': {
      'ar': 'إرسال',
      'fr': 'Envoyer',
      'en': 'Send'
    },
    'drivers_offers_title': {
      'ar': 'عروض السائقات القريبات منكِ',
      'fr': 'Offres des conductrices à proximité',
      'en': 'Offers from nearby drivers'
    },
    'minutes': {
      'ar': 'دقيقة',
      'fr': 'min',
      'en': 'min'
    },
    'accept_btn': {
      'ar': 'قبول',
      'fr': 'Accepter',
      'en': 'Accept'
    },
    'negotiate_btn': {
      'ar': 'فاوضي',
      'fr': 'Négocier',
      'en': 'Negotiate'
    },
    'back_to_home_btn': {
      'ar': 'العودة للرئيسية',
      'fr': 'Retour à l\'accueil',
      'en': 'Back to Home'
    },
    'riders_requests_title': {
      'ar': 'طلبات الركاب',
      'fr': 'Demandes des passagers',
      'en': 'Riders Requests'
    },
    'available_for_drivers': {
      'ar': 'متاحة للسائقين',
      'fr': 'Disponible pour les conductrices',
      'en': 'Available for drivers'
    },
    'online_for_requests': {
      'ar': 'متصل بالطلبات',
      'fr': 'En ligne (Demandes)',
      'en': 'Online for requests'
    },
    'offline': {
      'ar': 'غير متصل',
      'fr': 'Hors ligne',
      'en': 'Offline'
    },
    'shared_intercity_tag': {
      'ar': 'تشاركية سفر 🛣️',
      'fr': 'Partagé (Inter-wilaya) 🛣️',
      'en': 'Shared (Intercity) 🛣️'
    },
    'shared_city_tag': {
      'ar': 'تشاركية مدن 🏢',
      'fr': 'Partagé (En ville) 🏢',
      'en': 'Shared (City) 🏢'
    },
    'fare_label': {
      'ar': 'الأجرة:',
      'fr': 'Tarif :',
      'en': 'Fare:'
    },
    'half_price': {
      'ar': ' (نصف السعر)',
      'fr': ' (Moitié prix)',
      'en': ' (Half Price)'
    },
    'distance_from_you': {
      'ar': 'تبعد عنك:',
      'fr': 'À distance de :',
      'en': 'Distance from you:'
    },
    'current_price_label': {
      'ar': 'السعر الحالي:',
      'fr': 'Prix actuel :',
      'en': 'Current Price:'
    },
    'selected_driver_label': {
      'ar': 'السائقة المختارة:',
      'fr': 'Conductrice sélectionnée :',
      'en': 'Selected Driver:'
    },
    'no_messages_negotiation': {
      'ar': 'لا توجد رسائل بعد، ابدأ بالمفاوضة الآن.',
      'fr': 'Aucun message, commencez à négocier.',
      'en': 'No messages yet, start negotiating now.'
    },
    'send_new_offer': {
      'ar': 'أرسل عرضًا جديدًا',
      'fr': 'Envoyer une nouvelle offre',
      'en': 'Send a new offer'
    },
    'reject_btn': {
      'ar': 'رفض',
      'fr': 'Refuser',
      'en': 'Reject'
    },
    'ride_pin_title': {
      'ar': 'رمز التحقق الخاص برحلتك',
      'fr': 'Code de vérification de votre trajet',
      'en': 'Your Ride Verification PIN'
    },
    'give_pin_to_driver': {
      'ar': 'أعطِ هذا الرمز للسائقة عند الركوب',
      'fr': 'Donnez ce code à la conductrice en montant',
      'en': 'Give this PIN to the driver when boarding'
    },
    'rider_label': {
      'ar': 'الراكبة:',
      'fr': 'Passagère :',
      'en': 'Rider:'
    },
    'driver_label': {
      'ar': 'السائقة:',
      'fr': 'Conductrice :',
      'en': 'Driver:'
    },
    'driver_mode_active': {
      'ar': 'وضع السائق - الرحلة قيد التنفيذ',
      'fr': 'Mode conductrice - Trajet en cours',
      'en': 'Driver Mode - Ride Active'
    },
    'ride_active_now': {
      'ar': 'الرحلة قيد التنفيذ الآن',
      'fr': 'Le trajet est en cours',
      'en': 'Ride is now active'
    },
    'driver_waiting_at_pickup': {
      'ar': 'السائقة في نقطة الانطلاق وتنتظر...',
      'fr': 'La conductrice est au point de départ et attend...',
      'en': 'Driver is at pickup and waiting...'
    },
    'current_waiting_time': {
      'ar': 'وقت الانتظار الحالي:',
      'fr': 'Temps d\'attente actuel :',
      'en': 'Current waiting time:'
    },
    'free_waiting_exceeded': {
      'ar': 'تم تجاوز الـ 5 دقائق المجانية. رسوم إضافية:',
      'fr': 'Les 5 min gratuites sont dépassées. Frais supp. :',
      'en': '5 free minutes exceeded. Extra fee:'
    },
    'call_btn': {
      'ar': 'اتصال',
      'fr': 'Appeler',
      'en': 'Call'
    },
    'message_btn': {
      'ar': 'مراسلة',
      'fr': 'Message',
      'en': 'Message'
    },
    'cancel_btn': {
      'ar': 'إلغاء',
      'fr': 'Annuler',
      'en': 'Cancel'
    },
    'from_label': {
      'ar': 'من:',
      'fr': 'De :',
      'en': 'From:'
    },
    'to_label': {
      'ar': 'إلى:',
      'fr': 'À :',
      'en': 'To:'
    },
    'verifying_location_match': {
      'ar': '✨ جاري التحقق من التطابق الجغرافي وبدء الرحلة تلقائياً...',
      'fr': '✨ Vérification de la position et démarrage automatique...',
      'en': '✨ Verifying location match and auto-starting ride...'
    },
    'location_match_success': {
      'ar': '✅ تطابق الموقع والسرعة! بدأت الرحلة التلقائية.',
      'fr': '✅ Position et vitesse correspondantes ! Trajet démarré.',
      'en': '✅ Location and speed matched! Ride auto-started.'
    },
    'arrived_auto_start_btn': {
      'ar': 'وصلت (تفعيل البدء التلقائي)',
      'fr': 'Arrivée (Activer le démarrage auto)',
      'en': 'Arrived (Enable auto-start)'
    },
    'ride_ongoing_auto': {
      'ar': 'الرحلة مستمرة (بدأت تلقائياً)',
      'fr': 'Trajet en cours (Démarré auto)',
      'en': 'Ride ongoing (Auto-started)'
    },
    'or_enter_pin_manual': {
      'ar': 'أو إدخال كود PIN يدوياً',
      'fr': 'Ou entrer le code PIN manuellement',
      'en': 'Or enter PIN manually'
    },
    'completed_btn': {
      'ar': 'اكتملت',
      'fr': 'Terminé',
      'en': 'Completed'
    },
    'continuous_search_title': {
      'ar': 'البحث المستمر (الرحلات المتتالية)',
      'fr': 'Recherche continue (Trajets enchaînés)',
      'en': 'Continuous Search (Chain Rides)'
    },
    'continuous_search_desc': {
      'ar': 'جاري استقبال طلبات تنطلق بالقرب من منطقة الوصول الحالية لتجنب العودة فارغة.',
      'fr': 'Réception de demandes près de votre destination pour éviter le retour à vide.',
      'en': 'Receiving requests near your current dropoff to avoid empty returns.'
    },
    'from_dropoff_to_center': {
      'ar': 'من الوجهة → وسط المدينة',
      'fr': 'De la destination → Centre-ville',
      'en': 'From Dropoff → City Center'
    },
    'distance_from_dropoff': {
      'ar': 'تبعد 500 متر عن نقطة وصولك',
      'fr': 'À 500m de votre point d\'arrivée',
      'en': '500m from your dropoff point'
    },
    'next_ride_booked_success': {
      'ar': 'تم حجز الرحلة القادمة بنجاح!',
      'fr': 'Prochain trajet réservé avec succès !',
      'en': 'Next ride booked successfully!'
    },
    'pre_book_btn': {
      'ar': 'حجز مسبق',
      'fr': 'Pré-réserver',
      'en': 'Pre-book'
    },
    'live_location': {
      'ar': 'الموقع المباشر',
      'fr': 'Position en direct',
      'en': 'Live Location'
    },
    'eta_and_distance_remaining': {
      'ar': 'الوقت المتوقع: 12 دقيقة | المسافة المتبقية: 6 كم',
      'fr': 'Temps estimé : 12 min | Distance restante : 6 km',
      'en': 'ETA: 12 mins | Distance left: 6 km'
    },
    'write_message_hint': {
      'ar': 'اكتب رسالة...',
      'fr': 'Écrivez un message...',
      'en': 'Type a message...'
    },
    'incoming_ride_alert_title': {
      'ar': 'طلب توصيلة جديد!',
      'fr': 'Nouvelle demande de trajet !',
      'en': 'New ride request!'
    },
    'ignore_btn': {
      'ar': 'تجاهل',
      'fr': 'Ignorer',
      'en': 'Ignore'
    },
    'accept_request_btn': {
      'ar': 'قبول الطلب',
      'fr': 'Accepter la demande',
      'en': 'Accept Request'
    },
    'call_emergency_contact': {
      'ar': 'اتصال بأقرب شخص',
      'fr': 'Appeler un proche',
      'en': 'Call Emergency Contact'
    },
    'trigger_sos_alarm': {
      'ar': 'تفعيل إنذار الطوارئ (SOS)',
      'fr': 'Déclencher l\'alarme (SOS)',
      'en': 'Trigger SOS Alarm'
    },
    'sos_sent_success': {
      'ar': 'تم إرسال نداء الاستغاثة بنجاح للإدارة!',
      'fr': 'SOS envoyé avec succès à l\'administration !',
      'en': 'SOS sent successfully to administration!'
    },
    'start_recording': {
      'ar': 'بدء التسجيل',
      'fr': 'Commencer l\'enregistrement',
      'en': 'Start Recording'
    },
    'report_complaint': {
      'ar': 'إبلاغ عن شكوى / مساعدة',
      'fr': 'Signaler un problème / Aide',
      'en': 'Report Complaint / Help'
    },
    'safe_share_created': {
      'ar': 'تم إنشاء رسالة مشاركة آمنة',
      'fr': 'Message de partage sécurisé créé',
      'en': 'Safe share message created'
    },
    'confirm_payment_receive_title': {
      'ar': 'تأكيد استلام الدفع',
      'fr': 'Confirmer la réception du paiement',
      'en': 'Confirm Payment Receipt'
    },
    'confirm_payment_title': {
      'ar': 'تأكيد الدفع',
      'fr': 'Confirmer le paiement',
      'en': 'Confirm Payment'
    },
    'agreed_fare_label': {
      'ar': 'الأجرة المتفق عليها:',
      'fr': 'Tarif convenu :',
      'en': 'Agreed Fare:'
    },
    'distance_label': {
      'ar': 'المسافة:',
      'fr': 'Distance :',
      'en': 'Distance:'
    },
    'duration_label': {
      'ar': 'المدة:',
      'fr': 'Durée :',
      'en': 'Duration:'
    },
    'commission_label': {
      'ar': 'العمولة:',
      'fr': 'Commission :',
      'en': 'Commission:'
    },
    'net_for_you_label': {
      'ar': 'الصافي لك:',
      'fr': 'Net pour vous :',
      'en': 'Net for you:'
    },
    'net_profits_label': {
      'ar': 'صافي الأرباح:',
      'fr': 'Bénéfices nets :',
      'en': 'Net Profits:'
    },
    'i_received_payment': {
      'ar': 'استلمت الدفع',
      'fr': 'J\'ai reçu le paiement',
      'en': 'I received payment'
    },
    'i_paid_driver': {
      'ar': 'دفعت للسائقة',
      'fr': 'J\'ai payé la conductrice',
      'en': 'I paid the driver'
    },
    'confirm_btn': {
      'ar': 'تأكيد',
      'fr': 'Confirmer',
      'en': 'Confirm'
    },
    'rate_rider_title': {
      'ar': 'قيم الراكبة',
      'fr': 'Évaluer la passagère',
      'en': 'Rate Rider'
    },
    'rate_ride_title': {
      'ar': 'قيّم الرحلة',
      'fr': 'Évaluer le trajet',
      'en': 'Rate Ride'
    },
    'add_comment_hint': {
      'ar': 'أضف تعليقًا (اختياري)',
      'fr': 'Ajouter un commentaire (Optionnel)',
      'en': 'Add a comment (Optional)'
    },
    'submit_btn': {
      'ar': 'إرسال',
      'fr': 'Envoyer',
      'en': 'Submit'
    },
    'driver_receipt_title': {
      'ar': 'إيصال السائق',
      'fr': 'Reçu Conductrice',
      'en': 'Driver Receipt'
    },
    'ride_receipt_title': {
      'ar': 'إيصال الرحلة',
      'fr': 'Reçu du trajet',
      'en': 'Ride Receipt'
    },
    'base_fare_label': {
      'ar': 'الأساس:',
      'fr': 'Base :',
      'en': 'Base:'
    },
    'per_km_label': {
      'ar': 'لكل كم:',
      'fr': 'Par km :',
      'en': 'Per km:'
    },
    'per_minute_label': {
      'ar': 'لكل دقيقة:',
      'fr': 'Par min :',
      'en': 'Per minute:'
    },
    'total_label': {
      'ar': 'الإجمالي:',
      'fr': 'Total :',
      'en': 'Total:'
    },
    'net_label': {
      'ar': 'الصافي:',
      'fr': 'Net :',
      'en': 'Net:'
    },
    'save_to_gallery_btn': {
      'ar': 'حفظ في المعرض',
      'fr': 'Enregistrer',
      'en': 'Save to Gallery'
    },
    'saved_to_gallery_success': {
      'ar': 'تم الحفظ في المعرض بنجاح.',
      'fr': 'Enregistré dans la galerie.',
      'en': 'Saved to gallery successfully.'
    },
    'share_receipt_btn': {
      'ar': 'شاركي الإيصال',
      'fr': 'Partager le reçu',
      'en': 'Share Receipt'
    },
    'preparing_receipt_share': {
      'ar': 'جاري تجهيز الصورة للمشاركة...',
      'fr': 'Préparation du reçu...',
      'en': 'Preparing receipt for sharing...'
    },
    'view_history_btn': {
      'ar': 'عرض السجل',
      'fr': 'Voir l\'historique',
      'en': 'View History'
    },
    'driver_history_title': {
      'ar': 'سجل السائق',
      'fr': 'Historique Conductrice',
      'en': 'Driver History'
    },
    'ride_history_title': {
      'ar': 'سجل الرحلات',
      'fr': 'Historique des trajets',
      'en': 'Ride History'
    },
    'filter_all': {
      'ar': 'الكل',
      'fr': 'Tous',
      'en': 'All'
    },
    'filter_completed': {
      'ar': 'مكتمل',
      'fr': 'Terminé',
      'en': 'Completed'
    },
    'filter_cancelled': {
      'ar': 'ملغى',
      'fr': 'Annulé',
      'en': 'Cancelled'
    },
    'earnings_dashboard_title': {
      'ar': 'لوحة الأرباح',
      'fr': 'Tableau de bord des gains',
      'en': 'Earnings Dashboard'
    },
    'earnings_today': {
      'ar': 'اليوم:',
      'fr': 'Aujourd\'hui :',
      'en': 'Today:'
    },
    'earnings_week': {
      'ar': 'هذا الأسبوع:',
      'fr': 'Cette semaine :',
      'en': 'This week:'
    },
    'earnings_month': {
      'ar': 'هذا الشهر:',
      'fr': 'Ce mois :',
      'en': 'This month:'
    },
    'quick_stats_title': {
      'ar': 'مؤشرات سريعة',
      'fr': 'Statistiques rapides',
      'en': 'Quick Stats'
    },
    'four_rides_today': {
      'ar': '4 رحلات اليوم',
      'fr': '4 trajets aujourd\'hui',
      'en': '4 rides today'
    },
    'satisfaction_93': {
      'ar': '93% رضا',
      'fr': '93% satisfaction',
      'en': '93% satisfaction'
    },
    'live_update': {
      'ar': 'تحديث لحظي',
      'fr': 'Mise à jour en direct',
      'en': 'Live Update'
    },
    'personal_settings': {
      'ar': 'الإعدادات الشخصية',
      'fr': 'Paramètres personnels',
      'en': 'Personal Settings'
    },
    'online_status': {
      'ar': 'الوضع المتصل',
      'fr': 'Statut en ligne',
      'en': 'Online Status'
    },
    'notifications_setting': {
      'ar': 'الإشعارات',
      'fr': 'Notifications',
      'en': 'Notifications'
    },
    'share_ride': {
      'ar': 'مشاركة الرحلة',
      'fr': 'Partager le trajet',
      'en': 'Share Ride'
    },
    'profile_updated_success': {
      'ar': 'تم تحديث الملف الشخصي بنجاح',
      'fr': 'Profil mis à jour avec succès',
      'en': 'Profile updated successfully'
    },
    'avatar_updated_success': {
      'ar': 'تم تحديث الصورة الشخصية بنجاح',
      'fr': 'Photo de profil mise à jour avec succès',
      'en': 'Avatar updated successfully'
    },
    'avatar_update_failed': {
      'ar': 'فشل تحديث الصورة. حاول مرة أخرى.',
      'fr': 'Échec de la mise à jour de la photo. Réessayez.',
      'en': 'Failed to update avatar. Try again.'
    },
    'my_profile_title': {
      'ar': 'ملفي الشخصي',
      'fr': 'Mon Profil',
      'en': 'My Profile'
    },
    'my_info_title': {
      'ar': 'معلوماتي',
      'fr': 'Mes Informations',
      'en': 'My Info'
    },
    'full_name_label_dup': {
      'ar': 'الاسم الكامل',
      'fr': 'Nom complet',
      'en': 'Full Name'
    },
    'phone_number_label': {
      'ar': 'رقم الهاتف',
      'fr': 'Numéro de téléphone',
      'en': 'Phone Number'
    },
    'save_changes_btn': {
      'ar': '💾 حفظ التغييرات',
      'fr': '💾 Enregistrer',
      'en': '💾 Save Changes'
    },
    'wallet_and_subscription': {
      'ar': 'محفظتي واشتراكي',
      'fr': 'Mon Portefeuille & Abonnement',
      'en': 'My Wallet & Subscription'
    },
    'wallet_and_subscription_subtitle': {
      'ar': 'اشتراك شهري، رصيد المحفظة، العمولات',
      'fr': 'Abonnement, Solde, Commissions',
      'en': 'Monthly Subscription, Wallet Balance, Commissions'
    },
    'help_and_complaints': {
      'ar': 'المساعدة والشكاوى 🎧',
      'fr': 'Aide et Réclamations 🎧',
      'en': 'Help and Complaints 🎧'
    },
    'privacy_policy_title': {
      'ar': 'سياسة الخصوصية',
      'fr': 'Politique de confidentialité',
      'en': 'Privacy Policy'
    },
    'admin_dashboard_title': {
      'ar': 'لوحة تحكم الإدارة',
      'fr': 'Tableau de bord d\'administration',
      'en': 'Admin Dashboard'
    },
    'admin_dashboard_subtitle': {
      'ar': 'إدارة السائقات والطلبات',
      'fr': 'Gestion des conductrices et des demandes',
      'en': 'Manage drivers and requests'
    },
    'become_driver_title': {
      'ar': 'كوني سائقة وانطلقي معنا 🚗',
      'fr': 'Devenez conductrice avec nous 🚗',
      'en': 'Become a driver and join us 🚗'
    },
    'become_driver_subtitle': {
      'ar': 'سجلي كسائقة وابدئي في تحقيق الأرباح',
      'fr': 'Inscrivez-vous et commencez à gagner',
      'en': 'Register as a driver and start earning'
    },
    'request_under_review': {
      'ar': 'طلبك قيد المراجعة ⏳',
      'fr': 'Demande en cours d\'examen ⏳',
      'en': 'Request under review ⏳'
    },
    'admin_reviewing_data': {
      'ar': 'الإدارة تقوم بمراجعة بياناتك حالياً للموافقة',
      'fr': 'L\'administration examine vos données',
      'en': 'Administration is reviewing your data'
    },
    'start_driving_btn': {
      'ar': 'نبدأ سياقة 🚖',
      'fr': 'Commencer à conduire 🚖',
      'en': 'Start driving 🚖'
    },
    'start_driving_subtitle': {
      'ar': 'اضغطي للعودة والانتقال لاستقبال الطلبات',
      'fr': 'Cliquez pour retourner et recevoir des demandes',
      'en': 'Click to return and receive requests'
    },
    'ready_to_drive_msg': {
      'ar': 'أنت الآن جاهزة للقيادة! اضغطي على زر (وضع السائقة) أسفل الخريطة.',
      'fr': 'Prête ! Cliquez sur (Mode conductrice) en bas de la carte.',
      'en': 'Ready! Click on (Driver Mode) at the bottom of the map.'
    },
    'change_language_btn': {
      'ar': 'تغيير اللغة',
      'fr': 'Changer la langue',
      'en': 'Change Language'
    },
    'logout_btn': {
      'ar': 'تسجيل الخروج',
      'fr': 'Déconnexion',
      'en': 'Logout'
    },
    'app_version': {
      'ar': 'DORA App • نسخة 1.0',
      'fr': 'DORA App • Version 1.0',
      'en': 'DORA App • Version 1.0'
    },
    'choose_language_dialog': {
      'ar': 'اختر اللغة',
      'fr': 'Choisissez la langue',
      'en': 'Choose Language'
    },
    'renew_monthly_subscription_title': {
      'ar': 'تجديد الاشتراك الشهري',
      'fr': 'Renouveler l\'abonnement mensuel',
      'en': 'Renew Monthly Subscription'
    },
    'renew_instruction_1': {
      'ar': 'لتجديد اشتراكك بمبلغ 3000 دج:',
      'fr': 'Pour renouveler votre abonnement à 3000 DZD :',
      'en': 'To renew your subscription for 3000 DZD:'
    },
    'renew_instruction_2': {
      'ar': '1. افتحي تطبيق بريدي موب',
      'fr': '1. Ouvrez l\'application BaridiMob',
      'en': '1. Open the BaridiMob app'
    },
    'renew_instruction_3': {
      'ar': '2. حوّلي 3000 دج إلى رقم الحساب:',
      'fr': '2. Transférez 3000 DZD vers le compte :',
      'en': '2. Transfer 3000 DZD to account number:'
    },
    'renew_instruction_4': {
      'ar': '3. أرسلي لنا صورة الإيصال عبر الواتساب للتأكيد.',
      'fr': '3. Envoyez-nous le reçu sur WhatsApp pour confirmation.',
      'en': '3. Send us the receipt on WhatsApp for confirmation.'
    },
    'renew_note': {
      'ar': 'ملاحظة: سيتم تفعيل اشتراكك خلال ساعة واحدة.',
      'fr': 'Note : Votre abonnement sera activé dans l\'heure.',
      'en': 'Note: Your subscription will be activated within an hour.'
    },
    'close_btn': {
      'ar': 'إغلاق',
      'fr': 'Fermer',
      'en': 'Close'
    },
    'free_trial_month': {
      'ar': 'شهر تجريبي مجاني 🎁',
      'fr': 'Mois d\'essai gratuit 🎁',
      'en': 'Free Trial Month 🎁'
    },
    'subscription_active': {
      'ar': 'الاشتراك نشط',
      'fr': 'Abonnement actif',
      'en': 'Subscription Active'
    },
    'subscription_expired': {
      'ar': 'الاشتراك منتهٍ',
      'fr': 'Abonnement expiré',
      'en': 'Subscription Expired'
    },
    'days_remaining': {
      'ar': 'متبقي:',
      'fr': 'Restant :',
      'en': 'Remaining:'
    },
    'days': {
      'ar': 'يوم',
      'fr': 'jours',
      'en': 'days'
    },
    'free_trial_note': {
      'ar': 'بعد انتهاء الفترة التجريبية، سيتم تطبيق اشتراك شهري بـ 3000 دج',
      'fr': 'Après la période d\'essai, un abonnement de 3000 DZD s\'applique',
      'en': 'After the free trial, a monthly subscription of 3000 DZD applies'
    },
    'commission_system': {
      'ar': 'نظام العمولة',
      'fr': 'Système de commission',
      'en': 'Commission System'
    },
    'minimum_fare': {
      'ar': 'الحد الأدنى للأجرة',
      'fr': 'Tarif minimum',
      'en': 'Minimum Fare'
    },
    'dora_commission_per_ride': {
      'ar': 'عمولة DORA من كل رحلة',
      'fr': 'Commission DORA par trajet',
      'en': 'DORA commission per ride'
    },
    'net_income_per_ride': {
      'ar': 'صافي دخلك من كل رحلة',
      'fr': 'Votre revenu net par trajet',
      'en': 'Your net income per ride'
    },
    'example_ride': {
      'ar': 'مثال - رحلة بـ 500 دج:',
      'fr': 'Exemple - Trajet à 500 DZD :',
      'en': 'Example - 500 DZD ride:'
    },
    'dora_commission_example': {
      'ar': '  عمولة DORA',
      'fr': '  Commission DORA',
      'en': '  DORA commission'
    },
    'net_income_example': {
      'ar': '  ✅ صافي دخلك',
      'fr': '  ✅ Revenu net',
      'en': '  ✅ Net income'
    },
    'fare_calculation_note': {
      'ar': '💡 الأجرة تُحسب تلقائياً بناءً على المسافة والوقت، مع رفع السعر ليلاً وفي ساعات الذروة.',
      'fr': '💡 Le tarif est calculé automatiquement (distance, temps, nuit, pointe).',
      'en': '💡 Fare is calculated automatically based on distance, time, and peak hours.'
    },
    'digital_wallet': {
      'ar': 'المحفظة الرقمية',
      'fr': 'Portefeuille numérique',
      'en': 'Digital Wallet'
    },
    'balance_available': {
      'ar': '✅ رصيدك متاح',
      'fr': '✅ Solde disponible',
      'en': '✅ Balance available'
    },
    'balance_negative': {
      'ar': '⚠️ رصيد سالب - يرجى الشحن',
      'fr': '⚠️ Solde négatif - Veuillez recharger',
      'en': '⚠️ Negative balance - Please recharge'
    },
    'charge_wallet_baridimob': {
      'ar': 'شحن المحفظة عبر بريدي موب',
      'fr': 'Recharger via BaridiMob',
      'en': 'Recharge via BaridiMob'
    },
    'renew_subscription_btn': {
      'ar': '🔄  تجديد الاشتراك - 3000 دج/شهر',
      'fr': '🔄 Renouveler l\'abonnement - 3000 DZD/mois',
      'en': '🔄 Renew Subscription - 3000 DZD/month'
    },
    'subscription_plans_title': {
      'ar': 'خطط الاشتراك',
      'fr': 'Plans d\'abonnement',
      'en': 'Subscription Plans'
    },
    'free_trial_plan_title': {
      'ar': 'شهر تجريبي',
      'fr': 'Mois d\'essai',
      'en': 'Free Trial'
    },
    'free_price': {
      'ar': 'مجاني',
      'fr': 'Gratuit',
      'en': 'Free'
    },
    'free_for_new_driver': {
      'ar': 'مجاني لكل سائقة جديدة',
      'fr': 'Gratuit pour chaque nouvelle conductrice',
      'en': 'Free for every new driver'
    },
    'thirty_days_full': {
      'ar': '30 يوم كاملة',
      'fr': '30 jours complets',
      'en': 'Full 30 days'
    },
    'all_app_features': {
      'ar': 'جميع ميزات التطبيق',
      'fr': 'Toutes les fonctionnalités',
      'en': 'All app features'
    },
    'commission_10_percent': {
      'ar': 'عمولة 10% فقط على كل رحلة',
      'fr': '10% de commission par trajet',
      'en': 'Only 10% commission per ride'
    },
    'monthly_subscription_plan_title': {
      'ar': 'اشتراك شهري',
      'fr': 'Abonnement mensuel',
      'en': 'Monthly Subscription'
    },
    'three_thousand_dzd_month': {
      'ar': '3000 دج / شهر',
      'fr': '3000 DZD / mois',
      'en': '3000 DZD / month'
    },
    'priority_appearance': {
      'ar': 'أولوية ظهورك في قائمة السائقات',
      'fr': 'Apparence prioritaire',
      'en': 'Priority appearance'
    },
    'dedicated_tech_support': {
      'ar': 'دعم فني مخصص',
      'fr': 'Support technique dédié',
      'en': 'Dedicated tech support'
    },
    'monthly_earnings_reports': {
      'ar': 'تقارير الأرباح الشهرية',
      'fr': 'Rapports de gains mensuels',
      'en': 'Monthly earnings reports'
    },
    'charge_wallet_title': {
      'ar': 'شحن المحفظة',
      'fr': 'Recharger le portefeuille',
      'en': 'Recharge Wallet'
    },
    'charge_instruction_1': {
      'ar': 'لشحن محفظتك:',
      'fr': 'Pour recharger votre portefeuille :',
      'en': 'To recharge your wallet:'
    },
    'charge_instruction_2': {
      'ar': '1. أرسلي المبلغ المطلوب عبر بريدي موب إلى:',
      'fr': '1. Envoyez le montant via BaridiMob à :',
      'en': '1. Send the amount via BaridiMob to:'
    },
    'charge_instruction_3': {
      'ar': '2. أرسلي صورة الإيصال + اسم حسابك للمشرف عبر الواتساب.',
      'fr': '2. Envoyez le reçu + nom du compte sur WhatsApp.',
      'en': '2. Send receipt + account name on WhatsApp.'
    },
    'charge_note': {
      'ar': 'سيتم إضافة الرصيد خلال ساعة.',
      'fr': 'Le solde sera ajouté dans l\'heure.',
      'en': 'Balance will be added within an hour.'
    },
    'ok_btn': {
      'ar': 'حسناً',
      'fr': 'D\'accord',
      'en': 'OK'
    },
    'please_select_complaint_type': {
      'ar': 'الرجاء اختيار نوع الشكوى',
      'fr': 'Veuillez sélectionner le type de réclamation',
      'en': 'Please select complaint type'
    },
    'please_write_problem_details': {
      'ar': 'الرجاء كتابة تفاصيل المشكلة',
      'fr': 'Veuillez écrire les détails du problème',
      'en': 'Please write problem details'
    },
    'user_not_logged_in': {
      'ar': 'المستخدم غير مسجل الدخول',
      'fr': 'Utilisateur non connecté',
      'en': 'User not logged in'
    },
    'complaint_sent_success': {
      'ar': '✅ تم إرسال الشكوى للإدارة بنجاح. سنقوم بمراجعتها قريباً.',
      'fr': '✅ Réclamation envoyée avec succès. Nous l\'examinerons bientôt.',
      'en': '✅ Complaint sent successfully. We will review it soon.'
    },
    'error_occurred_prefix': {
      'ar': 'حدث خطأ:',
      'fr': 'Une erreur s\'est produite :',
      'en': 'An error occurred:'
    },
    'support_intro_message': {
      'ar': 'نحن هنا لمساعدتك. جميع الشكاوى تتم مراجعتها بسرية تامة من قبل الإدارة.',
      'fr': 'Nous sommes là pour vous aider. Toutes les plaintes sont examinées de manière confidentielle.',
      'en': 'We are here to help. All complaints are reviewed confidentially by administration.'
    },
    'what_is_the_problem': {
      'ar': 'ما هي المشكلة التي تواجهينها؟',
      'fr': 'Quel problème rencontrez-vous ?',
      'en': 'What is the problem you are facing?'
    },
    'choose_complaint_type_hint': {
      'ar': 'اختر نوع الشكوى...',
      'fr': 'Choisissez le type de réclamation...',
      'en': 'Choose complaint type...'
    },
    'complaint_details_title': {
      'ar': 'تفاصيل الشكوى',
      'fr': 'Détails de la réclamation',
      'en': 'Complaint Details'
    },
    'complaint_details_hint': {
      'ar': 'يرجى تزويدنا بأكبر قدر من التفاصيل لنتمكن من مساعدتك...',
      'fr': 'Veuillez fournir autant de détails que possible...',
      'en': 'Please provide as much detail as possible so we can help...'
    },
    'submit_complaint_btn': {
      'ar': 'إرسال الشكوى للإدارة',
      'fr': 'Envoyer à l\'administration',
      'en': 'Submit to Administration'
    },
    'category_delay': {
      'ar': 'السائقة/الراكبة تأخرت جداً',
      'fr': 'Conductrice/Passagère très en retard',
      'en': 'Driver/Rider is very late'
    },
    'category_car_mismatch': {
      'ar': 'السيارة لا تتطابق مع الوصف',
      'fr': 'Le véhicule ne correspond pas à la description',
      'en': 'Car does not match description'
    },
    'category_bad_behavior': {
      'ar': 'سلوك غير لائق',
      'fr': 'Comportement inapproprié',
      'en': 'Inappropriate behavior'
    },
    'category_payment_issue': {
      'ar': 'مشكلة في الدفع أو السعر',
      'fr': 'Problème de paiement ou de prix',
      'en': 'Payment or price issue'
    },
    'category_other': {
      'ar': 'أخرى (يرجى كتابة التفاصيل)',
      'fr': 'Autre (veuillez préciser)',
      'en': 'Other (please specify)'
    },
    'no_new_notifications': {
      'ar': 'لا توجد إشعارات جديدة',
      'fr': 'Aucune nouvelle notification',
      'en': 'No new notifications'
    },
    'notif_welcome_title': {
      'ar': 'مرحباً بكِ في DORA! 🎀',
      'fr': 'Bienvenue sur DORA ! 🎀',
      'en': 'Welcome to DORA! 🎀'
    },
    'notif_welcome_body': {
      'ar': 'شكراً لانضمامك لأول تطبيق لتوصيل السيدات في الجزائر.',
      'fr': 'Merci de rejoindre la 1ère appli de VTC pour femmes en Algérie.',
      'en': 'Thanks for joining the 1st ride-hailing app for women in Algeria.'
    },
    'two_hours_ago': {
      'ar': 'منذ ساعتين',
      'fr': 'Il y a 2 heures',
      'en': '2 hours ago'
    },
    'notif_driver_active_title': {
      'ar': 'تم تفعيل حساب السائقة 🚗',
      'fr': 'Compte conductrice activé 🚗',
      'en': 'Driver account activated 🚗'
    },
    'notif_driver_active_body': {
      'ar': 'تهانينا! حسابك كسائقة تم توثيقه. يمكنك الآن استقبال الطلبات.',
      'fr': 'Félicitations ! Votre compte est vérifié. Recevez des demandes.',
      'en': 'Congrats! Your account is verified. You can now receive requests.'
    },
    'five_hours_ago': {
      'ar': 'منذ 5 ساعات',
      'fr': 'Il y a 5 heures',
      'en': '5 hours ago'
    },
    'notif_discount_title': {
      'ar': 'خصم 50% على رحلاتك 👯‍♀️',
      'fr': '50% de réduction sur vos trajets 👯‍♀️',
      'en': '50% off your rides 👯‍♀️'
    },
    'notif_discount_body': {
      'ar': 'جربي ميزة الرحلة التشاركية الجديدة ووفري نصف السعر!',
      'fr': 'Essayez le nouveau covoiturage et économisez la moitié !',
      'en': 'Try the new carpooling feature and save half the price!'
    },
    'yesterday': {
      'ar': 'أمس',
      'fr': 'Hier',
      'en': 'Yesterday'
    },
    'please_fill_car_details': {
      'ar': 'يرجى ملء جميع بيانات السيارة',
      'fr': 'Veuillez remplir toutes les données du véhicule',
      'en': 'Please fill all car details'
    },
    'application_received_success': {
      'ar': 'تم استلام طلبك بنجاح! الإدارة ستقوم بمراجعته قريباً.',
      'fr': 'Demande reçue avec succès ! L\'administration l\'examinera bientôt.',
      'en': 'Application received successfully! Administration will review it soon.'
    },
    'join_as_captain_title': {
      'ar': 'طلب الانضمام ككابتن',
      'fr': 'Demande d\'inscription comme conductrice',
      'en': 'Join as Captain'
    },
    'submit_application_btn': {
      'ar': 'إرسال الطلب',
      'fr': 'Envoyer la demande',
      'en': 'Submit Application'
    },
    'next_btn_dup': {
      'ar': 'التالي',
      'fr': 'Suivant',
      'en': 'Next'
    },
    'cancel_btn_dup': {
      'ar': 'إلغاء',
      'fr': 'Annuler',
      'en': 'Cancel'
    },
    'previous_btn': {
      'ar': 'السابق',
      'fr': 'Précédent',
      'en': 'Previous'
    },
    'car_details_step': {
      'ar': 'بيانات السيارة',
      'fr': 'Données du véhicule',
      'en': 'Car Details'
    },
    'car_brand_hint': {
      'ar': 'الماركة (مثل تويوتا)',
      'fr': 'Marque (ex: Toyota)',
      'en': 'Brand (e.g. Toyota)'
    },
    'car_model_hint': {
      'ar': 'الموديل (مثل ياريس)',
      'fr': 'Modèle (ex: Yaris)',
      'en': 'Model (e.g. Yaris)'
    },
    'car_year_hint': {
      'ar': 'سنة الصنع',
      'fr': 'Année de fabrication',
      'en': 'Manufacturing Year'
    },
    'car_color_hint': {
      'ar': 'اللون',
      'fr': 'Couleur',
      'en': 'Color'
    },
    'car_plate_hint': {
      'ar': 'رقم اللوحة',
      'fr': 'Immatriculation',
      'en': 'License Plate'
    },
    'upload_documents_step': {
      'ar': 'رفع المستندات',
      'fr': 'Télécharger des documents',
      'en': 'Upload Documents'
    },
    'documents_upload_note': {
      'ar': 'يرجى التأكد من أن الصور واضحة لتسريع عملية القبول من قبل الإدارة.',
      'fr': 'Veuillez vous assurer que les photos sont claires pour accélérer l\'acceptation.',
      'en': 'Please ensure photos are clear to speed up the acceptance process.'
    },
    'driving_license_image': {
      'ar': 'صورة رخصة القيادة',
      'fr': 'Photo du permis de conduire',
      'en': 'Driving License Image'
    },
    'carte_grise_image': {
      'ar': 'صورة البطاقة الرمادية (Carte Grise)',
      'fr': 'Photo de la Carte Grise',
      'en': 'Carte Grise Image'
    },
    'privacy_policy_and_terms': {
      'ar': 'سياسة الخصوصية وشروط الاستخدام',
      'fr': 'Politique de confidentialité et CGU',
      'en': 'Privacy Policy and Terms of Use'
    },
    'privacy_policy_intro': {
      'ar': 'مرحباً بك في تطبيقنا. نحن نأخذ خصوصيتك بجدية بالغة. يرجى قراءة هذه السياسة بعناية لفهم كيف نجمع بياناتك ونستخدمها ونحميها.',
      'fr': 'Bienvenue. Nous prenons votre vie privée très au sérieux. Veuillez lire cette politique pour comprendre comment nous gérons vos données.',
      'en': 'Welcome. We take your privacy very seriously. Please read this policy to understand how we collect, use, and protect your data.'
    },
    'privacy_section_1_title': {
      'ar': '1. جمع البيانات واستخدامها',
      'fr': '1. Collecte et utilisation des données',
      'en': '1. Data Collection and Use'
    },
    'privacy_section_1_body': {
      'ar': 'نحن نجمع بعض البيانات الأساسية لضمان عمل التطبيق بأمان وكفاءة، وتشمل:\n• المعلومات الشخصية: الاسم، رقم الهاتف، والبريد الإلكتروني للتسجيل.\n• صور الهوية: تُجمع فقط لغرض التحقق الأمني للسائقات وتُحفظ بشكل آمن ولا تُعرض للعامة.\n• الموقع الجغرافي (GPS): يُستخدم لتحديد مسار الرحلة. بالنسبة للسائقات، يتم تتبع الموقع في الخلفية فقط أثناء تفعيل وضع "متصل" لضمان الأمان وتوفير الرحلات للراكبات.',
      'fr': 'Nous collectons des données de base :\n• Infos personnelles : Nom, téléphone, e-mail.\n• Photos d\'identité : Uniquement pour la vérification des conductrices.\n• Localisation (GPS) : Utilisée pour le trajet. Suivie en arrière-plan uniquement en mode "en ligne" pour la sécurité.',
      'en': 'We collect basic data:\n• Personal Info: Name, phone, email.\n• ID photos: Only for driver verification, kept secure.\n• GPS Location: Used for routing. Tracked in background only when "online" for safety.'
    },
    'privacy_section_2_title': {
      'ar': '2. حماية البيانات',
      'fr': '2. Protection des données',
      'en': '2. Data Protection'
    },
    'privacy_section_2_body': {
      'ar': 'جميع بياناتك الحساسة (مثل صور بطاقة الهوية) مشفرة ومحفوظة في خوادم آمنة. نحن لا نشارك بياناتك مع أي طرف ثالث لأغراض تسويقية.',
      'fr': 'Vos données sensibles sont cryptées. Nous ne les partageons pas à des fins de marketing.',
      'en': 'Sensitive data is encrypted. We do not share data with third parties for marketing.'
    },
    'privacy_section_3_title': {
      'ar': '3. سياسة الكاميرا والصور',
      'fr': '3. Politique Caméra/Photos',
      'en': '3. Camera and Photos Policy'
    },
    'privacy_section_3_body': {
      'ar': 'التطبيق يطلب صلاحية الوصول للكاميرا ومعرض الصور حصرياً لتمكينك من إكمال ملفك الشخصي ورفع مستندات التحقق أو تغيير صورتك الرمزية (Avatar).',
      'fr': 'L\'accès à la caméra et aux photos est uniquement pour le profil et les documents.',
      'en': 'Camera and photos access is solely to complete your profile and upload documents.'
    },
    'privacy_section_4_title': {
      'ar': '4. حقوق المستخدم',
      'fr': '4. Droits des utilisateurs',
      'en': '4. User Rights'
    },
    'privacy_section_4_body': {
      'ar': 'يحق لك في أي وقت طلب حذف حسابك بالكامل ومسح جميع بياناتك من خوادمنا عبر التواصل مع الدعم الفني.',
      'fr': 'Vous pouvez demander la suppression de votre compte et de vos données à tout moment via le support.',
      'en': 'You can request full account and data deletion at any time via technical support.'
    },
    'privacy_policy_agreement': {
      'ar': 'باستخدامك لهذا التطبيق، فإنك توافق على هذه السياسات والشروط.',
      'fr': 'En utilisant cette application, vous acceptez ces politiques et conditions.',
      'en': 'By using this app, you agree to these policies and terms.'
    },
    'admin_dashboard_title_dup': {
      'ar': 'لوحة المشرف 🛡️',
      'fr': 'Tableau de bord Admin 🛡️',
      'en': 'Admin Dashboard 🛡️'
    },
    'drivers_tab': {
      'ar': 'السائقات',
      'fr': 'Conductrices',
      'en': 'Drivers'
    },
    'identity_tab': {
      'ar': 'الهوية',
      'fr': 'Identité',
      'en': 'Identity'
    },
    'vehicles_tab': {
      'ar': 'السيارات',
      'fr': 'Véhicules',
      'en': 'Vehicles'
    },
    'complaints_tab': {
      'ar': 'الشكاوى',
      'fr': 'Plaintes',
      'en': 'Complaints'
    },
    'rides_tab': {
      'ar': 'الرحلات',
      'fr': 'Trajets',
      'en': 'Rides'
    },
    'fares_tab': {
      'ar': 'الأسعار',
      'fr': 'Tarifs',
      'en': 'Fares'
    },
    'discounts_tab': {
      'ar': 'الخصومات',
      'fr': 'Réductions',
      'en': 'Discounts'
    },
    'lost_items_tab': {
      'ar': 'المفقودات',
      'fr': 'Objets perdus',
      'en': 'Lost Items'
    },
    'disputes_tab': {
      'ar': 'النزاعات',
      'fr': 'Litiges',
      'en': 'Disputes'
    },
    'broadcast_notification_btn': {
      'ar': 'إشعار عام',
      'fr': 'Notification générale',
      'en': 'Broadcast Notification'
    },
    'no_drivers_registered': {
      'ar': 'لا توجد سائقات مسجلات حالياً.',
      'fr': 'Aucune conductrice inscrite actuellement.',
      'en': 'No drivers currently registered.'
    },
    'no_name': {
      'ar': 'بدون اسم',
      'fr': 'Sans nom',
      'en': 'No name'
    },
    'accept_btn_dup': {
      'ar': 'قبول',
      'fr': 'Accepter',
      'en': 'Accept'
    },
    'reject_btn_dup': {
      'ar': 'رفض',
      'fr': 'Refuser',
      'en': 'Reject'
    },
    'no_pending_documents': {
      'ar': 'لا توجد مستندات معلقة 🎉',
      'fr': 'Aucun document en attente 🎉',
      'en': 'No pending documents 🎉'
    },
    'unknown': {
      'ar': 'مجهول',
      'fr': 'Inconnu',
      'en': 'Unknown'
    },
    'document_type': {
      'ar': 'نوع الوثيقة:',
      'fr': 'Type de document :',
      'en': 'Document type:'
    },
    'pending_status': {
      'ar': 'معلق',
      'fr': 'En attente',
      'en': 'Pending'
    },
    'approve_btn': {
      'ar': 'موافقة',
      'fr': 'Approuver',
      'en': 'Approve'
    },
    'no_pending_vehicles': {
      'ar': 'لا توجد سيارات معلقة 🎉',
      'fr': 'Aucun véhicule en attente 🎉',
      'en': 'No pending vehicles 🎉'
    },
    'car_color': {
      'ar': 'اللون:',
      'fr': 'Couleur :',
      'en': 'Color:'
    },
    'car_plate': {
      'ar': 'اللوحة:',
      'fr': 'Plaque :',
      'en': 'Plate:'
    },
    'no_complaints_currently': {
      'ar': 'لا توجد شكاوى حالياً. 🎉',
      'fr': 'Aucune plainte actuellement. 🎉',
      'en': 'No complaints currently. 🎉'
    },
    'status_open': {
      'ar': 'مفتوحة',
      'fr': 'Ouverte',
      'en': 'Open'
    },
    'status_reviewing': {
      'ar': 'قيد المراجعة',
      'fr': 'En cours d\'examen',
      'en': 'Reviewing'
    },
    'status_resolved': {
      'ar': 'محلولة',
      'fr': 'Résolue',
      'en': 'Resolved'
    },
    'status_dismissed': {
      'ar': 'مرفوضة',
      'fr': 'Rejetée',
      'en': 'Dismissed'
    },
    'reason_label': {
      'ar': 'السبب:',
      'fr': 'Raison :',
      'en': 'Reason:'
    },
    'reporter_label': {
      'ar': 'المبلِّغ:',
      'fr': 'Signalé par :',
      'en': 'Reporter:'
    },
    'against_label': {
      'ar': 'ضد:',
      'fr': 'Contre :',
      'en': 'Against:'
    },
    'review_btn': {
      'ar': 'مراجعة',
      'fr': 'Examiner',
      'en': 'Review'
    },
    'resolve_and_close_btn': {
      'ar': 'حل وإغلاق',
      'fr': 'Résoudre et fermer',
      'en': 'Resolve & Close'
    },
    'no_active_rides_now': {
      'ar': 'لا توجد رحلات نشطة الآن',
      'fr': 'Aucun trajet actif actuellement',
      'en': 'No active rides right now'
    },
    'status_label': {
      'ar': 'الحالة:',
      'fr': 'Statut :',
      'en': 'Status:'
    },
    'base_fare_label_dup': {
      'ar': 'انطلاق:',
      'fr': 'Base :',
      'en': 'Base:'
    },
    'per_km_label_dup': {
      'ar': 'كم:',
      'fr': 'km :',
      'en': 'km:'
    },
    'per_min_label': {
      'ar': 'دق:',
      'fr': 'min :',
      'en': 'min:'
    },
    'min_fare_label': {
      'ar': 'أدنى:',
      'fr': 'Min :',
      'en': 'Min:'
    },
    'send_broadcast_title': {
      'ar': '📢 إرسال إشعار لجميع المستخدمين',
      'fr': '📢 Envoyer une notification à tous',
      'en': '📢 Send broadcast to all users'
    },
    'notification_title_hint': {
      'ar': 'عنوان الإشعار',
      'fr': 'Titre de la notification',
      'en': 'Notification title'
    },
    'notification_body_hint': {
      'ar': 'نص الإشعار',
      'fr': 'Corps de la notification',
      'en': 'Notification body'
    },
    'send_notification_btn': {
      'ar': 'إرسال الإشعار',
      'fr': 'Envoyer la notification',
      'en': 'Send Notification'
    },
    'feature_coming_soon': {
      'ar': 'سيتم إضافة هذه الميزة قريباً',
      'fr': 'Cette fonctionnalité sera bientôt ajoutée',
      'en': 'This feature will be added soon'
    },
    'create_new_promo_code': {
      'ar': 'إنشاء كود خصم جديد',
      'fr': 'Créer un nouveau code promo',
      'en': 'Create new promo code'
    },
    'no_promo_codes': {
      'ar': 'لا توجد أكواد خصم',
      'fr': 'Aucun code promo',
      'en': 'No promo codes'
    },
    'discount_amount_label': {
      'ar': 'الخصم:',
      'fr': 'Réduction :',
      'en': 'Discount:'
    },
    'validity_label': {
      'ar': 'الصلاحية:',
      'fr': 'Validité :',
      'en': 'Validity:'
    },
    'no_lost_items': {
      'ar': 'لا توجد بلاغات مفقودات حالياً 🎉',
      'fr': 'Aucun objet perdu signalé actuellement 🎉',
      'en': 'No lost items reported currently 🎉'
    },
    'lost_item_default': {
      'ar': 'غرض مفقود',
      'fr': 'Objet perdu',
      'en': 'Lost item'
    },
    'ride_label': {
      'ar': 'الرحلة:',
      'fr': 'Trajet :',
      'en': 'Ride:'
    },
    'no_open_disputes': {
      'ar': 'لا توجد نزاعات مفتوحة 🎉',
      'fr': 'Aucun litige ouvert 🎉',
      'en': 'No open disputes 🎉'
    },
    'financial_dispute_ride': {
      'ar': 'نزاع مالي - رحلة #',
      'fr': 'Litige financier - Trajet #',
      'en': 'Financial Dispute - Ride #'
    },
    'details_label': {
      'ar': 'التفاصيل:',
      'fr': 'Détails :',
      'en': 'Details:'
    },
    'edit_fares_title': {
      'ar': 'تعديل أسعار:',
      'fr': 'Modifier les tarifs :',
      'en': 'Edit fares:'
    },
    'base_fare_input': {
      'ar': 'رسوم الانطلاق (دج)',
      'fr': 'Frais de base (DZD)',
      'en': 'Base fare (DZD)'
    },
    'per_km_input': {
      'ar': 'سعر الكم (دج)',
      'fr': 'Tarif par km (DZD)',
      'en': 'Per km rate (DZD)'
    },
    'per_min_input': {
      'ar': 'سعر الدقيقة (دج)',
      'fr': 'Tarif par minute (DZD)',
      'en': 'Per minute rate (DZD)'
    },
    'min_fare_input': {
      'ar': 'الحد الأدنى (دج)',
      'fr': 'Tarif minimum (DZD)',
      'en': 'Minimum fare (DZD)'
    },
    'save_fares_btn': {
      'ar': 'حفظ',
      'fr': 'Enregistrer',
      'en': 'Save'
    },
    'document_updated': {
      'ar': 'تم تحديث المستند:',
      'fr': 'Document mis à jour :',
      'en': 'Document updated:'
    },
    'approved_success': {
      'ar': '✅ تمت الموافقة',
      'fr': '✅ Approuvé',
      'en': '✅ Approved'
    },
    'rejected_success': {
      'ar': '❌ تم الرفض',
      'fr': '❌ Rejeté',
      'en': '❌ Rejected'
    },
    'vehicle_updated': {
      'ar': 'تم تحديث السيارة:',
      'fr': 'Véhicule mis à jour :',
      'en': 'Vehicle updated:'
    },
    'complaint_updated': {
      'ar': 'تم تحديث الشكوى:',
      'fr': 'Plainte mise à jour :',
      'en': 'Complaint updated:'
    },
    'verification_updated': {
      'ar': 'تم تحديث التحقق:',
      'fr': 'Vérification mise à jour :',
      'en': 'Verification updated:'
    },
    'fares_saved_success': {
      'ar': '✅ تم حفظ الأسعار',
      'fr': '✅ Tarifs enregistrés',
      'en': '✅ Fares saved'
    },
    'notification_sent_success': {
      'ar': '✅ تم إرسال الإشعار',
      'fr': '✅ Notification envoyée',
      'en': '✅ Notification sent'
    },
    'ride_protected_evidence': {
      'ar': '🔒 هذه الرحلة محمية: الموقع مُسجل، المحادثات مؤرشفة، والعقد رقمي.',
      'fr': '🔒 Ce trajet est protégé : localisation enregistrée, discussions archivées, contrat numérique.',
      'en': '🔒 This ride is protected: location tracked, chats archived, and contract is digital.'
    },
    'terms_title': {
      'ar': 'الشروط والأحكام',
      'fr': 'Termes et conditions',
      'en': 'Terms and Conditions'
    },
    'terms_section_1_title': {
      'ar': '1. طبيعة المنصة',
      'fr': '1. Nature de la plateforme',
      'en': '1. Platform Nature'
    },
    'terms_section_1_desc': {
      'ar': 'Doraa هي منصتكِ الرقمية الموثوقة للتواصل بين السائقات والراكبات. نحن نوفر التقنية لتسهيل رحلاتكن، ولسنا جهة نقل رسمية أو مديرية.',
      'fr': 'Doraa est votre plateforme numérique de confiance. Nous fournissons la technologie pour faciliter vos trajets et ne sommes pas une direction de transport officielle.',
      'en': 'Doraa is your trusted digital platform. We provide the technology to facilitate your rides and are not an official transport directorate.'
    },
    'terms_section_2_title': {
      'ar': '2. المسؤولية',
      'fr': '2. Responsabilité',
      'en': '2. Responsibility'
    },
    'terms_section_2_desc': {
      'ar': 'أنتِ تستخدمين التطبيق على مسؤوليتك الشخصية. نحن نتحقق من الهوية والجنس لكننا لا نضمن سلوك أي مستخدمة. في حال وقوع حادث، التأمين على المركبة هو المسؤول الأول.',
      'fr': 'Vous utilisez l\'application à vos risques et périls. En cas d\'accident, l\'assurance du véhicule est la première responsable.',
      'en': 'You use the app at your own risk. In case of an accident, the vehicle insurance is the primary responsible party.'
    },
    'terms_section_3_title': {
      'ar': '3. زر SOS',
      'fr': '3. Bouton SOS',
      'en': '3. SOS Button'
    },
    'terms_section_3_desc': {
      'ar': 'زر SOS هو أداة مساعدة ولا يغني عن الاتصال بالطوارئ الرسمية (1548 / 17 / 14).',
      'fr': 'Le bouton SOS est un outil d\'assistance et ne remplace pas l\'appel aux urgences officielles (1548 / 17 / 14).',
      'en': 'The SOS button is an assistance tool and does not replace calling official emergencies (1548 / 17 / 14).'
    },
    'terms_section_4_title': {
      'ar': '4. البيانات',
      'fr': '4. Données',
      'en': '4. Data'
    },
    'terms_section_4_desc': {
      'ar': 'نحتفظ ببيانات الرحلات 90 يوماً، المحادثات 30 يوماً، والمستندات 1 سنة بعد حذف الحساب.',
      'fr': 'Nous conservons les données des trajets 90 jours, les discussions 30 jours, et les documents 1 an après suppression.',
      'en': 'We keep ride data for 90 days, chats for 30 days, and documents for 1 year after account deletion.'
    },
    'terms_section_5_title': {
      'ar': '5. العمر',
      'fr': '5. Âge',
      'en': '5. Age'
    },
    'terms_section_5_desc': {
      'ar': 'يجب أن يكون عمرك 18 سنة أو أكثر لاستخدام هذا التطبيق.',
      'fr': 'Vous devez avoir 18 ans ou plus pour utiliser cette application.',
      'en': 'You must be 18 years or older to use this app.'
    },
    'terms_agree_1': {
      'ar': 'أقر بأنني قرأت وفهمت شروط الاستخدام',
      'fr': 'Je certifie avoir lu et compris les conditions',
      'en': 'I acknowledge I have read and understood the terms'
    },
    'terms_agree_2': {
      'ar': 'أوافق على سياسة الخصوصية',
      'fr': 'J\'accepte la politique de confidentialité',
      'en': 'I agree to the privacy policy'
    },
    'terms_agree_3': {
      'ar': 'أوافق على سياسة السلامة',
      'fr': 'J\'accepte la politique de sécurité',
      'en': 'I agree to the safety policy'
    },
    'terms_accept_btn': {
      'ar': 'أوافق وأكمل',
      'fr': 'J\'accepte et je continue',
      'en': 'I Accept and Continue'
    },
    'terms_reject_btn': {
      'ar': 'لا أوافق — خروج',
      'fr': 'Je refuse — Quitter',
      'en': 'I Disagree — Exit'
    }
  };
}
