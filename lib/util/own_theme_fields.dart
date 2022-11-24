import 'package:flutter/material.dart';

class OwnThemeFields {
  final Color success;
  final Color onSuccess;

  const OwnThemeFields(
      {this.success = Colors.green, this.onSuccess = Colors.white});

  factory OwnThemeFields.empty() {
    return const OwnThemeFields(success: Colors.green, onSuccess: Colors.white);
  }
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
      empty ??= OwnThemeFields.empty();
      o = empty;
    }
    return o!;
  }
}
