import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CustomRatingBarIndicator extends StatelessWidget {
  final double rating;
  final CustomRatingBarIndicatorSize size;

  const CustomRatingBarIndicator({
    super.key,
    required this.rating,
    this.size = CustomRatingBarIndicatorSize.small,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemBuilder: (context, index) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      itemCount: 5,
      itemSize: size == CustomRatingBarIndicatorSize.small ? 15.0 : 30.0,
      direction: Axis.horizontal,
    );
  }
}

enum CustomRatingBarIndicatorSize {
  small,
  large,
}
