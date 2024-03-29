import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/about_page.dart';
import 'package:motis_mitfahr_app/account/pages/account_page.dart';
import 'package:motis_mitfahr_app/account/pages/help_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_widget.dart';
import 'package:motis_mitfahr_app/managers/locale_manager.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/managers/theme_manager.dart';

import '../../test_util/factories/profile_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/navigator_observer.mocks.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final MockNavigatorObserver navigatorObserver = MockNavigatorObserver();
  final Profile profile = ProfileFactory().generateFake();
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
    reset(processor);
    supabaseManager.currentProfile = profile;
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
    expect(profileWidget.profile, profile);
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

  testWidgets('can navigate to Profile Page', (WidgetTester tester) async {
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
        .thenReturnJson(profile.toJsonForApi());

    await pumpMaterial(tester, const AccountPage(), navigatorObserver: navigatorObserver);
    await tester.pump();

    await tester.tap(find.byType(ProfileWidget));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);

    await tester.pageBack();
  });

  testWidgets('can navigate to Help Page', (WidgetTester tester) async {
    await loadPageAndTapKey(tester, const Key('accountHelp'));

    expect(find.byType(HelpPage), findsOneWidget);
  });

  testWidgets('can navigate to About Page', (WidgetTester tester) async {
    await loadPageAndTapKey(tester, const Key('accountAbout'));

    expect(find.byType(AboutPage), findsOneWidget);
  });

  testWidgets('Accessibility', (WidgetTester tester) async {
    await expectMeetsAccessibilityGuidelines(tester, const AccountPage());
    await expectMeetsAccessibilityGuidelines(tester, const HelpPage());
  });
}
