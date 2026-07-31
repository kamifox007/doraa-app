import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class ScreenProtection {
  static Future<void> enable() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  static Future<void> disable() async {
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }
}
