import 'package:flutter_test/flutter_test.dart';
import 'package:doraa/services/app_config.dart';
import 'package:doraa/services/validation_service.dart';
import 'package:doraa/services/ride_service.dart';

void main() {
  group('ValidationService Tests', () {
    test('Validates Algerian phone numbers correctly', () {
      expect(ValidationService.isValidAlgerianPhone('0550123456'), isTrue);
      expect(ValidationService.isValidAlgerianPhone('0660123456'), isTrue);
      expect(ValidationService.isValidAlgerianPhone('0770123456'), isTrue);
      expect(ValidationService.isValidAlgerianPhone('+213550123456'), isTrue);
      expect(ValidationService.isValidAlgerianPhone('12345'), isFalse);
    });

    test('Validates Email addresses correctly', () {
      expect(ValidationService.isValidEmail('user@doraa.com'), isTrue);
      expect(ValidationService.isValidEmail('invalid-email'), isFalse);
    });

    test('Validates passwords correctly', () {
      expect(ValidationService.isValidPassword('Password123'), isTrue);
      expect(ValidationService.isValidPassword('weak'), isFalse);
    });
  });

  group('AppConfig & RideService Tests', () {
    test('Check AppConfig Supabase configuration', () {
      expect(AppConfig.isSupabaseConfigured, isTrue);
      expect(AppConfig.supabaseUrl, isNotEmpty);
      expect(AppConfig.effectiveSupabaseKey, isNotEmpty);
    });

    test('Calculate suggested fare correctly', () {
      final fare = RideService.calculateSuggestedFare(
        distanceKm: 10.0,
        durationMinutes: 15,
      );
      expect(fare, greaterThan(0));
    });
  });
}
