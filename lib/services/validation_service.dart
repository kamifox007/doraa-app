class ValidationService {
  static List<String> getAlgerianWilayas() {
    return [
      'أدرار',
      'الأغواط',
      'ام البواقي',
      'باتنة',
      'بجاية',
      'بسكرة',
      'بشار',
      'البليدة',
      'البويرة',
      'تمنراست',
      'تبسة',
      'تلمسان',
      'تيارت',
      'تيزي وزو',
      'الجزائر',
      'الجلفة',
      'جيجل',
      'سطيف',
      'سعيدة',
      'سكيكدة',
      'سيدي بلعباس',
      'عنابة',
      'قالمة',
      'قسنطينة',
      'المدية',
      'المسيلة',
      'معسكر',
      'ورقلة',
      'وهران',
      'البيض',
      'إليزي',
      'برج بوعريريج',
      'بومرداس',
      'الطارف',
      'تندوف',
      'تيسمسيلت',
      'الوادي',
      'خنشلة',
      'سوق أهراس',
      'تيبازة',
      'ميلة',
      'عين الدفلى',
      'النعامة',
      'عين تيموشنت',
      'غرداية',
      'غليزان',
      'الشرقية',
      'المغير',
      'المنيعة',
      'أم البواقي',
      'برج باجي مختار',
      'أولاد جلال',
      'بني عباس',
      'إن صالح',
      'إن غزافر',
      'تقرت',
      'المغير',
      'المنيعة',
      'تسوق',
    ];
  }

  static bool isValidAlgerianPhone(String value) {
    final normalized = value.trim();
    return RegExp(r'^\+213(5|6|7)\d{8}$').hasMatch(normalized);
  }

  static bool isValidEmail(String value) {
    final normalized = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
  }

  static bool isValidPassword(String value) {
    return value.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'\d').hasMatch(value);
  }

  static bool isValidName(String value) {
    final normalized = value.trim();
    return normalized.isNotEmpty &&
        RegExp(r"^[A-Za-z\u0600-\u06FF\u00C0-\u024F\s]+$").hasMatch(normalized);
  }

  static bool isValidWilaya(String value) {
    return getAlgerianWilayas().contains(value);
  }

  static bool hasValidEmergencyContact(List<dynamic> contacts) {
    if (contacts.isEmpty) return false;

    return contacts.any((contact) {
      if (contact == null) return false;

      if (contact is Map) {
        final name = contact['name']?.toString() ?? contact['contact_name']?.toString();
        final phone = contact['phone']?.toString() ?? contact['contact_phone']?.toString();
        return (name ?? '').trim().isNotEmpty && (phone ?? '').trim().isNotEmpty;
      }

      try {
        final name = contact.name?.toString();
        final phone = contact.phone?.toString();
        return (name ?? '').trim().isNotEmpty && (phone ?? '').trim().isNotEmpty;
      } catch (_) {
        return false;
      }
    });
  }
}
