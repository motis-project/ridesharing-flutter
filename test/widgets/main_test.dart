import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/main.dart';
import 'package:motis_mitfahr_app/main_app.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/util/theme_manager.dart';
import 'package:motis_mitfahr_app/welcome/pages/reset_password_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/welcome_page.dart';

import '../util/factories/profile_factory.dart';
import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  group('AppWrapper', () {
    testWidgets('It creates the app', (WidgetTester tester) async {
      await tester.pumpWidget(const AppWrapper());

      expect(find.byType(AppWrapper), findsOneWidget);

      // ignore: invalid_use_of_protected_member
      expect(localeManager.hasListeners, isTrue);
      localeManager.setCurrentLocale(const Locale('de'));
      // ignore: invalid_use_of_protected_member
      expect(themeManager.hasListeners, isTrue);
      themeManager.setTheme(ThemeMode.dark);

      final Finder materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);
      final MaterialApp app = materialApp.evaluate().first.widget as MaterialApp;
      expect(app.home.runtimeType, AuthApp);
      expect(app.darkTheme, themeManager.darkTheme);
    });
  });

  group('AuthApp', () {
    const Map<String, dynamic> userHash = {
      'id': 'id',
      'app_metadata': {},
      'user_metadata': {},
      'aud': 'public',
      'created_at': '2021-09-01T00:00:00.000Z',
      'email': 'email',
    };

    const Map<String, dynamic> responseHash = {
      'user': userHash,
      'access_token': 'my_access_token',
      'token_type': 'bearer',
    };

    setUpAll(() {
      // Mocking current user
      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).thenReturnJson(ProfileFactory().generateFake().toJsonForApi());

      // Mocking logout
      whenRequest(
        processor,
        urlMatcher: startsWith('/auth/v1/logout'),
        methodMatcher: equals('POST'),
      ).thenReturnJson('');
    });

    Future<void> setSession() async {
      whenRequest(
        processor,
        urlMatcher: equals('/auth/v1/token?grant_type=refresh_token'),
        bodyMatcher: equals({'refresh_token': 'my_refresh_token'}),
        methodMatcher: equals('POST'),
      ).thenReturnJson(responseHash);
      await SupabaseManager.supabaseClient.auth.setSession('my_refresh_token');
      await SupabaseManager.reloadCurrentProfile();
    }

    setUp(() {
      SupabaseManager.setCurrentProfile(null);
      SupabaseManager.supabaseClient.auth.signOut();
    });

    testWidgets('It shows Welcome when not logged in', (WidgetTester tester) async {
      await pumpMaterial(tester, const AuthApp());

      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('It shows MainApp when logged in', (WidgetTester tester) async {
      await setSession();

      await pumpMaterial(tester, const AuthApp());

      expect(find.byType(MainApp), findsOneWidget);
    });

    testWidgets('It shows MainApp after signing in', (WidgetTester tester) async {
      await pumpMaterial(tester, const AuthApp());

      expect(find.byType(WelcomePage), findsOneWidget);

      whenRequest(
        processor,
        urlMatcher: equals('/auth/v1/token?grant_type=password'),
        bodyMatcher: equals({'email': 'motismitfahrapp@gmail.com', 'password': '?Pass123word'}),
        methodMatcher: equals('POST'),
      ).thenReturnJson(responseHash);

      // Sending AuthChangeEvent.signedIn
      await SupabaseManager.supabaseClient.auth.signInWithPassword(
        email: 'motismitfahrapp@gmail.com',
        password: '?Pass123word',
      );

      await tester.pump();

      expect(find.byType(MainApp), findsOneWidget);
    });

    testWidgets('It shows WelcomePage after signing out', (WidgetTester tester) async {
      await setSession();

      await pumpMaterial(tester, const AuthApp());

      expect(find.byType(MainApp), findsOneWidget);

      // Sending AuthChangeEvent.signedOut
      await SupabaseManager.supabaseClient.auth.signOut();

      await tester.pump();

      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('It shows ResetPasswordPage after clicking deeplink', (WidgetTester tester) async {
      await pumpMaterial(tester, const AuthApp());

      whenRequest(
        processor,
        urlMatcher: equals('/auth/v1/user?'),
        methodMatcher: equals('GET'),
      ).thenReturnJson(userHash);

      await SupabaseManager.supabaseClient.auth.getSessionFromUrl(
        Uri(host: 'localhost', port: 3000, queryParameters: {
          'access_token': 'access_token',
          'expires_in': '3600',
          'refresh_token': 'refresh_token',
          'token_type': 'token_type',
          'type': 'recovery'
        }),
      );

      await tester.pump();

      final Finder resetPasswordPage = find.byType(ResetPasswordPage);
      expect(resetPasswordPage, findsOneWidget);
      final ResetPasswordPage page = resetPasswordPage.evaluate().first.widget as ResetPasswordPage;
      page.onPasswordReset();

      await tester.pump();

      expect(find.byType(MainApp), findsOneWidget);
    });

    // TODO: Write test case that checks the snackbar when email is invalid/expired
    // (only possible after merging the welcome tests because I need to return error from API)
  });
}
