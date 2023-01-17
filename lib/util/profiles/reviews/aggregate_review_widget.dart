import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../account/models/review.dart';
import 'custom_rating_bar_indicator.dart';
import 'custom_rating_bar_size.dart';

class AggregateReviewWidget extends StatelessWidget {
  final AggregateReview _aggregateReview;
  const AggregateReviewWidget(this._aggregateReview, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Text(_aggregateReview.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            CustomRatingBarIndicator(rating: _aggregateReview.rating, size: CustomRatingBarSize.large),
            Expanded(
              child: Text(
                S.of(context).pageReviewCount(_aggregateReview.numberOfReviews),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context).reviewCategoryComfort),
                  const SizedBox(width: 10),
                  CustomRatingBarIndicator(rating: _aggregateReview.comfortRating),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context).reviewCategorySafety),
                  const SizedBox(width: 10),
                  CustomRatingBarIndicator(rating: _aggregateReview.safetyRating)
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context).reviewCategoryReliability),
                  const SizedBox(width: 10),
                  CustomRatingBarIndicator(rating: _aggregateReview.reliabilityRating)
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context).reviewCategoryHospitality),
                  const SizedBox(width: 10),
                  CustomRatingBarIndicator(rating: _aggregateReview.hospitalityRating)
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
