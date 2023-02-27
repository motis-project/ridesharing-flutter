import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/account/widgets/review_detail.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_chip.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_indicator.dart';

import '../../util/factories/model_factory.dart';
import '../../util/factories/review_factory.dart';
import '../../util/pump_material.dart';

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

    testWidgets('Can expand and retract when text is long', skip: true, (WidgetTester tester) async {
      final Review review = ReviewFactory().generateFake(text: NullableParameter('This is a review' * 100));
      final Finder reviewTextFinder = find.byKey(const Key('reviewText'));

      await pumpReviewDetail(tester, review);

      Text reviewTextWidget = tester.widget<Text>(reviewTextFinder);
      expect(reviewTextWidget.data!.length, lessThan(review.text!.length));

      expect(expandReviewButtonFinder, findsOneWidget);

      await tester.tap(expandReviewButtonFinder);
      await tester.pumpAndSettle();

      expect(expandReviewButtonFinder, findsOneWidget);
      expect(reviewTextWidget.data!.length, review.text!.length);

      await tester.tap(expandReviewButtonFinder);
      await tester.pumpAndSettle();

      reviewTextWidget = tester.widget<Text>(reviewTextFinder);
      expect(reviewTextWidget.data!.length, lessThan(review.text!.length));

      expect(expandReviewButtonFinder, findsOneWidget);
    });
  });
}
