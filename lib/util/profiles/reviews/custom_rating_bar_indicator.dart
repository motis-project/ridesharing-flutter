import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../account/models/review.dart';
import 'custom_rating_bar_size.dart';

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
        itemBuilder: (BuildContext context, int index) => const Icon(
          Icons.star,
          color: Colors.amber,
        ),
        // Keep the next line for more explicitness, and to avoid breaking changes
        // ignore: avoid_redundant_argument_values
        itemCount: Review.maxRating,
        itemSize: size.itemSize,
      ),
    );
  }
}
