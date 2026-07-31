import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecurityCheck {
  static Future<bool> isDeviceSecure() async {
    return true;
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
