import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../util/factories/profile_factory.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    SupabaseManager.setCurrentProfile(ProfileFactory().generateFake());
    localeManager.currentLocale = const Locale('en');
  });

  await testMain();
}
