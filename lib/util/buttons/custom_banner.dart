import 'package:flutter/material.dart';

import 'display_color_kind.dart';

class CustomBanner extends StatelessWidget {
  final DisplayColorKind displayColorKind;
  final String text;

  const CustomBanner(this.text, {super.key, required this.displayColorKind});

  factory CustomBanner.error(String text, {Key? key}) =>
      CustomBanner(text, displayColorKind: DisplayColorKind.error, key: key);
  factory CustomBanner.warning(String text, {Key? key}) =>
      CustomBanner(text, displayColorKind: DisplayColorKind.warning, key: key);
  factory CustomBanner.primary(String text, {Key? key}) =>
      CustomBanner(text, displayColorKind: DisplayColorKind.primary, key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: displayColorKind.getBackgroundColor(context),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: displayColorKind.getColor(context),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
