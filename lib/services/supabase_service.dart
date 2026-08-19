import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!AppConfig.isSupabaseConfigured) {
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.effectiveSupabaseKey,
    );
  }

  static Future<Map<String, dynamic>?> getHealth() async {
    if (!AppConfig.isSupabaseConfigured) {
      return null;
    }

    try {
      final response = await client.from('fare_settings').select().limit(1);
      return {'status': 'ok', 'count': response.length};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<void> createRating({
    required String rideId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? comment,
    required bool isDriverRating,
  }) async {
    await client.from('ratings').insert({
      'ride_id': rideId,
      'reviewer_id': reviewerId,
      'reviewed_id': revieweeId,
      'rating': rating,
      'comment': comment,
      'is_driver_rating': isDriverRating,
    });
  }

  Future<void> createCommission({
    required String rideId,
    required String driverId,
    required double fare,
    required double commissionRate,
  }) async {
    final commissionAmount = fare * commissionRate;
    final netEarnings = fare - commissionAmount;
    await client.from('commissions').insert({
      'ride_id': rideId,
      'driver_id': driverId,
      'fare': fare,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'net_earnings': netEarnings,
      'status': 'pending',
    });
  }

  Future<void> updateProfileTotals({
    required String userId,
    required String role,
    required int completedRides,
    double? averageRating,
  }) async {
    final table = role == 'driver' ? 'driver_profiles' : 'rider_profiles';
    final additionalRating = averageRating == null ? null : {'average_rating': averageRating};
    final data = <String, dynamic>{
      'user_id': userId,
      'total_rides': completedRides,
      ...?additionalRating,
    };
    await client.from(table).upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchAvailableRideRequests() async {
    final response = await client.from('rides').select().eq('status', 'searching');
    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchDriverTrips(String driverId) async {
    final response = await client.from('rides').select().eq('driver_id', driverId).eq('status', 'completed');
    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }
}
