import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class StitchService {
  static Future<Map<String, dynamic>> ping() async {
    if (!AppConfig.isStitchConfigured) {
      return {'status': 'pending'};
    }

    try {
      final response = await http.get(
        Uri.parse(AppConfig.stitchBaseUrl),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        return {'status': 'ok', 'body': body};
      }

      return {'status': 'error', 'code': response.statusCode};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
