import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../account/models/review.dart';
import 'custom_rating_bar_size.dart';

class CustomRatingBar extends StatelessWidget {
  final CustomRatingBarSize size;
  final Function(double) onRatingUpdate;
  final int? rating;

  const CustomRatingBar({
    super.key,
    this.size = CustomRatingBarSize.small,
    required this.onRatingUpdate,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      minRating: 1,
      itemBuilder: (BuildContext context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
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
