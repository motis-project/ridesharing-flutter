import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_chip.dart';
import 'package:motis_mitfahr_app/account/widgets/review_detail.dart';
import 'package:motis_mitfahr_app/reviews/models/review.dart';
import 'package:motis_mitfahr_app/reviews/util/custom_rating_bar_indicator.dart';

import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/review_factory.dart';
import '../../test_util/pump_material.dart';

void main() {
  Future<void> pumpReviewDetail(WidgetTester tester, Review review) async {
    await pumpScaffold(
      tester,
      SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [ReviewDetail(review: review)],
        ),
      ),
    );
  }

  group('ReviewDetail', () {
    final Finder reviewDetailFinder = find.byType(ReviewDetail);
    final Finder expandReviewButtonFinder = find.byKey(const Key('expandReviewButton'));
    final Finder retractReviewButtonFinder = find.byKey(const Key('retractReviewButton'));
    final Review review = ReviewFactory().generateFake(text: NullableParameter('This is a review'));

    testWidgets('Shows review detail', (WidgetTester tester) async {
      await pumpReviewDetail(tester, review);
      expect(reviewDetailFinder, findsOneWidget);

      expect(find.byType(ProfileChip), findsOneWidget);
      expect(find.byType(CustomRatingBarIndicator), findsOneWidget);
      expect(find.text(review.text!), findsOneWidget);
      expect(expandReviewButtonFinder, findsNothing);
    });

    testWidgets('Works without text', (WidgetTester tester) async {
      await pumpReviewDetail(tester, ReviewFactory().generateFake(text: NullableParameter(null)));
      expect(find.byType(ProfileChip), findsOneWidget);
      expect(find.byType(CustomRatingBarIndicator), findsOneWidget);
      expect(expandReviewButtonFinder, findsNothing);
    });

    testWidgets('Can expand and retract when text is long', (WidgetTester tester) async {
      final Review review = ReviewFactory().generateFake(text: NullableParameter('This is a review' * 100));

      await pumpReviewDetail(tester, review);

      expect(expandReviewButtonFinder, findsOneWidget);
      await tester.tap(expandReviewButtonFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(retractReviewButtonFinder, findsOneWidget);
      await tester.scrollUntilVisible(retractReviewButtonFinder, 100, scrollable: find.byType(Scrollable).first);

      await tester.tap(retractReviewButtonFinder);
      await tester.pumpAndSettle();

      expect(expandReviewButtonFinder, findsOneWidget);
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, ReviewDetail(review: review));
    });
  });
}
