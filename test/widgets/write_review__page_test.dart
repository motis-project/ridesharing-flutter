import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/account/pages/reviews_page.dart';
import 'package:motis_mitfahr_app/account/pages/write_review_page.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';

import '../util/factories/profile_factory.dart';
import '../util/factories/review_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
    profile = ProfileFactory().generateFake(id: 1);
    supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews'), methodMatcher: equals('GET'))
        .thenReturnJson(null);

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'), methodMatcher: equals('GET')).thenReturnJson([
      RideFactory()
          .generateFake(endTime: DateTime.now().subtract(const Duration(days: 2)), status: RideStatus.approved)
          .toJsonForApi(),
    ]);

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
        .thenReturnJson(profile.toJsonForApi());

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews'), methodMatcher: equals('POST'))
        .thenReturnJson(null);

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews?id=eq.12'), methodMatcher: equals('PATCH'))
        .thenReturnJson(null);
  });

  group('WriteReviewPage', () {
    testWidgets('constructor', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReviewPage(profile));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text(profile.username), findsOneWidget);
    });

    testWidgets('edit rating', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReviewPage(profile));
      await tester.pumpAndSettle();

      final Finder overallRating = find.byKey(const Key('overallRating'));
      expect(overallRating, findsOneWidget);
      expect((overallRating.evaluate().first.widget as CustomRatingBar).rating, 0);

      final Finder overallRatingStars =
          find.descendant(of: overallRating, matching: find.byKey(const Key('ratingBarIcon')));
      expect(overallRatingStars, findsNWidgets(5));

      final List<Key> ratingBarKeys = [
        const Key('comfortRating'),
        const Key('safetyRating'),
        const Key('reliabilityRating'),
        const Key('hospitalityRating'),
      ];

      final List<int> ratingList = [];

      for (final Key ratingBarKey in ratingBarKeys) {
        final int rating = Random().nextInt(4);
        final Finder ratingBar = find.byKey(ratingBarKey);

        expect(ratingBar, findsOneWidget);
        expect((ratingBar.evaluate().first.widget as CustomRatingBar).rating, null);

        final Finder ratingBarStars = find.descendant(of: ratingBar, matching: find.byKey(const Key('ratingBarIcon')));
        expect(ratingBarStars, findsNWidgets(5));

        await tester.tap(ratingBarStars.at(rating));
        await tester.pumpAndSettle();
        expect((ratingBar.evaluate().first.widget as CustomRatingBar).rating, rating + 1);
        ratingList.add(rating + 1);
      }

      //automatic overallRating
      expect((overallRating.evaluate().first.widget as CustomRatingBar).rating, ratingList.average.round());

      //manual overallRating
      await tester.tap(overallRatingStars.at(0));
      await tester.pumpAndSettle();
      expect((overallRating.evaluate().first.widget as CustomRatingBar).rating, 1);
    });

    testWidgets('load review', (WidgetTester tester) async {
      final Review review = ReviewFactory().generateFake(writerId: 2, receiverId: 1);

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews'), methodMatcher: equals('GET'))
          .thenReturnJson(review.toJsonForApi());

      await pumpMaterial(tester, WriteReviewPage(profile));
      await tester.pumpAndSettle();

      expect((find.byKey(const Key('overallRating')).evaluate().first.widget as CustomRatingBar).rating, review.rating);
      expect((find.byKey(const Key('comfortRating')).evaluate().first.widget as CustomRatingBar).rating,
          review.comfortRating);
      expect((find.byKey(const Key('safetyRating')).evaluate().first.widget as CustomRatingBar).rating,
          review.safetyRating);
      expect((find.byKey(const Key('reliabilityRating')).evaluate().first.widget as CustomRatingBar).rating,
          review.reliabilityRating);
      expect((find.byKey(const Key('hospitalityRating')).evaluate().first.widget as CustomRatingBar).rating,
          review.hospitalityRating);

      expect(find.text(review.text!), findsOneWidget);
    });

    testWidgets('write review', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReviewPage(profile));
      await tester.pumpAndSettle();

      final Finder reviewTextfield = find.byKey(const Key('reviewText'));
      expect(reviewTextfield, findsOneWidget);

      await tester.enterText(reviewTextfield, 'test');
      await tester.pumpAndSettle();

      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('no rating save button', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReviewPage(profile));
      await tester.pumpAndSettle();

      final Finder saveButton = find.byKey(const Key('submitButton'));
      expect(saveButton, findsOneWidget);

      await tester.tap(find.byKey(const Key('submitButton')));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('ratingRequiredSnackbar')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(WriteReviewPage), findsOneWidget);
    });

    testWidgets('new rating save button', (WidgetTester tester) async {
      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reviewsPage_reviewButton')));
      await tester.pumpAndSettle();

      final List<Key> ratingBarKeys = [
        const Key('comfortRating'),
        const Key('safetyRating'),
        const Key('reliabilityRating'),
        const Key('hospitalityRating'),
      ];

      for (final Key ratingBarKey in ratingBarKeys) {
        final int rating = Random().nextInt(4);
        final Finder ratingBarStars =
            find.descendant(of: find.byKey(ratingBarKey), matching: find.byKey(const Key('ratingBarIcon')));
        await tester.tap(ratingBarStars.at(rating));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewsPage), findsOneWidget);

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/reviews'),
        methodMatcher: equals('POST'),
      ).called(1);
    });

    testWidgets('edit rating save button', (WidgetTester tester) async {
      final Review review = ReviewFactory().generateFake(id: 12, writerId: 2, receiverId: 1);

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews'), methodMatcher: equals('GET'))
          .thenReturnJson(review.toJsonForApi());

      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reviewsPage_reviewButton')));
      await tester.pumpAndSettle();

      final int rating = Random().nextInt(4);
      final Finder ratingBarStars =
          find.descendant(of: find.byKey(const Key('comfortRating')), matching: find.byKey(const Key('ratingBarIcon')));
      await tester.tap(ratingBarStars.at(rating));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewsPage), findsOneWidget);

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/reviews?id=eq.12'),
        methodMatcher: equals('PATCH'),
      ).called(1);
    });
  });
}
