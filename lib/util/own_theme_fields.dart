import 'package:flutter/material.dart';

class OwnThemeFields {
  final Color success;
  final Color onSuccess;

  final Color warning;
  final Color onWarning;

  const OwnThemeFields({
    this.success = Colors.green,
    this.onSuccess = Colors.white,
    this.warning = Colors.orange,
    this.onWarning = Colors.white,
  });
}

extension ThemeDataExtensions on ThemeData {
  static final Map<InputDecorationTheme, OwnThemeFields> _own = <InputDecorationTheme, OwnThemeFields>{};

  void addOwn(OwnThemeFields own) {
    _own[inputDecorationTheme] = own;
  }

  static OwnThemeFields? empty;

  OwnThemeFields own() {
    OwnThemeFields? o = _own[inputDecorationTheme];
    if (o == null) {
      empty ??= const OwnThemeFields();
      o = empty;
    }
    return o!;
  }
}
