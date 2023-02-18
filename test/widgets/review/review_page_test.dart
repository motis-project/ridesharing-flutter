import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/account/pages/reviews_page.dart';
import 'package:motis_mitfahr_app/account/pages/write_review_page.dart';
import 'package:motis_mitfahr_app/account/widgets/avatar.dart';
import 'package:motis_mitfahr_app/account/widgets/review_detail.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/aggregate_review_widget.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';

import '../../util/factories/profile_factory.dart';
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

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
        .thenReturnJson(profile.toJsonForApi());

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'), methodMatcher: equals('GET')).thenReturnJson([]);

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/reviews'), methodMatcher: equals('GET'))
        .thenReturnJson(null);
  });

  group('ReviewsPage', () {
    testWidgets('constructor', (WidgetTester tester) async {
      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewsPage), findsOneWidget);
      expect(find.text(profile.username), findsOneWidget);
      expect(find.byKey(const Key('reviewsPage_reviewButton')), findsNothing);
    });

    testWidgets('rate button', (WidgetTester tester) async {
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'), methodMatcher: equals('GET')).thenReturnJson([
        RideFactory()
            .generateFake(endTime: DateTime.now().subtract(const Duration(days: 2)), status: RideStatus.approved)
            .toJsonForApi(),
      ]);

      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pumpAndSettle();

      final Finder reviewButtonFinder = find.byKey(const Key('reviewsPage_reviewButton'));
      expect(reviewButtonFinder, findsOneWidget);

      await tester.tap(reviewButtonFinder);
      await tester.pumpAndSettle();
      expect(find.byType(WriteReviewPage), findsOneWidget);
    });

    testWidgets('ratings', (WidgetTester tester) async {
      final AggregateReview aggregateReview = AggregateReview.fromReviews(profile.reviewsReceived!);

      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('aggregateReview')), findsOneWidget);
      expect(find.text(aggregateReview.rating.toStringAsFixed(1)), findsOneWidget);
      expect(
          find.descendant(
            of: find.byKey(const Key('aggregateReview')),
            matching: find.byKey(const Key('ratingBarIndicator')),
          ),
          findsOneWidget);

      expect(find.byKey(const Key('reviewCount')), findsOneWidget);
      expect(find.byKey(const Key('comfortRating')), findsOneWidget);
      expect(find.byKey(const Key('safetyRating')), findsOneWidget);
      expect(find.byKey(const Key('reliabilityRating')), findsOneWidget);
      expect(find.byKey(const Key('hospitalityRating')), findsOneWidget);
    });

    testWidgets('reviews', (WidgetTester tester) async {
      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pumpAndSettle();

      for (int i = 0; i < profile.reviewsReceived!.length; i++) {
        final Review review = profile.reviewsReceived![i];
        expect(find.byKey(Key('reviewCard ${review.writerId}')), findsOneWidget);
        expect(find.byKey(Key('profile-${review.writerId}')), findsOneWidget);
        expect(
            find.descendant(
                of: find.byKey(Key('reviewCard ${review.writerId}')),
                matching: find.text(localeManager.formatDate(review.createdAt!))),
            findsOneWidget);
        expect(
            find.descendant(
                of: find.byKey(Key('reviewCard ${review.writerId}')), matching: find.byKey(const Key('reviewRating'))),
            findsOneWidget);
        expect(find.descendant(of: find.byKey(Key('reviewCard ${review.writerId}')), matching: find.text(review.text!)),
            findsOneWidget);
      }
    });

    testWidgets('no reviews', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(id: profile.id, reviewsReceived: []);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
          .thenReturnJson(profile.toJsonForApi());

      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pumpAndSettle();

      expect(find.text(profile.username), findsOneWidget);
      expect(find.byType(Avatar), findsOneWidget);
      expect(find.byType(AggregateReviewWidget), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.byType(ReviewDetail), findsNothing);
    });
  });
}
