import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/fields/email_field.dart';
import 'package:motis_mitfahr_app/util/fields/password_field.dart';
import 'package:motis_mitfahr_app/welcome/pages/forgot_password_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/login_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/register_page.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  const String email = 'motismitfahrapp@gmail.com';
  const String password = 'abc&EFG0';

  setUpAll(() async {
    MockServer.setProcessor(processor);
    supabaseManager.currentProfile = null;
  });

  group('LoginPage', () {
    final Finder emailFieldFinder = find.descendant(
      of: find.byType(EmailField),
      matching: find.byType(TextFormField),
    );
    final Finder passwordFieldFinder = find.byKey(PasswordField.passwordFieldKey);
    final Finder loginButtonFinder = find.byType(LoadingButton);

    testWidgets('Shows the login page', (WidgetTester tester) async {
      await pumpMaterial(tester, const LoginPage());

      final Finder loginFormFinder = find.byType(LoginForm);
      final LoginFormState formState = tester.state(loginFormFinder);

      expect(loginFormFinder, findsOneWidget);
      expect(formState.buttonState, ButtonState.idle);
      expect(find.byType(EmailField), findsOneWidget);
    });

    testWidgets('Validates the password (not so strictly)', (WidgetTester tester) async {
      await pumpMaterial(tester, const LoginPage());

      final PasswordField passwordField = tester.widget(find.byType(PasswordField));

      expect(passwordField.validateSecurity, isFalse);
    });

    testWidgets('Navigates to the forgotPassword page', (WidgetTester tester) async {
      await pumpMaterial(tester, const LoginPage());

      await tester.enterText(emailFieldFinder, email);

      await tester.tap(find.byKey(const Key('loginForgotPasswordButton')));
      await tester.pumpAndSettle();

      final Finder forgotPasswordPageFinder = find.byType(ForgotPasswordPage);
      expect(forgotPasswordPageFinder, findsOneWidget);
      final ForgotPasswordPage forgotPasswordPageState = tester.widget(forgotPasswordPageFinder);
      expect(forgotPasswordPageState.initialEmail, email);
    });

    testWidgets('Navigates to the register page', (WidgetTester tester) async {
      await pumpMaterial(tester, const LoginPage());

      await tester.tap(find.byKey(const Key('loginNoAccountButton')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    group('LoginButton', () {
      const String email = 'motismitfahrapp@gmail.com';
      const String authId = '123';

      Future<void> fillForm(WidgetTester tester, {bool valid = true}) async {
        await tester.enterText(emailFieldFinder, valid ? email : '123noemail');
        await tester.enterText(passwordFieldFinder, password);
      }

      ProcessorPostExpectation whenLoginRequest() => whenRequest(
            processor,
            urlMatcher: startsWith('/auth/v1/token'),
            bodyMatcher: containsPair('email', 'motismitfahrapp@gmail.com'),
            methodMatcher: equals('POST'),
          );

      Future<void> expectSupabaseFailBehavior(WidgetTester tester) async {
        await tester.tap(loginButtonFinder);
        await tester.pump();

        final LoginFormState loginFormState = tester.state(find.byType(LoginForm));
        expect(loginFormState.buttonState, ButtonState.fail);

        await tester.pump(const Duration(seconds: 2, milliseconds: 100));

        expect(loginFormState.buttonState, ButtonState.idle);
      }

      testWidgets('Fails if form is not filled validly', (WidgetTester tester) async {
        await pumpMaterial(tester, const LoginPage());

        await fillForm(tester, valid: false);

        await tester.tap(loginButtonFinder);
        await tester.pump();

        final FormFieldState emailField = tester.state(emailFieldFinder);
        expect(emailField.hasError, isTrue);
      });

      testWidgets('Fails if supabase responds with generic error', (WidgetTester tester) async {
        await pumpMaterial(tester, const LoginPage());

        await fillForm(tester);

        whenLoginRequest().thenReturnJson(
          {
            'error': 'Generic error',
          },
          statusCode: 400,
        );

        await expectSupabaseFailBehavior(tester);

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Fails if supabase responds with credentials error', (WidgetTester tester) async {
        await pumpMaterial(tester, const LoginPage());

        await fillForm(tester);

        whenLoginRequest().thenReturnJson(
          {
            'error': 'Wrong credentials.',
          },
          statusCode: 400,
        );

        await expectSupabaseFailBehavior(tester);

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Fails if supabase responds with other error', (WidgetTester tester) async {
        await pumpMaterial(tester, const LoginPage());

        await fillForm(tester);

        whenLoginRequest().thenReturnJson(
          {
            'error': 'Other error.',
          },
          statusCode: 500,
        );

        await expectSupabaseFailBehavior(tester);

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Is successful if everything worked', (WidgetTester tester) async {
        await pumpMaterial(tester, const LoginPage());

        await fillForm(tester);

        whenLoginRequest().thenReturnJson({
          'id': authId,
          'app_metadata': {},
          'user_metadata': {},
          'aud': 'public',
          'created_at': DateTime.now().toIso8601String(),
          'email': email,
        });

        await tester.tap(loginButtonFinder);
        await tester.pump();

        final LoginFormState loginFormState = tester.state(find.byType(LoginForm));
        expect(loginFormState.buttonState, ButtonState.success);
      });
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, const LoginPage());
    });
  });
}
