import 'package:flutter/services.dart';

class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void vibrate() => HapticFeedback.vibrate();

  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), HapticFeedback.lightImpact);
  }

  static void error() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), HapticFeedback.heavyImpact);
  }
}
