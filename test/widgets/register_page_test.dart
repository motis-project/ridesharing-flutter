import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/welcome/pages/after_registration_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/register_page.dart';
import 'package:progress_state_button/progress_button.dart';

import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  const String username = 'motismitfahrapp';
  const String email = 'motismitfahrapp@gmail.com';
  const String password = 'abc&EFG0';

  setUpAll(() async {
    MockServer.setProcessor(processor);
    SupabaseManager.setCurrentProfile(null);
  });

  group('RegisterPage', () {
    final Finder usernameFieldFinder = find.byKey(const Key('registerUsernameField'));
    final Finder emailFieldFinder = find.descendant(
      of: find.byKey(const Key('registerEmailField')),
      matching: find.byType(TextFormField),
    );
    final Finder passwordFieldFinder = find.descendant(
      of: find.byKey(const Key('registerPasswordField')),
      matching: find.byType(TextFormField),
    );
    final Finder passwordConfirmFieldFinder = find.descendant(
      of: find.byKey(const Key('registerPasswordConfirmField')),
      matching: find.byType(TextFormField),
    );
    final Finder registerButtonFinder = find.byType(LoadingButton);

    testWidgets('Shows the register page', (WidgetTester tester) async {
      await pumpMaterial(tester, const RegisterPage());

      final Finder registerFormFinder = find.byType(RegisterForm);
      final RegisterFormState formState = tester.state(registerFormFinder);

      expect(formState.buttonState, ButtonState.idle);
    });

    testWidgets('Validates the email', (WidgetTester tester) async {
      await pumpMaterial(tester, const RegisterPage());

      final RegisterFormState formState = tester.state(find.byType(RegisterForm));

      final FormFieldState emailField = tester.state(emailFieldFinder);

      // Not validated yet, so no error
      expect(emailField.hasError, isFalse);

      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(emailField.hasError, isTrue);

      await tester.enterText(emailFieldFinder, '123noemail');
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Not real email, so error
      expect(emailField.hasError, isTrue);

      await tester.enterText(emailFieldFinder, email);
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Real email, so no error
      expect(emailField.hasError, isFalse);
    });

    testWidgets('Validates the username', (WidgetTester tester) async {
      await pumpMaterial(tester, const RegisterPage());

      final RegisterFormState formState = tester.state(find.byType(RegisterForm));

      final FormFieldState usernameField = tester.state(usernameFieldFinder);

      // Not validated yet, so no error
      expect(usernameField.hasError, isFalse);

      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(usernameField.hasError, isTrue);

      await tester.enterText(usernameFieldFinder, 'a');

      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Not empty, so no error
      expect(usernameField.hasError, isFalse);

      await tester.enterText(usernameFieldFinder, 'a' * Profile.maxUsernameLength * 2);
      expect(formState.usernameController.text.length, Profile.maxUsernameLength);
    });

    testWidgets('Validates the password', (WidgetTester tester) async {
      await pumpMaterial(tester, const RegisterPage());

      final RegisterFormState formState = tester.state(find.byType(RegisterForm));

      final FormFieldState passwordField = tester.state(passwordFieldFinder);

      // Not validated yet, so no error
      expect(passwordField.hasError, isFalse);

      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdefg');
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Too short, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdefgh');
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No number, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdefg0');
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No capital letters, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'ABCDEFG0');
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No lower letters, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdEFG0');
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No special, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, password);
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      expect(passwordField.hasError, isFalse);
    });

    testWidgets('Validates the password confirmation', (WidgetTester tester) async {
      await pumpMaterial(tester, const RegisterPage());

      final RegisterFormState formState = tester.state(find.byType(RegisterForm));
      await tester.enterText(passwordFieldFinder, password);

      final FormFieldState passwordConfirmationField = tester.state(passwordConfirmFieldFinder);

      // Not validated yet, so no error
      expect(passwordConfirmationField.hasError, isFalse);

      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(passwordConfirmationField.hasError, isTrue);

      await tester.enterText(passwordConfirmFieldFinder, '${password}a');
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Not the same, so error
      expect(passwordConfirmationField.hasError, isTrue);

      await tester.enterText(passwordConfirmFieldFinder, password);
      formState.formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Same, so no error
      expect(passwordConfirmationField.hasError, isFalse);
    });

    group('RegisterButton', () {
      const String authId = '123';

      Future<void> fillForm(WidgetTester tester, {bool valid = true}) async {
        await tester.enterText(emailFieldFinder, email);
        await tester.enterText(usernameFieldFinder, username);
        await tester.enterText(passwordFieldFinder, 'abc&EFG0');
        await tester.enterText(passwordConfirmFieldFinder, valid ? 'abc&EFG0' : 'notTheSame');
      }

      ProcessorPostExpectation whenSignupRequest() => whenRequest(
            processor,
            urlMatcher: startsWith('/auth/v1/signup'),
            bodyMatcher: containsPair('email', 'motismitfahrapp@gmail.com'),
            methodMatcher: equals('POST'),
          );

      void respondToSignupRequestCorrectly() {
        whenSignupRequest().thenReturnJson({
          'id': authId,
          'app_metadata': {},
          'user_metadata': {},
          'aud': 'public',
          'created_at': DateTime.now().toIso8601String(),
          'email': email,
        });
      }

      Future<void> expectSupabaseFailBehavior(WidgetTester tester) async {
        await tester.tap(registerButtonFinder);
        await tester.pump();

        final RegisterFormState registerFormState = tester.state(find.byType(RegisterForm));
        expect(registerFormState.buttonState, ButtonState.fail);

        await tester.pump(const Duration(seconds: 2, milliseconds: 100));

        expect(registerFormState.buttonState, ButtonState.idle);
      }

      testWidgets('Fails if form is not filled validly', (WidgetTester tester) async {
        await pumpMaterial(tester, const RegisterPage());

        await fillForm(tester, valid: false);

        await tester.tap(registerButtonFinder);
        await tester.pump();

        final FormFieldState passwordConfirmationField = tester.state(passwordConfirmFieldFinder);
        expect(passwordConfirmationField.hasError, isTrue);
      });

      testWidgets('Fails if supabase responds with error', (WidgetTester tester) async {
        await pumpMaterial(tester, const RegisterPage());

        await fillForm(tester);

        whenSignupRequest().thenReturnJson(
          {
            'error': 'An error occurred',
          },
          statusCode: 400,
        );

        await expectSupabaseFailBehavior(tester);
      });

      testWidgets('Fails if supabase does not respond with correctly built object', (WidgetTester tester) async {
        await pumpMaterial(tester, const RegisterPage());

        await fillForm(tester);

        whenSignupRequest().thenReturnJson({'something': 'else'});

        await expectSupabaseFailBehavior(tester);
      });

      testWidgets('Fails if register is successful, but user already exists in table', (WidgetTester tester) async {
        await pumpMaterial(tester, const RegisterPage());

        await fillForm(tester);

        respondToSignupRequestCorrectly();
        whenRequest(
          processor,
          urlMatcher: equals('/rest/v1/profiles'),
          bodyMatcher: equals({
            'auth_id': authId,
            'email': email,
            'username': username,
          }),
          methodMatcher: equals('POST'),
        ).thenReturnJson(
          {
            'error': 'An error occurred',
          },
          statusCode: 400,
        );

        await expectSupabaseFailBehavior(tester);
      });

      testWidgets('Is successful if everything worked', (WidgetTester tester) async {
        await pumpMaterial(tester, const RegisterPage());

        await fillForm(tester);

        respondToSignupRequestCorrectly();
        whenRequest(
          processor,
          urlMatcher: equals('/rest/v1/profiles'),
          bodyMatcher: equals({
            'auth_id': authId,
            'email': email,
            'username': username,
          }),
          methodMatcher: equals('POST'),
        ).thenReturnJson(
          {
            'data': "{'id': '123'}",
            'status': 200,
          },
        );

        await tester.tap(registerButtonFinder);

        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.byType(AfterRegistrationPage), findsOneWidget);
      });
    });
  });
}
