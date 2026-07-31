class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    // ── Common ──
    'dora_app': {
      'ar': 'تطبيق DORA',
      'fr': 'Application DORA',
      'en': 'DORA App',
    },
    'currency': {
      'ar': 'دج',
      'fr': 'DZD',
      'en': 'DZD',
    },
    'cancel': {
      'ar': 'إلغاء',
      'fr': 'Annuler',
      'en': 'Cancel',
    },
    'save_changes': {
      'ar': 'حفظ التغييرات',
      'fr': 'Enregistrer les modifications',
      'en': 'Save Changes',
    },
    'logout': {
      'ar': 'تسجيل الخروج',
      'fr': 'Déconnexion',
      'en': 'Logout',
    },

    // ── Profile Screen ──
    'profile_title': {
      'ar': 'ملفي الشخصي',
      'fr': 'Mon Profil',
      'en': 'My Profile',
    },
    'dora_user': {
      'ar': 'مستخدمة DORA',
      'fr': 'Utilisatrice DORA',
      'en': 'DORA User',
    },
    'my_info': {
      'ar': 'معلوماتي',
      'fr': 'Mes Informations',
      'en': 'My Information',
    },
    'full_name': {
      'ar': 'الاسم الكامل',
      'fr': 'Nom Complet',
      'en': 'Full Name',
    },
    'phone_number': {
      'ar': 'رقم الهاتف',
      'fr': 'Numéro de Téléphone',
      'en': 'Phone Number',
    },
    'wallet_sub_title': {
      'ar': 'محفظتي واشتراكي',
      'fr': 'Mon Portefeuille et Abonnement',
      'en': 'My Wallet & Subscription',
    },
    'wallet_sub_desc': {
      'ar': 'اشتراك شهري، رصيد المحفظة، العمولات',
      'fr': 'Abonnement mensuel, solde du portefeuille, commissions',
      'en': 'Monthly subscription, wallet balance, commissions',
    },
    'admin_dashboard_title': {
      'ar': 'لوحة تحكم الإدارة',
      'fr': 'Tableau de Bord Admin',
      'en': 'Admin Dashboard',
    },
    'admin_dashboard_desc': {
      'ar': 'إدارة السائقات والطلبات',
      'fr': 'Gérer les conductrices et les requêtes',
      'en': 'Manage drivers and requests',
    },
    'become_driver_title': {
      'ar': 'كوني سائقة وانطلقي معنا 🚗',
      'fr': 'Devenez Conductrice avec nous 🚗',
      'en': 'Become a Driver with us 🚗',
    },
    'become_driver_desc': {
      'ar': 'سجلي كسائقة وابدئي في تحقيق الأرباح',
      'fr': 'Inscrivez-vous en tant que conductrice et commencez à gagner',
      'en': 'Sign up as a driver and start earning',
    },
    'become_driver_dialog_title': {
      'ar': '🚗 كوني سائقة مع DORA',
      'fr': '🚗 Devenez Conductrice avec DORA',
      'en': '🚗 Become a Driver with DORA',
    },
    'become_driver_dialog_content': {
      'ar': 'للتسجيل كسائقة، سيتم تسجيل خروجك من حساب الراكبة الحالي لتتمكني من إنشاء حساب جديد مخصص للسائقات ورفع أوراقك الثبوتية.\n\nهل أنت مستعدة للانطلاق؟',
      'fr': 'Pour vous inscrire comme conductrice, vous serez déconnectée de votre compte actuelle afin de créer un nouveau compte dédié aux conductrices et télécharger vos documents.\n\nÊtes-vous prête ?',
      'en': 'To register as a driver, you will be logged out of your current rider account to create a new dedicated driver account and upload your documents.\n\nAre you ready?',
    },
    'yes_logout_start': {
      'ar': 'نعم، تسجيل خروج والبدء',
      'fr': 'Oui, me déconnecter et commencer',
      'en': 'Yes, log out and start',
    },
    'change_language': {
      'ar': 'تغيير اللغة',
      'fr': 'Changer la Langue',
      'en': 'Change Language',
    },
    'choose_language': {
      'ar': 'اختر اللغة',
      'fr': 'Choisissez la langue',
      'en': 'Choose Language',
    },
  };

  static String get(String key, String locale) {
    if (translations.containsKey(key)) {
      return translations[key]![locale] ?? translations[key]!['ar'] ?? key;
    }
    return key;
  }
}

extension TranslationHelper on String {
  String tr(String locale) {
    return AppTranslations.get(this, locale);
  }
}
