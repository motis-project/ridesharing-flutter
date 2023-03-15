import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/fade_out.dart';
import '../../util/locale_manager.dart';
import '../../util/profiles/profile_chip.dart';
import '../../util/profiles/reviews/custom_rating_bar_indicator.dart';
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
  State<ReviewDetail> createState() => ReviewDetailState();
}

class ReviewDetailState extends State<ReviewDetail> {
  bool isExpanded = false;

  static const int defaultLinesShown = 2;

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
          key: const Key('reviewRating'),
        ),
      ],
    );

    return Card(
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
                    final int? maxLinesShown = isExpanded ? null : defaultLinesShown;

                    final TextSpan span = TextSpan(text: widget.review.text);
                    final TextPainter tp = TextPainter(
                      maxLines: maxLinesShown,
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                      text: span,
                    )..layout(maxWidth: size.maxWidth);
                    final bool exceeded = tp.didExceedMaxLines;

                    final Widget text = Text(
                      widget.review.text!,
                      maxLines: maxLinesShown,
                    );
                    if (!widget.isExpandable || !exceeded && !isExpanded) {
                      return text;
                    }

                    if (isExpanded) {
                      return Semantics(
                        label: S.of(context).retract,
                        child: InkWell(
                          onTap: () => setState(() => isExpanded = !isExpanded),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[text, const Icon(Icons.expand_less, key: Key('retractReviewButton'))],
                          ),
                        ),
                      );
                    }
                    return FadeOut(
                      tooltip: S.of(context).expand,
                      onTap: () => setState(() => isExpanded = !isExpanded),
                      indicator: const Icon(Icons.expand_more, key: Key('expandReviewButton')),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[text, const SizedBox(height: 22)],
                      ),
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
