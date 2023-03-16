import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/review.dart';
import 'custom_rating_bar_size.dart';

class CustomRatingBar extends StatelessWidget {
  final CustomRatingBarSize size;
  final void Function(double) onRatingUpdate;
  final int? rating;

  const CustomRatingBar({
    super.key,
    this.size = CustomRatingBarSize.medium,
    required this.onRatingUpdate,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      minRating: 1,
      itemBuilder: (BuildContext context, int index) => Semantics(
        label: S.of(context).ratingBarSemantics(index + 1),
        child: const Icon(
          key: Key('ratingBarIcon'),
          Icons.star,
          color: Colors.amber,
        ),
      ),
      // Keep the next line for more explicitness, and to avoid breaking changes
      // ignore: avoid_redundant_argument_values
      itemCount: Review.maxRating,
      itemSize: size.itemSize,
      onRatingUpdate: onRatingUpdate,
      initialRating: rating?.toDouble() ?? 0,
    );
  }
}
