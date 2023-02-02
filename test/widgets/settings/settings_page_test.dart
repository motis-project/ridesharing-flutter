import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/about_page.dart';
import 'package:motis_mitfahr_app/account/pages/account_page.dart';
import 'package:motis_mitfahr_app/account/pages/help_page.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/util/theme_manager.dart';

import '../../util/factories/profile_factory.dart';
import '../../util/mocks/navigator_observer.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  final MockNavigatorObserver navigatorObserver = MockNavigatorObserver();
  final Profile user = ProfileFactory().generateFake();

  setUp(() async {
    SupabaseManager.setCurrentProfile(user);
  });

  Future<void> loadPageAndTapKey(WidgetTester tester, Key key) async {
    await pumpMaterial(tester, const AccountPage(), navigatorObserver: navigatorObserver);

    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('shows ProfileWidget of current User', (WidgetTester tester) async {
    await pumpMaterial(tester, const AccountPage());

    final Finder profileWidgetFinder = find.byType(ProfileWidget);
    expect(profileWidgetFinder, findsOneWidget);

    final ProfileWidget profileWidget = tester.widget(profileWidgetFinder);
    expect(profileWidget.profile, user);
    expect(profileWidget.withHero, true);
    expect(profileWidget.isTappable, true); //tappable to open profile page
  });

  testWidgets('change Language', (WidgetTester tester) async {
    localeManager.setCurrentLocale(const Locale('de'));
    await loadPageAndTapKey(tester, const Key('accountLanguage'));

    expect(localeManager.currentLocale, const Locale('de'));

    //shows all locales
    final Finder locales = find.byType(RadioListTile<Locale>);
    expect(locales, findsNWidgets(localeManager.supportedLocales.length));

    //current Locale is selected
    expect(tester.widget<RadioListTile<Locale>>(locales.first).groupValue, localeManager.currentLocale);

    //change locale
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(localeManager.currentLocale, const Locale('en'));

    await tester.tap(find.byKey(const Key('okButtonLanguage')));
    await tester.pumpAndSettle();

    verify(navigatorObserver.didPop(any, any)).called(1);
  });
  testWidgets('change Theme', (WidgetTester tester) async {
    themeManager.setTheme(ThemeMode.values.first);

    await loadPageAndTapKey(tester, const Key('accountTheme'));

    //shows all themes
    final Finder themes = find.byType(RadioListTile<ThemeMode>);
    expect(themes, findsNWidgets(ThemeMode.values.length));

    //current theme is selected
    expect(tester.widget<RadioListTile<ThemeMode>>(themes.first).groupValue, themeManager.currentThemeMode);

    //change theme
    await tester.tap(themes.last);
    await tester.pumpAndSettle();

    expect(themeManager.currentThemeMode, ThemeMode.values.last);

    await tester.tap(find.byKey(const Key('okButtonDesign')));
    await tester.pumpAndSettle();

    verify(navigatorObserver.didPop(any, any)).called(1);
  });

  testWidgets('can navigate to help Page', (WidgetTester tester) async {
    await loadPageAndTapKey(tester, const Key('accountHelp'));

    expect(find.byType(HelpPage), findsOneWidget);
  });

  testWidgets('can navigate to about Page', (WidgetTester tester) async {
    await loadPageAndTapKey(tester, const Key('accountAbout'));

    expect(find.byType(AboutPage), findsOneWidget);
  });
}
