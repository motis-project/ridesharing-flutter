import 'package:flutter_app/account/models/profile.dart';

import '../../util/model.dart';

class Review extends Model {
  int stars;
  int? comfortStars;
  int? safetyStars;
  int? reliabilityStars;
  int? hospitalityStars;
  String? text;

  int writerId;
  Profile? writer;

  int receiverId;
  Profile? receiver;

  Review({
    super.id,
    super.createdAt,
    required this.stars,
    this.comfortStars,
    this.safetyStars,
    this.reliabilityStars,
    this.hospitalityStars,
    this.text,
    required this.writerId,
    this.writer,
    required this.receiverId,
    this.receiver,
  });

  @override
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      stars: json['stars'],
      comfortStars: json['comfort_stars'],
      safetyStars: json['safety_stars'],
      reliabilityStars: json['reliability_stars'],
      hospitalityStars: json['hospitality_stars'],
      text: json['text'],
      writerId: json['writer_id'],
      receiverId: json['receiver_id'],
    );
  }

  static List<Review> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => Review.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'stars': stars,
      'comfort_stars': comfortStars,
      'safety_stars': safetyStars,
      'reliability_stars': reliabilityStars,
      'hospitality_stars': hospitalityStars,
      'text': text,
      'writer_id': writerId,
      'receiver_id': receiverId
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Review> reviews) {
    return reviews.map((review) => review.toJson()).toList();
  }

  @override
  String toString() {
    return 'Review{id: $id, stars: $stars, text: $text, writerId: $writerId, receiverId: $receiverId, createdAt: $createdAt}';
  }
}

class AggregateReview {
  double stars;
  double comfortStars;
  double safetyStars;
  double reliabilityStars;
  double hospitalityStars;

  AggregateReview({
    required this.stars,
    required this.comfortStars,
    required this.safetyStars,
    required this.reliabilityStars,
    required this.hospitalityStars,
  });

  factory AggregateReview.fromReviews(List<Review> reviews) {
    double stars = reviews.isEmpty ? 0 : reviews.map((review) => review.stars).reduce((a, b) => a + b) / reviews.length;

    List<Review> comfortReviews = reviews.where((review) => review.comfortStars != null).toList();
    double comfortStars = comfortReviews.isEmpty
        ? 0
        : comfortReviews.map((review) => review.comfortStars!).reduce((a, b) => a + b) / comfortReviews.length;

    List<Review> safetyReviews = reviews.where((review) => review.safetyStars != null).toList();
    double safetyStars = safetyReviews.isEmpty
        ? 0
        : safetyReviews.map((review) => review.safetyStars!).reduce((a, b) => a + b) / safetyReviews.length;

    List<Review> reliabilityReviews = reviews.where((review) => review.reliabilityStars != null).toList();
    double reliabilityStars = reliabilityReviews.isEmpty
        ? 0
        : reliabilityReviews.map((review) => review.reliabilityStars!).reduce((a, b) => a + b) /
            reliabilityReviews.length;

    List<Review> hospitalityReviews = reviews.where((review) => review.hospitalityStars != null).toList();
    double averageStars = hospitalityReviews.isEmpty
        ? 0
        : hospitalityReviews.map((review) => review.hospitalityStars!).reduce((a, b) => a + b) /
            hospitalityReviews.length;

    return AggregateReview(
      stars: stars,
      comfortStars: comfortStars,
      safetyStars: safetyStars,
      reliabilityStars: reliabilityStars,
      hospitalityStars: averageStars,
    );
  }
}
