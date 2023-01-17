import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/profile.dart';
import '../models/review.dart';
import '../pages/reviews_page.dart';
import 'review_detail.dart';

class ReviewsPreview extends StatelessWidget {
  final Profile profile;

  const ReviewsPreview(this.profile, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Review> reviews = profile.reviewsReceived!..sort((a, b) => a.compareTo(b));
    AggregateReview aggregateReview = AggregateReview.fromReviews(reviews);

    return Semantics(
      label: S.of(context).reviewsPreviewReviews,
      button: true,
      tooltip: S.of(context).reviewsPreviewShowReviews,
      child: Stack(
        children: [
          Column(
            children: [
              aggregateReview.widget(),
              if (reviews.isNotEmpty)
                ExcludeSemantics(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
                        blendMode: BlendMode.dstIn,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ClipRect(
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  min(reviews.length, 2),
                                  (index) => ReviewDetail(review: reviews[index]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
          if (reviews.isNotEmpty)
            Positioned(
              bottom: 2,
              right: 2,
              child: ExcludeSemantics(
                child: Text(
                  S.of(context).more,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReviewsPage.fromProfile(profile)));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
