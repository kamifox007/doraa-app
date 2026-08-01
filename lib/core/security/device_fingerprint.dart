import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceFingerprint {
  static Future<String> generate() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      final components = [
        webInfo.userAgent ?? '',
        webInfo.platform ?? '',
        webInfo.appName ?? '',
        webInfo.appVersion ?? '',
      ];
      final raw = components.join('|');
      return sha256.convert(utf8.encode(raw)).toString();
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      final components = [
        androidInfo.id,
        androidInfo.model,
        androidInfo.brand,
        androidInfo.hardware,
        androidInfo.fingerprint,
        androidInfo.manufacturer,
        androidInfo.product,
      ];
      final raw = components.join('|');
      return sha256.convert(utf8.encode(raw)).toString();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final components = [
        iosInfo.identifierForVendor ?? '',
        iosInfo.model,
        iosInfo.systemName,
        iosInfo.systemVersion,
      ];
      final raw = components.join('|');
      return sha256.convert(utf8.encode(raw)).toString();
    }
    
    return 'unsupported_platform';
  }
}
