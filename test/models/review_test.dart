import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';

import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/review_factory.dart';

void main() {
  group('Review.fromJson', () {
    test('parses Review from json', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'writer_id': 1,
        'receiver_id': 1,
        'rating': 5,
        'comment': 'This is a comment',
      };
      final Review review = Review.fromJson(json);
      expect(review.id, 1);
      expect(review.createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(review.writerId, 1);
      expect(review.receiverId, 1);
      expect(review.rating, 5);
    });

    test('can handle Profile', () {
      final Profile writer = ProfileFactory().generateFake();
      final Profile receiver = ProfileFactory().generateFake();
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'writer_id': writer.id,
        'receiver_id': writer.id,
        'rating': 5,
        'comment': 'This is a comment',
        'writer': writer.toJsonForApi(),
        'receiver': receiver.toJsonForApi(),
      };
      final Review review = Review.fromJson(json);
      expect(review.writer.toString(), writer.toString());
      expect(review.receiver.toString(), receiver.toString());
    });

    test('can handle non required values', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'writer_id': 1,
        'receiver_id': 1,
        'rating': 1,
        'comfort_rating': 2,
        'safety_rating': 3,
        'reliability_rating': 4,
        'hospitality_rating': 5,
        'text': 'text',
      };
      final Review review = Review.fromJson(json);
      expect(review.text, 'text');
      expect(review.comfortRating, 2);
      expect(review.safetyRating, 3);
      expect(review.reliabilityRating, 4);
      expect(review.hospitalityRating, 5);
    });
  });

  group('Review.fromJsonList', () {
    test('parses a list of Reviews from json', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'writer_id': 1,
        'receiver_id': 1,
        'rating': 5,
        'comment': 'This is a comment',
      };
      final List<Map<String, dynamic>> jsonList = [json, json, json];
      final List<Review> reviews = Review.fromJsonList(jsonList);
      expect(reviews.first.id, json['id']);
      expect(reviews[1].createdAt, DateTime.parse(json['created_at']));
      expect(reviews.last.writerId, json['writer_id']);
      expect(reviews.first.receiverId, json['receiver_id']);
      expect(reviews.first.rating, json['rating']);
    });

    test('can handle an empty list', () {
      final List<Review> reviews = Review.fromJsonList([]);
      expect(reviews, []);
    });
  });

  group('Review.toJson', () {
    test('returns a json representation of the review', () {
      final Review review = ReviewFactory().generateFake();
      final Map<String, dynamic> json = review.toJson();
      expect(json['writer_id'], review.writerId);
      expect(json['receiver_id'], review.receiverId);
      expect(json['rating'], review.rating);
      expect(json['comfort_rating'], review.comfortRating);
      expect(json['safety_rating'], review.safetyRating);
      expect(json['reliability_rating'], review.reliabilityRating);
      expect(json['hospitality_rating'], review.hospitalityRating);
      expect(json['text'], review.text);
      expect(json.keys.length, 8);
    });
    test('can handle null vlaues', () {
      final Review review = ReviewFactory().generateFake(
        comfortRating: NullableParameter(null),
        safetyRating: NullableParameter(null),
        reliabilityRating: NullableParameter(null),
        hospitalityRating: NullableParameter(null),
        text: NullableParameter(null),
      );
      final Map<String, dynamic> json = review.toJson();
      expect(json['text'], null);
      expect(json['comfort_rating'], null);
      expect(json['safety_rating'], null);
      expect(json['reliability_rating'], null);
      expect(json['hospitality_rating'], null);
      expect(json.keys.length, 8);
    });
  });

  group('Review.compareTo', () {
    test('returns 0 if the reviews are equal', () {
      final Review review = ReviewFactory().generateFake();
      expect(review.compareTo(review), 0);
    });
    test('ratings with text are rated higher', () {
      final Review review = ReviewFactory().generateFake();
      final Review review2 = ReviewFactory().generateFake(
        text: NullableParameter(null),
      );
      expect(review.compareTo(review2), -1);
      expect(review2.compareTo(review), 1);
    });
    test('ratings are rated by created at', () {
      final Review review = ReviewFactory().generateFake(
        createdAt: DateTime.parse('2021-01-01T00:00:00.000Z'),
      );
      final Review review2 = ReviewFactory().generateFake(
        createdAt: DateTime.parse('2021-01-02T00:00:00.000Z'),
      );
      expect(review.compareTo(review2), 1);
      expect(review2.compareTo(review), -1);
    });

    test('text is prioiritized over created at', () {
      final Review review = ReviewFactory().generateFake(
        createdAt: DateTime.parse('2021-01-01T00:00:00.000Z'),
        text: NullableParameter('text'),
      );
      final Review review2 = ReviewFactory().generateFake(
        createdAt: DateTime.parse('2021-01-02T00:00:00.000Z'),
        text: NullableParameter(null),
      );
      expect(review.compareTo(review2), -1);
      expect(review2.compareTo(review), 1);
    });
  });

  group('Review.toString', () {
    test('returns a string representation of the review', () {
      final Review review = ReviewFactory().generateFake(
        text: NullableParameter('text'),
      );
      expect(review.toString(),
          'Review{id: ${review.id}, rating: ${review.rating}, text: ${review.text}, writerId: ${review.writerId}, receiverId: ${review.receiverId}, createdAt: ${review.createdAt}}');
    });
  });

  group('AggregateReview.isSet Methods', () {
    test('isSet returns true if the value is not 0', () {
      final AggregateReview review = AggregateReview(
        rating: 1,
        comfortRating: 1,
        safetyRating: 1,
        reliabilityRating: 1,
        hospitalityRating: 1,
        numberOfReviews: 4,
      );
      expect(review.isRatingSet, true);
      expect(review.isComfortSet, true);
      expect(review.isSafetySet, true);
      expect(review.isReliabilitySet, true);
      expect(review.isHospitalitySet, true);
    });
    test('isSet returns false if the value is 0', () {
      final AggregateReview review = AggregateReview(
        rating: 0,
        comfortRating: 0,
        safetyRating: 0,
        reliabilityRating: 0,
        hospitalityRating: 0,
        numberOfReviews: 0,
      );
      expect(review.isRatingSet, false);
      expect(review.isComfortSet, false);
      expect(review.isSafetySet, false);
      expect(review.isReliabilitySet, false);
      expect(review.isHospitalitySet, false);
    });
  });

  group('AggregateReview.fromReviews', () {
    test('returns an AggregateReview from a list of reviews', () {
      final Review review1 = ReviewFactory().generateFake(
        rating: 1,
        comfortRating: NullableParameter(2),
        safetyRating: NullableParameter(3),
        reliabilityRating: NullableParameter(4),
        hospitalityRating: NullableParameter(5),
      );
      final Review review2 = ReviewFactory().generateFake(
        rating: 2,
        comfortRating: NullableParameter(3),
        safetyRating: NullableParameter(4),
        reliabilityRating: NullableParameter(5),
        hospitalityRating: NullableParameter(1),
      );
      final Review review3 = ReviewFactory().generateFake(
        rating: 3,
        comfortRating: NullableParameter(4),
        safetyRating: NullableParameter(5),
        reliabilityRating: NullableParameter(1),
        hospitalityRating: NullableParameter(3),
      );

      final AggregateReview aggregateReview1 = AggregateReview.fromReviews([review1]);
      expect(aggregateReview1.rating, 1);
      expect(aggregateReview1.comfortRating, 2);
      expect(aggregateReview1.safetyRating, 3);
      expect(aggregateReview1.reliabilityRating, 4);
      expect(aggregateReview1.hospitalityRating, 5);
      expect(aggregateReview1.numberOfReviews, 1);
      final AggregateReview aggregateReview2 = AggregateReview.fromReviews([review1, review1, review1]);
      expect(aggregateReview2.rating, 1);
      expect(aggregateReview2.comfortRating, 2);
      expect(aggregateReview2.safetyRating, 3);
      expect(aggregateReview2.reliabilityRating, 4);
      expect(aggregateReview2.hospitalityRating, 5);
      expect(aggregateReview2.numberOfReviews, 3);
      final AggregateReview aggregateReview3 = AggregateReview.fromReviews([review1, review2, review3]);
      expect(aggregateReview3.rating, 2);
      expect(aggregateReview3.comfortRating, 3);
      expect(aggregateReview3.safetyRating, 4);
      expect(aggregateReview3.reliabilityRating, 10 / 3);
      expect(aggregateReview3.hospitalityRating, 3);
      expect(aggregateReview3.numberOfReviews, 3);
    });
    test('returns an AggregateReview from an empty list', () {
      final List<Review> reviews = [];
      final AggregateReview review = AggregateReview.fromReviews(reviews);
      expect(review.rating, 0);
      expect(review.comfortRating, 0);
      expect(review.safetyRating, 0);
      expect(review.reliabilityRating, 0);
      expect(review.hospitalityRating, 0);
      expect(review.numberOfReviews, 0);
    });
    test('returns zero if rating is not set', () {
      final Review review = ReviewFactory().generateFake(
        rating: 0,
        comfortRating: NullableParameter(null),
        safetyRating: NullableParameter(null),
        reliabilityRating: NullableParameter(null),
        hospitalityRating: NullableParameter(null),
      );
      final AggregateReview aggregateReview1 = AggregateReview.fromReviews([review]);
      expect(aggregateReview1.comfortRating, 0);
      expect(aggregateReview1.safetyRating, 0);
      expect(aggregateReview1.reliabilityRating, 0);
      expect(aggregateReview1.hospitalityRating, 0);
      final AggregateReview aggregateReview2 = AggregateReview.fromReviews([review, review, review]);
      expect(aggregateReview2.comfortRating, 0);
      expect(aggregateReview2.safetyRating, 0);
      expect(aggregateReview2.reliabilityRating, 0);
      expect(aggregateReview2.hospitalityRating, 0);
    });
    test('discards null values', () {
      final Review review1 = ReviewFactory().generateFake(
        rating: 1,
        comfortRating: NullableParameter(null),
        safetyRating: NullableParameter(null),
        reliabilityRating: NullableParameter(null),
        hospitalityRating: NullableParameter(null),
      );
      final List<Review> reviews = ReviewFactory().generateFakeList(length: 3);
      final AggregateReview aggregateReview = AggregateReview.fromReviews(reviews);
      final AggregateReview aggregateReviewWithNull = AggregateReview.fromReviews([review1, ...reviews]);
      expect(aggregateReviewWithNull.comfortRating, aggregateReview.comfortRating);
      expect(aggregateReviewWithNull.safetyRating, aggregateReview.safetyRating);
      expect(aggregateReviewWithNull.reliabilityRating, aggregateReview.reliabilityRating);
      expect(aggregateReviewWithNull.hospitalityRating, aggregateReview.hospitalityRating);
      expect(aggregateReviewWithNull.numberOfReviews, aggregateReview.numberOfReviews + 1);
    });
  });
}
