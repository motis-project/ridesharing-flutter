import 'package:flutter/material.dart';

import 'display_color_kind.dart';

class CustomBanner extends StatelessWidget {
  final DisplayColorKind displayColorKind;
  final String text;

  const CustomBanner(this.text, {super.key, this.displayColorKind = DisplayColorKind.primary});

  factory CustomBanner.error(text) => CustomBanner(text, displayColorKind: DisplayColorKind.error);
  factory CustomBanner.translucenterror(text) =>
      CustomBanner(text, displayColorKind: DisplayColorKind.translucenterror);
  factory CustomBanner.warning(text) => CustomBanner(text, displayColorKind: DisplayColorKind.warning);
  factory CustomBanner.pending(text) => CustomBanner(text, displayColorKind: DisplayColorKind.disabled);

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
