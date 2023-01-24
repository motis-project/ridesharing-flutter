import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/util/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/factories/profile_factory.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseManager.setCurrentProfile(ProfileFactory().generateFake());
    localeManager.currentLocale = const Locale('en');
    themeManager.setTheme(ThemeMode.light);
  });

  await testMain();
}
