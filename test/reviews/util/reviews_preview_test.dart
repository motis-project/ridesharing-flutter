import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/widgets/review_detail.dart';
import 'package:motis_mitfahr_app/account/widgets/reviews_preview.dart';
import 'package:motis_mitfahr_app/reviews/models/review.dart';
import 'package:motis_mitfahr_app/reviews/pages/reviews_page.dart';
import 'package:motis_mitfahr_app/reviews/util/aggregate_review_widget.dart';

import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/review_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  group('ReviewsPreview', () {
    final Finder reviewsPreviewFinder = find.byType(ReviewsPreview);
    final Review emptyReview = ReviewFactory().generateFake(text: NullableParameter(null));
    final Review earlierEmptyReview = ReviewFactory().generateFake(
      text: NullableParameter(null),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    final Review reviewWithText = ReviewFactory().generateFake(text: NullableParameter('This is a review'));
    final Review earlierReviewWithText = ReviewFactory().generateFake(
      text: NullableParameter('This is an earlier review'),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    final Profile profile = ProfileFactory().generateFake(
      reviewsReceived: [emptyReview, earlierEmptyReview, reviewWithText, earlierReviewWithText],
    );

    testWidgets('Shows review details', (WidgetTester tester) async {
      await pumpMaterial(tester, ReviewsPreview(profile));
      expect(reviewsPreviewFinder, findsOneWidget);

      expect(find.byType(AggregateReviewWidget), findsOneWidget);

      final Finder reviewDetailFinder = find.byType(ReviewDetail);
      expect(reviewDetailFinder, findsNWidgets(2));

      // Sorts reviews by whether they have text, then by date
      expect(tester.widget<ReviewDetail>(reviewDetailFinder.at(0)).review, reviewWithText);
      expect(tester.widget<ReviewDetail>(reviewDetailFinder.at(1)).review, earlierReviewWithText);

      expect(tester.widget<ReviewDetail>(reviewDetailFinder.at(0)).isExpandable, false);
    });

    testWidgets('Works without reviews', (WidgetTester tester) async {
      await pumpMaterial(tester, ReviewsPreview(ProfileFactory().generateFake(reviewsReceived: [])));
      expect(reviewsPreviewFinder, findsOneWidget);

      expect(find.byType(AggregateReviewWidget), findsOneWidget);

      final Finder reviewDetailFinder = find.byType(ReviewDetail);
      expect(reviewDetailFinder, findsNothing);
    });

    testWidgets('Navigates to reviews page', (WidgetTester tester) async {
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
          .thenReturnJson(profile.toJsonForApi());

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'), methodMatcher: equals('GET')).thenReturnJson([]);

      await pumpMaterial(tester, ReviewsPreview(profile));
      await tester.tap(reviewsPreviewFinder);

      await tester.pumpAndSettle();

      expect(find.byType(ReviewsPage), findsOneWidget);
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, ReviewsPreview(profile));
    });
  });
}
