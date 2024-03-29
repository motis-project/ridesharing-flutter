import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/main.dart';
import 'package:motis_mitfahr_app/main_app.dart';
import 'package:motis_mitfahr_app/managers/firebase_manager.dart';
import 'package:motis_mitfahr_app/managers/locale_manager.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/managers/theme_manager.dart';
import 'package:motis_mitfahr_app/welcome/pages/reset_password_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/welcome_page.dart';

import 'test_util/factories/profile_factory.dart';
import 'test_util/mocks/mock_server.dart';
import 'test_util/mocks/request_processor.dart';
import 'test_util/mocks/request_processor.mocks.dart';
import 'test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    MockServer.setProcessor(processor);
    await firebaseManager.initialize(name: 'test');
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
      'created_at': '2021-09-01T00:00:00.000',
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

      //Mocking message request from Homepage
      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/messages'),
      ).thenReturnJson([]);

      //Mocking ride_event request from Homepage
      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/ride_events'),
      ).thenReturnJson([]);

      //Mocking rides request from Homepage
      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/rides'),
      ).thenReturnJson([]);

      //Mocking drives request from Homepage
      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/drives'),
      ).thenReturnJson([]);
    });

    Future<void> setSession() async {
      whenRequest(
        processor,
        urlMatcher: equals('/auth/v1/token?grant_type=refresh_token'),
        bodyMatcher: equals({'refresh_token': 'my_refresh_token'}),
        methodMatcher: equals('POST'),
      ).thenReturnJson(responseHash);
      await supabaseManager.supabaseClient.auth.setSession('my_refresh_token');
      await supabaseManager.reloadCurrentProfile();
    }

    setUp(() {
      supabaseManager.currentProfile = null;
      supabaseManager.supabaseClient.auth.signOut();
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

    testWidgets('It shows MainApp after signing in when user is not blocked', (WidgetTester tester) async {
      await pumpMaterial(tester, const AuthApp());

      expect(find.byType(WelcomePage), findsOneWidget);

      whenRequest(
        processor,
        urlMatcher: equals('/auth/v1/token?grant_type=password'),
        bodyMatcher: equals({'email': 'motismitfahrapp@gmail.com', 'password': '?Pass123word'}),
        methodMatcher: equals('POST'),
      ).thenReturnJson(responseHash);

      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/is_blocked')).thenReturnJson(false);

      // Sending AuthChangeEvent.signedIn
      await supabaseManager.supabaseClient.auth.signInWithPassword(
        email: 'motismitfahrapp@gmail.com',
        password: '?Pass123word',
      );

      await tester.pump();

      expect(find.byType(MainApp), findsOneWidget);
    });

    testWidgets('It logs user out again after signing in when user is blocked', (WidgetTester tester) async {
      await pumpMaterial(tester, const AuthApp());

      expect(find.byType(WelcomePage), findsOneWidget);

      whenRequest(
        processor,
        urlMatcher: equals('/auth/v1/token?grant_type=password'),
        bodyMatcher: equals({'email': 'motismitfahrapp@gmail.com', 'password': '?Pass123word'}),
        methodMatcher: equals('POST'),
      ).thenReturnJson(responseHash);

      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/is_blocked')).thenReturnJson(true);

      // Sending AuthChangeEvent.signedIn
      await supabaseManager.supabaseClient.auth.signInWithPassword(
        email: 'motismitfahrapp@gmail.com',
        password: '?Pass123word',
      );

      await tester.pump();

      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('It shows WelcomePage after signing out', (WidgetTester tester) async {
      await setSession();

      await pumpMaterial(tester, const AuthApp());

      expect(find.byType(MainApp), findsOneWidget);

      // Sending AuthChangeEvent.signedOut
      await supabaseManager.supabaseClient.auth.signOut();

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

      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/is_blocked')).thenReturnJson(false);

      await supabaseManager.supabaseClient.auth.getSessionFromUrl(
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
  });
}
