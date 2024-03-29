import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../util/own_theme_fields.dart';
import 'storage_manager.dart';

ThemeManager themeManager = ThemeManager();

class ThemeManager with ChangeNotifier {
  final ThemeData lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    colorScheme: const ColorScheme.light().copyWith(
      error: const Color(0xffd32f2f),
    ),
    appBarTheme: ThemeData.light().appBarTheme.copyWith(
          backgroundColor: ThemeData.light().scaffoldBackgroundColor,
        ),
    dividerTheme: ThemeData.light().dividerTheme.copyWith(
          color: Colors.grey.withOpacity(0.5),
        ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: ThemeData.light().hintColor),
    ),
  )..addOwn(const OwnThemeFields());
  final ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark().copyWith(
      error: const Color(0xffd32f2f),
    ),
    chipTheme: ThemeData.dark().chipTheme.copyWith(
          selectedColor: ThemeData.dark().highlightColor,
        ),
    appBarTheme: ThemeData.dark().appBarTheme.copyWith(
          backgroundColor: ThemeData.dark().scaffoldBackgroundColor,
        ),
    dividerTheme: ThemeData.dark().dividerTheme.copyWith(
          color: Colors.grey.withOpacity(0.5),
        ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: ThemeData.dark().hintColor),
    ),
  )..addOwn(const OwnThemeFields(onSuccess: Colors.black, onWarning: Colors.black));

  late ThemeMode currentThemeMode;

  Future<void> loadTheme() async {
    await storageManager.readData<String?>('themeMode').then((String? value) {
      switch (value) {
        case 'system':
          currentThemeMode = ThemeMode.system;
          break;
        case 'light':
          currentThemeMode = ThemeMode.light;
          break;
        case 'dark':
          currentThemeMode = ThemeMode.dark;
          break;
        default:
          currentThemeMode = ThemeMode.system;
      }
      notifyListeners();
    });
  }

  void setTheme(ThemeMode? value) {
    if (value == null) return;

    currentThemeMode = value;
    storageManager.saveData('themeMode', value.name);
    notifyListeners();
  }
}

extension ThemeModeName on ThemeMode {
  String getName(BuildContext context) {
    switch (this) {
      case ThemeMode.system:
        return S.of(context).pageAccountThemesSystem;
      case ThemeMode.light:
        return S.of(context).pageAccountThemesLight;
      case ThemeMode.dark:
        return S.of(context).pageAccountThemesDark;
    }
  }
}
