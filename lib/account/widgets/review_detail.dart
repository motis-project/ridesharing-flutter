import 'package:flutter/material.dart';

import '../../util/locale_manager.dart';
import '../../util/profiles/profile_chip.dart';
import '../../util/profiles/reviews/custom_rating_bar_indicator.dart';
import '../../util/profiles/reviews/custom_rating_bar_size.dart';
import '../models/review.dart';

class ReviewDetail extends StatefulWidget {
  final Review review;
  final bool withHero;
  const ReviewDetail({super.key, required this.review, this.withHero = false});

  @override
  State<ReviewDetail> createState() => _ReviewDetailState();
}

class _ReviewDetailState extends State<ReviewDetail> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final Widget header = Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Flexible(child: ProfileChip(widget.review.writer!, withHero: widget.withHero)),
              Text(
                localeManager.formatDate(widget.review.updatedAt),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        CustomRatingBarIndicator(
          rating: widget.review.rating.toDouble(),
          size: CustomRatingBarSize.medium,
          key: const Key('reviewRating'),
        ),
      ],
    );

    return Card(
      key: Key('reviewCard ${widget.review.writerId}'),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            header,
            if (widget.review.text?.isNotEmpty ?? false) ...<Widget>[
              const SizedBox(
                height: 5,
              ),
              SizedBox(
                width: double.infinity,
                child: Text(widget.review.text!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
