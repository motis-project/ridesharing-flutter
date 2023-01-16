import 'package:flutter/material.dart';
import '../own_theme_fields.dart';

enum DisplayColorKind { primary, secondary, success, warning, error, disabled }

extension DisplayColorKindExtensions on DisplayColorKind {
  Color getBackgroundColor(BuildContext context) {
    switch (this) {
      case DisplayColorKind.primary:
        return Theme.of(context).colorScheme.primary;
      case DisplayColorKind.secondary:
        return Theme.of(context).colorScheme.secondary;
      case DisplayColorKind.success:
        return Theme.of(context).own().success;
      case DisplayColorKind.warning:
        return Theme.of(context).own().warning;
      case DisplayColorKind.error:
        return Theme.of(context).colorScheme.error;
      case DisplayColorKind.disabled:
        return Theme.of(context).disabledColor;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case DisplayColorKind.primary:
        return Theme.of(context).colorScheme.onPrimary;
      case DisplayColorKind.secondary:
        return Theme.of(context).colorScheme.onSecondary;
      case DisplayColorKind.success:
        return Theme.of(context).own().onSuccess;
      case DisplayColorKind.warning:
        return Theme.of(context).own().onWarning;
      case DisplayColorKind.error:
        return Theme.of(context).colorScheme.onError;
      case DisplayColorKind.disabled:
        return Theme.of(context).colorScheme.onPrimary;
    }
  }
}
