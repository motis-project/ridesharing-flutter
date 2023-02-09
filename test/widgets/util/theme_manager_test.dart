import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/storage_manager.dart';
import 'package:motis_mitfahr_app/util/theme_manager.dart';

void main() {
  //this is needed since the storageManage contains themeMode as a key by default for the tests.
  setUp(() => storageManager.deleteData('themeMode'));
  test('setTheme', () async {
    themeManager.currentThemeMode = ThemeMode.light;

    themeManager.setTheme(null);
    expect(themeManager.currentThemeMode, ThemeMode.light);
    final String? noTheme = await storageManager.readData('themeMode');
    expect(noTheme, null);

    themeManager.setTheme(ThemeMode.dark);
    expect(themeManager.currentThemeMode, ThemeMode.dark);
    final String theme = await storageManager.readData('themeMode');
    expect(theme, 'dark');
  });

  test('loadCurrentLocale', () async {
    await themeManager.loadTheme();
    //default when no locale is saved
    expect(themeManager.currentThemeMode, ThemeMode.system);

    storageManager.saveData('themeMode', 'dark');
    await themeManager.loadTheme();

    expect(themeManager.currentThemeMode, ThemeMode.dark);

    storageManager.saveData('themeMode', 'light');
    await themeManager.loadTheme();

    expect(themeManager.currentThemeMode, ThemeMode.light);

    storageManager.saveData('themeMode', 'system');
    await themeManager.loadTheme();

    expect(themeManager.currentThemeMode, ThemeMode.system);
  });
}
