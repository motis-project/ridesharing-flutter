enum CustomRatingBarSize {
  small,
  medium,
  large,
  huge,
}

extension CustomRatingBarSizeExtension on CustomRatingBarSize {
  double get itemSize {
    switch (this) {
      case CustomRatingBarSize.small:
        return 15.0;
      case CustomRatingBarSize.medium:
        return 20.0;
      case CustomRatingBarSize.large:
        return 30.0;
      case CustomRatingBarSize.huge:
        return 48.0;
    }
  }
}
