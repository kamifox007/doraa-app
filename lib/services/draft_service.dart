import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة حفظ المسودات (Draft Service)
/// تقوم بحفظ البيانات المدخلة في النماذج محلياً لاستعادتها عند العودة أو عند إغلاق التطبيق فجأة.
class DraftService {
  static const String _draftPrefix = 'draft_';

  /// حفظ البيانات كمسودة
  /// [formKey] معرف النموذج (مثلاً: 'support_form', 'driver_vehicle_form')
  /// [data] البيانات المراد حفظها (نصوص، اختيارات)
  static Future<void> saveDraft(String formKey, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data);
    await prefs.setString('$_draftPrefix$formKey', jsonString);
  }

  /// استرجاع بيانات المسودة
  /// يعود بـ null إذا لم تكن هناك مسودة سابقة
  static Future<Map<String, dynamic>?> loadDraft(String formKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_draftPrefix$formKey');
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// مسح المسودة (يُستدعى بعد الإرسال الناجح للنموذج)
  static Future<void> clearDraft(String formKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftPrefix$formKey');
  }
}
