import 'package:flutter/material.dart';

import '../../util/locale_manager.dart';
import '../../util/profiles/profile_chip.dart';
import '../../util/profiles/reviews/custom_rating_bar_indicator.dart';
import '../../util/profiles/reviews/custom_rating_bar_size.dart';
import '../models/review.dart';

class ReviewDetail extends StatefulWidget {
  final Review review;
  final bool withHero;
  final bool isExpandable;
  const ReviewDetail({
    super.key,
    required this.review,
    this.withHero = false,
    this.isExpandable = true,
  });

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
                localeManager.formatDate(widget.review.updatedAt ?? widget.review.createdAt!),
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
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints size) {
                    final int? maxLines = isExpanded ? null : 2;

                    final TextSpan span = TextSpan(text: widget.review.text);
                    final TextPainter tp = TextPainter(
                      maxLines: maxLines,
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                      text: span,
                    )..layout();
                    final bool exceeded = tp.didExceedMaxLines;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text.rich(
                          span,
                          overflow: TextOverflow.ellipsis,
                          maxLines: maxLines,
                        ),
                        if (widget.isExpandable && (exceeded || isExpanded)) ...<Widget>[
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: RichText(
                              text: TextSpan(
                                text: isExpanded ? S.of(context).showLess : S.of(context).showMore,
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => setState(() => isExpanded = !isExpanded),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
