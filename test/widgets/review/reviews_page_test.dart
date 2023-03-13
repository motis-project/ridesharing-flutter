import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/account/pages/reviews_page.dart';
import 'package:motis_mitfahr_app/account/pages/write_review_page.dart';
import 'package:motis_mitfahr_app/account/widgets/avatar.dart';
import 'package:motis_mitfahr_app/account/widgets/review_detail.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
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
      await tester.pump();
      expect(find.byType(ReviewsPage), findsOneWidget);
      expect(find.text(profile.username), findsOneWidget);
      expect(find.byKey(const Key('reviewsPage_reviewButton')), findsNothing);
    });

    testWidgets('rate button', (WidgetTester tester) async {
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'), methodMatcher: equals('GET')).thenReturnJson([
        RideFactory()
            .generateFake(endDateTime: DateTime.now().subtract(const Duration(days: 2)), status: RideStatus.approved)
            .toJsonForApi(),
      ]);

      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pump();

      final Finder reviewButtonFinder = find.byKey(const Key('reviewsPage_reviewButton'));
      expect(reviewButtonFinder, findsOneWidget);

      await tester.tap(reviewButtonFinder);
      await tester.pumpAndSettle();
      expect(find.byType(WriteReviewPage), findsOneWidget);
    });

    testWidgets('ratings', (WidgetTester tester) async {
      final AggregateReview aggregateReview = AggregateReview.fromReviews(profile.reviewsReceived!);

      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pump();

      final Finder aggregateReviewFinder = find.byType(AggregateReviewWidget);
      expect(aggregateReviewFinder, findsOneWidget);
      expect(
        tester.widget<AggregateReviewWidget>(aggregateReviewFinder).aggregateReview.rating,
        aggregateReview.rating,
      );
    });

    testWidgets('reviews', (WidgetTester tester) async {
      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pump();

      final Finder reviewDetailFinder = find.byType(ReviewDetail);
      expect(
        reviewDetailFinder,
        findsNWidgets(profile.reviewsReceived!.length),
      );
    });

    testWidgets('no reviews', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(id: profile.id, reviewsReceived: []);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
          .thenReturnJson(profile.toJsonForApi());

      await pumpMaterial(tester, ReviewsPage(profile: profile));
      await tester.pump();

      expect(find.text(profile.username), findsOneWidget);
      expect(find.byType(Avatar), findsOneWidget);
      expect(find.byType(AggregateReviewWidget), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.byType(ReviewDetail), findsNothing);
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, ReviewsPage(profile: profile));
    });
  });
}
