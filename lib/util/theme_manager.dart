import 'package:flutter/material.dart';
import 'package:flutter_app/util/storage_manager';
import 'own_theme_fields.dart';

ThemeManager themeManager = ThemeManager();

class ThemeManager with ChangeNotifier {
  final ThemeData lightTheme = ThemeData.light().copyWith(useMaterial3: true)
    ..addOwn(const OwnThemeFields(success: Colors.green, onSuccess: Colors.white));
  final ThemeData darkTheme = ThemeData.dark().copyWith(useMaterial3: true)
    ..addOwn(const OwnThemeFields(success: Colors.green, onSuccess: Colors.white));

  late ThemeMode themeMode;

  Future<void> loadTheme() async {
    await StorageManager.readData('themeMode').then((value) {
      switch (value) {
        case 'system':
          themeMode = ThemeMode.system;
          break;
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        default:
          themeMode = ThemeMode.system;
      }
      notifyListeners();
    });
  }

  void setTheme(ThemeMode value) {
    themeMode = value;
    StorageManager.saveData('themeMode', value.name);
    notifyListeners();
  }
}
