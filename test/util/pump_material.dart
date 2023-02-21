import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';

Future<void> pumpMaterial(
  WidgetTester tester,
  Widget widget, {
  NavigatorObserver? navigatorObserver,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: localeManager.supportedLocales,
      locale: localeManager.currentLocale,
      navigatorObservers: navigatorObserver == null ? [] : [navigatorObserver],
      home: widget,
    ),
  );
}

Future<void> pumpScaffold(WidgetTester tester, Widget widget) async {
  await pumpMaterial(tester, Scaffold(body: widget));
}

Future<void> pumpForm(WidgetTester tester, Widget widget, {required Key formKey}) async {
  await pumpScaffold(tester, Form(key: formKey, child: widget));
}
