import '../../account/models/profile.dart';
import '../../model.dart';

class Review extends Model implements Comparable<Review> {
  static const int maxRating = 5;

  DateTime? updatedAt;

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
    this.updatedAt,
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
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
      rating: json['rating'] as int,
      comfortRating: json['comfort_rating'] as int?,
      safetyRating: json['safety_rating'] as int?,
      reliabilityRating: json['reliability_rating'] as int?,
      hospitalityRating: json['hospitality_rating'] as int?,
      text: json['text'] as String?,
      writerId: json['writer_id'] as int,
      writer: json.containsKey('writer') ? Profile.fromJson(json['writer'] as Map<String, dynamic>) : null,
      receiverId: json['receiver_id'] as int,
      receiver: json.containsKey('receiver') ? Profile.fromJson(json['receiver'] as Map<String, dynamic>) : null,
    );
  }

  static List<Review> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Review.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'updated_at': updatedAt?.toIso8601String(),
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

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        'writer': writer?.toJsonForApi(),
        'receiver': receiver?.toJsonForApi(),
      });
  }

  /// Returns true if the review has been changed from [other].
  bool isChangedFrom(Review other) {
    return rating != other.rating ||
        comfortRating != other.comfortRating ||
        safetyRating != other.safetyRating ||
        reliabilityRating != other.reliabilityRating ||
        hospitalityRating != other.hospitalityRating ||
        text != other.text;
  }

  Review copyWith() {
    return Review(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rating: rating,
      comfortRating: comfortRating,
      safetyRating: safetyRating,
      reliabilityRating: reliabilityRating,
      hospitalityRating: hospitalityRating,
      text: text,
      writerId: writerId,
      writer: writer,
      receiverId: receiverId,
      receiver: receiver,
    );
  }

  /// Returns a -1 if this review is "more relevant" than [other], i.e. it has text and [other] doesn't OR it was created more recently.
  /// Returns a 1 if this review is "less relevant" than [other], i.e. it doesn't have text and [other] does OR it was created less recently.
  @override
  int compareTo(Review other) {
    final bool thisHasText = text?.isNotEmpty ?? false;
    final bool otherHasText = other.text?.isNotEmpty ?? false;
    if (thisHasText && !otherHasText) {
      return -1;
    } else if (!thisHasText && otherHasText) {
      return 1;
    } else {
      return other.createdAt!.compareTo(createdAt!);
    }
  }

  @override
  String toString() {
    return 'Review{id: $id, rating: $rating, text: $text, writerId: $writerId, receiverId: $receiverId, updatedAt: $updatedAt}';
  }
}

class AggregateReview {
  double rating;
  double comfortRating;
  double safetyRating;
  double reliabilityRating;
  double hospitalityRating;

  int numberOfReviews;

  AggregateReview({
    required this.rating,
    required this.comfortRating,
    required this.safetyRating,
    required this.reliabilityRating,
    required this.hospitalityRating,
    required this.numberOfReviews,
  });

  /// Returns true if the overall rating has been changed, i.e. is not 0.
  bool get isRatingSet => rating != 0;

  /// Returns true if the comfort rating has been changed, i.e. is not 0.
  bool get isComfortSet => comfortRating != 0;

  /// Returns true if the safety rating has been changed, i.e. is not 0.
  bool get isSafetySet => safetyRating != 0;

  /// Returns true if the reliability rating has been changed, i.e. is not 0.
  bool get isReliabilitySet => reliabilityRating != 0;

  /// Returns true if the hospitality rating has been changed, i.e. is not 0.
  bool get isHospitalitySet => hospitalityRating != 0;

  /// Builds an [AggregateReview] from a list of [Review]s.
  ///
  /// Every rating is the average of all the reviews that have a rating for that category.
  factory AggregateReview.fromReviews(List<Review> reviews) {
    final double rating = reviews.isEmpty
        ? 0
        : reviews.map((Review review) => review.rating).reduce((int a, int b) => a + b) / reviews.length;

    final List<Review> comfortReviews = reviews.where((Review review) => review.comfortRating != null).toList();
    final double comfortRating = comfortReviews.isEmpty
        ? 0
        : comfortReviews.map((Review review) => review.comfortRating!).reduce((int a, int b) => a + b) /
            comfortReviews.length;

    final List<Review> safetyReviews = reviews.where((Review review) => review.safetyRating != null).toList();
    final double safetyRating = safetyReviews.isEmpty
        ? 0
        : safetyReviews.map((Review review) => review.safetyRating!).reduce((int a, int b) => a + b) /
            safetyReviews.length;

    final List<Review> reliabilityReviews = reviews.where((Review review) => review.reliabilityRating != null).toList();
    final double reliabilityRating = reliabilityReviews.isEmpty
        ? 0
        : reliabilityReviews.map((Review review) => review.reliabilityRating!).reduce((int a, int b) => a + b) /
            reliabilityReviews.length;

    final List<Review> hospitalityReviews = reviews.where((Review review) => review.hospitalityRating != null).toList();
    final double averageRating = hospitalityReviews.isEmpty
        ? 0
        : hospitalityReviews.map((Review review) => review.hospitalityRating!).reduce((int a, int b) => a + b) /
            hospitalityReviews.length;

    return AggregateReview(
      rating: rating,
      comfortRating: comfortRating,
      safetyRating: safetyRating,
      reliabilityRating: reliabilityRating,
      hospitalityRating: averageRating,
      numberOfReviews: reviews.length,
    );
  }
}
