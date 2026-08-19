class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zszqfbiomkfevkmtnoho.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_7IryTLEVdY4SF6OULonCLA_lP1UNX_O',
  );

  static String get effectiveSupabaseKey {
    if (supabasePublishableKey.isNotEmpty) {
      return supabasePublishableKey;
    }
    return supabaseAnonKey;
  }

  static const String stitchBaseUrl = String.fromEnvironment(
    'STITCH_BASE_URL',
    defaultValue: 'https://example.com/stitch',
  );

  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        effectiveSupabaseKey.isNotEmpty &&
        !supabaseUrl.contains('your-project') &&
        !effectiveSupabaseKey.contains('your-anon-key');
  }

  static bool get isStitchConfigured {
    return stitchBaseUrl.startsWith('http') &&
        !stitchBaseUrl.contains('example') &&
        !stitchBaseUrl.contains('your-stitch');
  }
}
