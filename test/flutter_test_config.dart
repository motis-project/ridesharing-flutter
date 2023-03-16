import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/managers/locale_manager.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/managers/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_util/factories/profile_factory.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    supabaseManager.currentProfile = ProfileFactory().generateFake();
    localeManager.currentLocale = const Locale('en');
    themeManager.setTheme(ThemeMode.light);
  });

  await testMain();
}
