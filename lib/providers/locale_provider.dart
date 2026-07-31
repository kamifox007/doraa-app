import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  // الافتراضي هو اللغة العربية
  LocaleNotifier() : super('ar');

  void setLocale(String languageCode) {
    if (['ar', 'fr', 'en'].contains(languageCode)) {
      state = languageCode;
    }
  }

  bool get isRtl => state == 'ar';
}
