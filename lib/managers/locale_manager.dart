import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'storage_manager.dart';

LocaleManager localeManager = LocaleManager();

class LocaleManager with ChangeNotifier {
  static const Locale defaultLocale = Locale('en');
  final List<Locale> supportedLocales = S.supportedLocales;
  late Locale currentLocale;

  Future<void> loadCurrentLocale() async {
    await storageManager.readData<String>('locale').then((String? value) {
      value ??= Platform.localeName.split('_').first;

      final Locale locale =
          supportedLocales.firstWhere((Locale element) => element.languageCode == value, orElse: () => defaultLocale);

      setCurrentLocale(locale);
    });
  }

  void setCurrentLocale(Locale? locale) {
    if (locale == null) return;

    currentLocale = locale;
    storageManager.saveData('locale', locale.languageCode);
    notifyListeners();
  }

  String formatDate(DateTime dateTime) {
    return DateFormat.yMd(currentLocale.languageCode).format(dateTime);
  }

  String formatTime(DateTime dateTime) {
    return DateFormat.Hm(currentLocale.languageCode).format(dateTime);
  }

  String formatTimeOfDay(TimeOfDay time) {
    return formatTime(DateTime(0, 0, 0, time.hour, time.minute));
  }

  String formatDuration(Duration duration, {bool shouldPadHours = true}) {
    final String hours = duration.inHours.toString().padLeft(shouldPadHours ? 2 : 0, '0');
    final String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

extension LanguageName on Locale {
  String get languageName {
    switch (languageCode) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      default:
        return '';
    }
  }
}
