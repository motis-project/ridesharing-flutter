import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// ignore: long-parameter-list
void showSnackBar(
  BuildContext context,
  String message, {
  SnackBarDurationType durationType = SnackBarDurationType.long,
  bool replace = false,
  Key? key,
}) {
  SemanticsService.announce(message, TextDirection.ltr);

  if (replace) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: key,
      content: Text(message),
      duration: durationType.duration,
    ),
  );
}

enum SnackBarDurationType { short, medium, long }

extension SnackBarDurationExtension on SnackBarDurationType {
  Duration get duration {
    switch (this) {
      case SnackBarDurationType.short:
        return const Duration(seconds: 1);
      case SnackBarDurationType.medium:
        return const Duration(seconds: 2);
      case SnackBarDurationType.long:
        return const Duration(seconds: 4);
    }
  }
}
