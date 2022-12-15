import 'package:flutter_app/account/models/profile.dart';

import '../../util/model.dart';

class Review extends Model {
  int rating;
  int? comfortRating;
  int? safetyRating;
  int? reliabilityRating;
  int? hospitalityRating;
  String? text;

  int writerId;
  Profile? writer;

  int receiverId;
  Profile? receiver;

  Review({
    super.id,
    super.createdAt,
    required this.rating,
    this.comfortRating,
    this.safetyRating,
    this.reliabilityRating,
    this.hospitalityRating,
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
      rating: json['rating'],
      comfortRating: json['comfort_rating'],
      safetyRating: json['safety_rating'],
      reliabilityRating: json['reliability_rating'],
      hospitalityRating: json['hospitality_rating'],
      text: json['text'],
      writerId: json['writer_id'],
      receiverId: json['receiver_id'],
      writer: json.containsKey('writer') ? Profile.fromJson(json['writer']) : null,
    );
  }

  static List<Review> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => Review.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comfort_rating': comfortRating,
      'safety_rating': safetyRating,
      'reliability_rating': reliabilityRating,
      'hospitality_rating': hospitalityRating,
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
    return 'Review{id: $id, rating: $rating, text: $text, writerId: $writerId, receiverId: $receiverId, createdAt: $createdAt}';
  }
}

class AggregateReview {
  double rating;
  double comfortRating;
  double safetyRating;
  double reliabilityRating;
  double hospitalityRating;

  AggregateReview({
    required this.rating,
    required this.comfortRating,
    required this.safetyRating,
    required this.reliabilityRating,
    required this.hospitalityRating,
  });

  factory AggregateReview.fromReviews(List<Review> reviews) {
    double rating =
        reviews.isEmpty ? 0 : reviews.map((review) => review.rating).reduce((a, b) => a + b) / reviews.length;

    List<Review> comfortReviews = reviews.where((review) => review.comfortRating != null).toList();
    double comfortRating = comfortReviews.isEmpty
        ? 0
        : comfortReviews.map((review) => review.comfortRating!).reduce((a, b) => a + b) / comfortReviews.length;

    List<Review> safetyReviews = reviews.where((review) => review.safetyRating != null).toList();
    double safetyRating = safetyReviews.isEmpty
        ? 0
        : safetyReviews.map((review) => review.safetyRating!).reduce((a, b) => a + b) / safetyReviews.length;

    List<Review> reliabilityReviews = reviews.where((review) => review.reliabilityRating != null).toList();
    double reliabilityRating = reliabilityReviews.isEmpty
        ? 0
        : reliabilityReviews.map((review) => review.reliabilityRating!).reduce((a, b) => a + b) /
            reliabilityReviews.length;

    List<Review> hospitalityReviews = reviews.where((review) => review.hospitalityRating != null).toList();
    double averageRating = hospitalityReviews.isEmpty
        ? 0
        : hospitalityReviews.map((review) => review.hospitalityRating!).reduce((a, b) => a + b) /
            hospitalityReviews.length;

    return AggregateReview(
      rating: rating,
      comfortRating: comfortRating,
      safetyRating: safetyRating,
      reliabilityRating: reliabilityRating,
      hospitalityRating: averageRating,
    );
  }
}
