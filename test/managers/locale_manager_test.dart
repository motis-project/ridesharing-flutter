import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/managers/locale_manager.dart';
import 'package:motis_mitfahr_app/managers/storage_manager.dart';

void main() {
  test('setCurrentLocale', () async {
    localeManager.currentLocale = const Locale('en');

    localeManager.setCurrentLocale(null);
    expect(localeManager.currentLocale, const Locale('en'));
    final String? noLocale = await storageManager.readData('locale');
    expect(noLocale, null);

    localeManager.setCurrentLocale(const Locale('de'));

    expect(localeManager.currentLocale, const Locale('de'));

    final String locale = await storageManager.readData('locale');
    expect(locale, 'de');
  });

  test('loadCurrentLocale', () async {
    await localeManager.loadCurrentLocale();
    //default when no locale is saved
    expect(localeManager.currentLocale, const Locale('en'));

    storageManager.saveData('locale', 'de');
    await localeManager.loadCurrentLocale();

    //locale that was saved
    expect(localeManager.currentLocale, const Locale('de'));
  });
}
