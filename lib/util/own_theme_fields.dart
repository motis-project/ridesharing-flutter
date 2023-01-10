import 'package:flutter/material.dart';

class OwnThemeFields {
  final Color success;
  final Color onSuccess;

  final Color warning;
  final Color onWarning;

  final Color pending;
  final Color onPending;

  const OwnThemeFields(
      {this.success = Colors.green,
      this.onSuccess = Colors.white,
      this.warning = Colors.orange,
      this.onWarning = Colors.white,
      this.pending = Colors.grey,
      this.onPending = Colors.white});
}

extension ThemeDataExtensions on ThemeData {
  static final Map<InputDecorationTheme, OwnThemeFields> _own = {};

  void addOwn(OwnThemeFields own) {
    _own[inputDecorationTheme] = own;
  }

  static OwnThemeFields? empty;

  OwnThemeFields own() {
    var o = _own[inputDecorationTheme];
    if (o == null) {
      empty ??= const OwnThemeFields();
      o = empty;
    }
    return o!;
  }
}
