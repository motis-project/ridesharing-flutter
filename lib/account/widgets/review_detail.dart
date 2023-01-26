import 'package:flutter/material.dart';

import '../../util/locale_manager.dart';
import '../../util/profiles/profile_chip.dart';
import '../../util/profiles/reviews/custom_rating_bar_indicator.dart';
import '../../util/profiles/reviews/custom_rating_bar_size.dart';
import '../models/review.dart';

class ReviewDetail extends StatelessWidget {
  final Review review;
  final bool withHero;
  const ReviewDetail({super.key, required this.review, this.withHero = false});

  @override
  Widget build(BuildContext context) {
    final Widget header = Row(
      children: <Widget>[
        ProfileChip(review.writer!, withHero: withHero),
        Text(
          localeManager.formatDate(review.createdAt!),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: CustomRatingBarIndicator(
              rating: review.rating.toDouble(),
              size: CustomRatingBarSize.medium,
            ),
          ),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            header,
            if (review.text?.isNotEmpty ?? false) ...<Widget>[
              const SizedBox(
                height: 5,
              ),
              SizedBox(
                width: double.infinity,
                child: Text(review.text!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
