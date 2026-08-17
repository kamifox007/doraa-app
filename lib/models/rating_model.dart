class RatingModel {
  final String id;
  final String rideId;
  final String reviewerId;
  final String revieweeId;
  final int score;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.rideId,
    required this.reviewerId,
    required this.revieweeId,
    required this.score,
    this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      revieweeId: json['reviewee_id'] as String,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'ride_id': rideId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'score': score,
      'comment': comment,
      'tags': tags,
    };
  }
}
