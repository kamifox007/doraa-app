import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// تحقق مما إذا كان الإصدار الحالي مدعوماً
  static Future<void> checkAppVersion(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // استخراج الحد الأدنى من الإصدار المطلوب من قاعدة البيانات
      final response = await _client
          .from('app_settings')
          .select('min_build_number, store_url')
          .single();

      final minBuildNumber = response['min_build_number'] as int? ?? 0;
      final storeUrl = response['store_url'] as String? ?? '';

      if (buildNumber < minBuildNumber) {
        if (!context.mounted) return;
        _showForceUpdateDialog(context, storeUrl);
      }
    } catch (e) {
      // تجاهل الخطأ للسماح بالدخول في حال عدم التمكن من جلب البيانات
      debugPrint('VersionService: $e');
    }
  }

  static void _showForceUpdateDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false, // لا يمكن إغلاقه
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('تحديث ضروري! ⚠️'),
          content: const Text(
            'لقد أطلقنا تحديثاً جديداً يتضمن ميزات أمان هامة.\n'
            'يرجى التحديث لمتابعة استخدام التطبيق.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('تحديث الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
