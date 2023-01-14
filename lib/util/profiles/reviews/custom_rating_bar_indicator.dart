import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_size.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomRatingBarIndicator extends StatelessWidget {
  final double rating;
  final CustomRatingBarSize size;

  const CustomRatingBarIndicator({
    super.key,
    required this.rating,
    this.size = CustomRatingBarSize.small,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).ratingBarSemantics(rating.toStringAsFixed(1)),
      child: RatingBarIndicator(
        rating: rating,
        itemBuilder: (context, index) => const Icon(
          Icons.star,
          color: Colors.amber,
        ),
        itemCount: Review.maxRating,
        itemSize: size.itemSize,
        direction: Axis.horizontal,
      ),
    );
  }
}
