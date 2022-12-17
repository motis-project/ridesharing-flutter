import 'package:flutter/material.dart';
import 'package:flutter_app/util/profiles/reviews/custom_rating_bar_size.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      itemCount: 5,
      itemSize: size.itemSize,
      direction: Axis.horizontal,
      onRatingUpdate: onRatingUpdate,
      initialRating: rating?.toDouble() ?? 0,
    );
  }
}
