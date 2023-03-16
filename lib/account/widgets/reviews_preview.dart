import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../reviews/models/review.dart';
import '../../reviews/pages/reviews_page.dart';
import '../../reviews/util/aggregate_review_widget.dart';
import '../../util/fade_out.dart';
import '../models/profile.dart';
import 'review_detail.dart';

class ReviewsPreview extends StatelessWidget {
  final Profile profile;

  const ReviewsPreview(this.profile, {super.key});

  @override
  Widget build(BuildContext context) {
    final List<Review> reviews = profile.reviewsReceived!..sort((Review a, Review b) => a.compareTo(b));
    final AggregateReview aggregateReview = AggregateReview.fromReviews(reviews);

    return Semantics(
      label: S.of(context).reviewsPreviewReviews,
      button: true,
      tooltip: S.of(context).reviewsPreviewShowReviews,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              AggregateReviewWidget(aggregateReview),
              if (reviews.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                ExcludeSemantics(
                  child: FadeOut(
                    label: S.of(context).openDetails,
                    indicator: Text(
                      S.of(context).more,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                    indicatorAlignment: Alignment.bottomRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ClipRect(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List<ReviewDetail>.generate(
                              min(reviews.length, 2),
                              (int index) => ReviewDetail(review: reviews[index], isExpandable: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Semantics(
                label: S.of(context).openDetails,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => ReviewsPage(profile: profile)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
