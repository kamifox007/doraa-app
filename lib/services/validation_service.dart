class ValidationService {
  static List<String> getAlgerianWilayas() {
    return [
      '1 - أدرار',
      '2 - الشلف',
      '3 - الأغواط',
      '4 - أم البواقي',
      '5 - باتنة',
      '6 - بجاية',
      '7 - بسكرة',
      '8 - بشار',
      '9 - البليدة',
      '10 - البويرة',
      '11 - تمنراست',
      '12 - تبسة',
      '13 - تلمسان',
      '14 - تيارت',
      '15 - تيزي وزو',
      '16 - الجزائر',
      '17 - الجلفة',
      '18 - جيجل',
      '19 - سطيف',
      '20 - سعيدة',
      '21 - سكيكدة',
      '22 - سيدي بلعباس',
      '23 - عنابة',
      '24 - قالمة',
      '25 - قسنطينة',
      '26 - المدية',
      '27 - المسيلة',
      '28 - معسكر',
      '29 - ورقلة',
      '30 - وهران',
      '31 - البيض',
      '32 - إليزي',
      '33 - برج بوعريريج',
      '34 - بومرداس',
      '35 - الطارف',
      '36 - تندوف',
      '37 - تيسمسيلت',
      '38 - الوادي',
      '39 - خنشلة',
      '40 - سوق أهراس',
      '41 - تيبازة',
      '42 - ميلة',
      '43 - عين الدفلى',
      '44 - النعامة',
      '45 - عين تموشنت',
      '46 - غرداية',
      '47 - غليزان',
      '48 - تيميمون',
      '49 - برج باجي مختار',
      '50 - أولاد جلال',
      '51 - بني عباس',
      '52 - إن صالح',
      '53 - إن قزام',
      '54 - تقرت',
      '55 - المغير',
      '56 - المنيعة',
      '57 - الأغواط الجديدة',
      '58 - المنيعة الجديدة',
    ];
  }

  static bool isValidAlgerianPhone(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.startsWith('05') || normalized.startsWith('06') || normalized.startsWith('07')) {
      return normalized.length == 10 && RegExp(r'^0(5|6|7)\d{8}$').hasMatch(normalized);
    }
    if (normalized.startsWith('+213')) {
      return normalized.length == 13 && RegExp(r'^\+213(5|6|7)\d{8}$').hasMatch(normalized);
    }
    if (normalized.startsWith('213')) {
      return normalized.length == 12 && RegExp(r'^213(5|6|7)\d{8}$').hasMatch(normalized);
    }
    return false;
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
