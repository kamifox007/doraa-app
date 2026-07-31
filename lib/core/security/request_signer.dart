import 'dart:convert';
import 'package:crypto/crypto.dart';

class RequestSigner {
  static String sign(String endpoint, Map<String, dynamic> body, String secret) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$endpoint:${jsonEncode(body)}:$timestamp';
    final hmac = Hmac(sha256, utf8.encode(secret));
    return base64Encode(hmac.convert(utf8.encode(payload)).bytes);
  }
}
