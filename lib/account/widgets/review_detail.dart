import 'package:flutter/material.dart';
import '../../util/locale_manager.dart';
import '../../util/profiles/profile_chip.dart';
import '../../util/profiles/reviews/custom_rating_bar_size.dart';

import '../../util/profiles/reviews/custom_rating_bar_indicator.dart';
import '../models/review.dart';

class ReviewDetail extends StatelessWidget {
  final Review review;
  const ReviewDetail({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    Widget header = Row(
      children: [
        ProfileChip(review.writer!),
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
          children: [
            header,
            if (review.text?.isNotEmpty ?? false) ...[
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
