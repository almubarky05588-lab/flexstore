/// تُمرَّر عبر --dart-define أثناء البناء، فلا تُخزَّن الأسرار في الكود.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'مفقود: SUPABASE_URL أو SUPABASE_ANON_KEY. '
        'شغّل التطبيق مع --dart-define لكل منهما.',
      );
    }
  }
}
