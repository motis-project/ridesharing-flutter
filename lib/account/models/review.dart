import 'package:flutter_app/account/models/profile.dart';

import '../../util/model.dart';

class Review extends Model {
  int stars;
  int comfortStars;
  int safetyStars;
  int reliabilityStars;
  int hospitalityStars;
  String text;

  int writerId;
  Profile? writer;

  int receiverId;
  Profile? receiver;

  Review({
    super.id,
    super.createdAt,
    required this.stars,
    required this.comfortStars,
    required this.safetyStars,
    required this.reliabilityStars,
    required this.hospitalityStars,
    required this.text,
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
