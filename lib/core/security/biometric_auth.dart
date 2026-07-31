import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  static final _localAuth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    return await _localAuth.canCheckBiometrics && 
           await _localAuth.isDeviceSupported();
  }

  static Future<bool> authenticate({String reason = 'يرجى التحقق من هويتك'}) async {
    return await _localAuth.authenticate(
      localizedReason: reason,
    );
  }
}
