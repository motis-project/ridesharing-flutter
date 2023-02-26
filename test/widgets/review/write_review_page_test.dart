import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/account/pages/reviews_page.dart';
import 'package:motis_mitfahr_app/account/pages/write_review_page.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../util/factories/profile_factory.dart';
import '../../util/factories/review_factory.dart';
import '../../util/factories/ride_factory.dart';
import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
    profile = ProfileFactory().generateFake();
    supabaseManager.currentProfile = ProfileFactory().generateFake(id: profile.id! + 1);

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

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews'), methodMatcher: equals('PATCH'))
        .thenReturnJson(null);
  });

  group('WriteReviewPage', () {
    testWidgets('constructor', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReviewPage(profile));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump();
      expect(find.text(profile.username), findsOneWidget);
    });

    testWidgets('edit rating', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReviewPage(profile));
      await tester.pump();

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
        await tester.pump();
        expect((ratingBar.evaluate().first.widget as CustomRatingBar).rating, rating + 1);
        ratingList.add(rating + 1);
      }

      //automatic overallRating
      expect((overallRating.evaluate().first.widget as CustomRatingBar).rating, ratingList.average.round());

      //manual overallRating
      await tester.tap(overallRatingStars.at(0));
      await tester.pump();
      expect((overallRating.evaluate().first.widget as CustomRatingBar).rating, 1);
    });

    testWidgets('load review', (WidgetTester tester) async {
      final Review review = ReviewFactory().generateFake(writerId: profile.id! + 1, receiverId: profile.id);

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews'), methodMatcher: equals('GET'))
          .thenReturnJson(review.toJsonForApi());

      await pumpMaterial(tester, WriteReviewPage(profile));
      await tester.pump();

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
      await tester.pump();

      final Finder saveButton = find.byKey(const Key('submitButton'));
      expect(saveButton, findsOneWidget);

      await tester.tap(find.byKey(const Key('submitButton')));

      await tester.pump(const Duration(milliseconds: 400));

      expect((tester.widget(saveButton) as LoadingButton).state, ButtonState.fail);
      expect(find.byKey(const Key('ratingRequiredSnackbar')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));

      expect((tester.widget(saveButton) as LoadingButton).state, ButtonState.idle);
      expect(find.byType(WriteReviewPage), findsOneWidget);

      verifyRequestNever(
        processor,
        urlMatcher: startsWith('/rest/v1/reviews'),
        methodMatcher: equals('POST'),
      );
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

      final List<int> ratingList = [];

      for (final Key ratingBarKey in ratingBarKeys) {
        final int rating = Random().nextInt(4);
        final Finder ratingBarStars =
            find.descendant(of: find.byKey(ratingBarKey), matching: find.byKey(const Key('ratingBarIcon')));
        await tester.tap(ratingBarStars.at(rating));
        ratingList.add(rating + 1);
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byKey(const Key('reviewText')), 'test');

      final Finder saveButton = find.byKey(const Key('submitButton'));
      await tester.tap(saveButton);

      await tester.pump(const Duration(milliseconds: 400));

      expect((tester.widget(saveButton) as LoadingButton).state, ButtonState.success);

      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ReviewsPage), findsOneWidget);

      verifyRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/reviews'),
        methodMatcher: equals('POST'),
        bodyMatcher: equals({
          'rating': ratingList.average.round(),
          'comfort_rating': ratingList[0],
          'safety_rating': ratingList[1],
          'reliability_rating': ratingList[2],
          'hospitality_rating': ratingList[3],
          'text': 'test',
          'writer_id': profile.id! + 1,
          'receiver_id': profile.id
        }),
      ).called(1);
    });

    testWidgets('edit rating save button', (WidgetTester tester) async {
      final Review review = ReviewFactory().generateFake(writerId: profile.id! + 1, receiverId: profile.id);

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

      final Finder saveButton = find.byKey(const Key('submitButton'));
      await tester.tap(saveButton);

      await tester.pump(const Duration(milliseconds: 400));

      expect((tester.widget(saveButton) as LoadingButton).state, ButtonState.success);

      await tester.pump();

      expect(find.byType(ReviewsPage), findsOneWidget);

      final int newRating =
          [rating + 1, review.safetyRating!, review.reliabilityRating!, review.hospitalityRating!].average.round();

      verifyRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/reviews?id=eq.${review.id}'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({
          'rating': newRating,
          'comfort_rating': rating + 1,
          'safety_rating': review.safetyRating,
          'reliability_rating': review.reliabilityRating,
          'hospitality_rating': review.hospitalityRating,
          'text': review.text,
          'writer_id': profile.id! + 1,
          'receiver_id': profile.id
        }),
      ).called(1);
    });
  });
}
