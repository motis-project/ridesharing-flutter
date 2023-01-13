import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/own_theme_fields.dart';

enum DisplayColorKind { primary, secondary, success, warning, error, disabled, translucenterror }

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
      case DisplayColorKind.translucenterror:
        return Theme.of(context).colorScheme.error.withOpacity(0.625);
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
      case DisplayColorKind.translucenterror:
        return Theme.of(context).colorScheme.onPrimary;
    }
  }
}
