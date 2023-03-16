import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/managers/locale_manager.dart';
import 'package:motis_mitfahr_app/managers/theme_manager.dart';

Future<void> pumpMaterial(
  WidgetTester tester,
  Widget widget, {
  NavigatorObserver? navigatorObserver,
  ThemeData? themeData,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: localeManager.supportedLocales,
      locale: localeManager.currentLocale,
      navigatorObservers: navigatorObserver == null ? [] : [navigatorObserver],
      home: widget,
      theme: themeData,
    ),
  );
}

Future<void> pumpScaffold(WidgetTester tester, Widget widget) async {
  await pumpMaterial(tester, Scaffold(body: widget));
}

Future<void> pumpForm(WidgetTester tester, Widget widget, {required Key formKey}) async {
  await pumpScaffold(tester, Form(key: formKey, child: widget));
}

Future<void> expectMeetsAccessibilityGuidelines(WidgetTester tester, Widget widget,
    {bool checkTapTargets = true}) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  for (final ThemeData theme in [themeManager.lightTheme, themeManager.darkTheme]) {
    await pumpMaterial(tester, widget, themeData: theme);
    await tester.pump();

    if (checkTapTargets) {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }
  handle.dispose();
}
