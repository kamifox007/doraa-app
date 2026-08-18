import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating_model.dart';

final ratingServiceProvider = Provider((ref) => RatingService());

class RatingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit a new rating
  Future<void> submitRating(RatingModel rating) async {
    try {
      await _supabase.from('ratings').insert(rating.toJson());
    } catch (e) {
      // In a real app, handle offline queuing or specific errors
      debugPrint('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Get average rating for a user (driver or rider)
  Future<double> getAverageRating(String userId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('score')
          .eq('reviewee_id', userId);

      if (response.isEmpty) return 5.0; // Default if no ratings

      int total = 0;
      for (var row in response) {
        total += (row['score'] as int);
      }
      return total / response.length;
    } catch (e) {
      debugPrint('Error fetching average rating: $e');
      return 5.0;
    }
  }

  /// Get recent reviews for a user
  Future<List<RatingModel>> getRecentReviews(String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => RatingModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching recent reviews: $e');
      return [];
    }
  }
}
