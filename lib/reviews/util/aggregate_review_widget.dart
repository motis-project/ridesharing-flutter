import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/review.dart';
import 'custom_rating_bar_indicator.dart';
import 'custom_rating_bar_size.dart';

class AggregateReviewWidget extends StatelessWidget {
  final AggregateReview aggregateReview;
  const AggregateReviewWidget(this.aggregateReview, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            ExcludeSemantics(
              child: Text(aggregateReview.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            CustomRatingBarIndicator(rating: aggregateReview.rating, size: CustomRatingBarSize.large),
            Expanded(
              child: Text(
                S.of(context).pageReviewCount(aggregateReview.numberOfReviews),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRatingTable(context),
      ],
    );
  }

  static const double verticalTableSpacing = 3.0;
  static TableRow verticalTableSpacer =
      TableRow(children: List<Widget>.generate(3, (int _) => const SizedBox(height: verticalTableSpacing)));
  static const double horizontalSpacing = 20.0;
  static TableCell horizontalTableSpacer = const TableCell(child: SizedBox(width: horizontalSpacing));

  Widget _buildRatingTable(BuildContext context) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(horizontalSpacing),
        2: FlexColumnWidth(),
      },
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            Text(S.of(context).reviewCategoryComfort),
            horizontalTableSpacer,
            CustomRatingBarIndicator(rating: aggregateReview.comfortRating),
          ],
        ),
        verticalTableSpacer,
        TableRow(
          children: <Widget>[
            Text(S.of(context).reviewCategorySafety),
            horizontalTableSpacer,
            CustomRatingBarIndicator(rating: aggregateReview.safetyRating),
          ],
        ),
        verticalTableSpacer,
        TableRow(
          children: <Widget>[
            Text(S.of(context).reviewCategoryReliability),
            horizontalTableSpacer,
            CustomRatingBarIndicator(rating: aggregateReview.reliabilityRating),
          ],
        ),
        verticalTableSpacer,
        TableRow(
          children: <Widget>[
            Text(S.of(context).reviewCategoryHospitality),
            horizontalTableSpacer,
            CustomRatingBarIndicator(rating: aggregateReview.hospitalityRating),
          ],
        ),
      ],
    );
  }
}
