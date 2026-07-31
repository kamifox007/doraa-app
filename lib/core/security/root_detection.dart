import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class SecurityCheck {
  static Future<bool> isDeviceSecure() async {
    if (kIsWeb) return true; // Web is always considered secure from root/jailbreak perspective
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      final developerMode = await FlutterJailbreakDetection.developerMode;
      return !jailbroken && !developerMode;
    } catch (e) {
      return false;
    }
  }

  static void showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ جهاز غير آمن'),
        content: const Text(
          'تم اكتشاف تعديل على النظام (Root/Jailbreak).\n'
          'لا يمكن استخدام التطبيق لأسباب أمنية.',
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}
