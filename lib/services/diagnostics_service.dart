import 'dart:io';
import 'package:flutter/material.dart';

/// نظام التشخيص الذكي للأخطاء
class DiagnosticsService {
  /// مفتاح التنقل العام للوصول إلى الواجهة من أي مكان في الكود دون الحاجة لـ BuildContext
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// تصنيف وتحليل الخطأ ثم عرض التنبيه المناسب
  static void reportError(dynamic exception, StackTrace stackTrace, {bool isFlutterError = false}) {
    debugPrint('🛑 [DiagnosticsService] Error Caught: $exception');
    
    // 1. تحليل سبب المشكلة (Diagnostics Algorithm)
    String errorCategory = 'خطأ غير متوقع';
    String userMessage = 'عذراً، حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    IconData icon = Icons.error_outline;
    Color color = Colors.red;

    final errorString = exception.toString().toLowerCase();

    // فحص مشاكل الهاتف / المستخدم (Network/Location)
    if (exception is SocketException || errorString.contains('socketexception') || errorString.contains('network') || errorString.contains('failed host lookup')) {
      errorCategory = 'مشكلة في الاتصال (هاتف)';
      userMessage = 'تأكد من اتصال هاتفك بالإنترنت (Wi-Fi أو بيانات الجوال) ثم حاول مجدداً.';
      icon = Icons.wifi_off_rounded;
      color = Colors.orange;
    } 
    // فحص مشاكل الخادم / قواعد البيانات (Server)
    // منع ظهور كلمة Supabase أو Postgrest للمستخدم أبداً
    else if (errorString.contains('postgrest') || errorString.contains('supabase') || errorString.contains('500') || errorString.contains('timeout')) {
      errorCategory = 'خلل في الاتصال بالخادم';
      userMessage = 'عذراً، الخادم يواجه ضغطاً أو مشكلة مؤقتة. نحن نعمل على حلها حالاً.';
      icon = Icons.cloud_off_rounded;
      color = Colors.blueGrey;
    }
    // فحص الأخطاء البرمجية المباشرة (App Bug)
    else if (exception is TypeError || exception is NoSuchMethodError || errorString.contains('null')) {
      errorCategory = 'خلل في عمل التطبيق';
      userMessage = 'عذراً، واجه التطبيق مشكلة غير متوقعة. يرجى إغلاق التطبيق وفتحه من جديد.';
      icon = Icons.bug_report_rounded;
      color = Colors.redAccent;
    }

    // 2. إظهار الإشعار للمستخدم
    _showErrorOverlay(errorCategory, userMessage, icon, color);
  }

  static void _showErrorOverlay(String title, String message, IconData icon, Color color) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // التأكد من عدم عرض حوارات كثيرة في نفس الوقت
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
