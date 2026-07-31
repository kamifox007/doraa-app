import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'sawari_nisa_secure',
    ),
  );

  static Future<void> write(String key, String value) => 
    _storage.write(key: key, value: value);

  static Future<String?> read(String key) => 
    _storage.read(key: key);

  static Future<void> delete(String key) => 
    _storage.delete(key: key);

  static Future<void> clear() => 
    _storage.deleteAll();
}
