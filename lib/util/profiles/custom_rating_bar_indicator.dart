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
      itemSize: getRatingBarIndicatorSize(),
      direction: Axis.horizontal,
    );
  }

  double getRatingBarIndicatorSize() {
    switch (size) {
      case CustomRatingBarIndicatorSize.small:
        return 15.0;
      case CustomRatingBarIndicatorSize.medium:
        return 20.0;
      case CustomRatingBarIndicatorSize.large:
        return 30.0;
    }
  }
}

enum CustomRatingBarIndicatorSize {
  small,
  medium,
  large,
}
