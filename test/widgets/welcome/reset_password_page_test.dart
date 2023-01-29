import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/welcome/pages/reset_password_page.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

class MockFunction extends Mock {
  void call();
}

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  final MockFunction onPasswordReset = MockFunction();
  const String password = 'abc&EFG0';

  const Map<String, dynamic> userHash = {
    'id': 'id',
    'app_metadata': {},
    'user_metadata': {},
    'aud': 'public',
    'created_at': '2021-09-01T00:00:00.000Z',
    'email': 'email',
  };

  void setSessionByUrl() {
    whenRequest(
      processor,
      urlMatcher: equals('/auth/v1/user?'),
      methodMatcher: equals('GET'),
    ).thenReturnJson(userHash);
    SupabaseManager.supabaseClient.auth.getSessionFromUrl(
      Uri(host: 'localhost', port: 3000, queryParameters: {
        'access_token': 'access_token',
        'expires_in': '3600',
        'refresh_token': 'refresh_token',
        'token_type': 'token_type',
      }),
    );
  }

  setUpAll(() async {
    MockServer.setProcessor(processor);
    setSessionByUrl();
  });

  group('ResetPasswordPage', () {
    final Finder passwordFieldFinder = find.descendant(
      of: find.byKey(const Key('resetPasswordPasswordField')),
      matching: find.byType(TextFormField),
    );
    final Finder passwordConfirmFieldFinder = find.descendant(
      of: find.byKey(const Key('resetPasswordPasswordConfirmField')),
      matching: find.byType(TextFormField),
    );
    final Finder resetPasswordButtonFinder = find.byType(LoadingButton);

    testWidgets('Shows the password form', (WidgetTester tester) async {
      await pumpMaterial(tester, ResetPasswordPage(onPasswordReset: onPasswordReset));

      final Finder resetPasswordFormFinder = find.byType(ResetPasswordForm);
      final ResetPasswordFormState formState = tester.state(resetPasswordFormFinder);

      expect(formState.buttonState, ButtonState.idle);

      expect(passwordFieldFinder, findsOneWidget);
      expect(passwordConfirmFieldFinder, findsOneWidget);
    });

    testWidgets('Validates the password', (WidgetTester tester) async {
      await pumpMaterial(tester, ResetPasswordPage(onPasswordReset: onPasswordReset));

      final ResetPasswordFormState formState = tester.state(find.byType(ResetPasswordForm));

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
      await pumpMaterial(tester, ResetPasswordPage(onPasswordReset: onPasswordReset));

      final ResetPasswordFormState formState = tester.state(find.byType(ResetPasswordForm));
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

    group('submitting the form', () {
      testWidgets('Fails if form is not filled validly', (WidgetTester tester) async {
        await pumpMaterial(tester, ResetPasswordPage(onPasswordReset: onPasswordReset));

        await tester.tap(resetPasswordButtonFinder);
        await tester.pump();

        final FormFieldState passwordField = tester.state(passwordFieldFinder);
        expect(passwordField.hasError, isTrue);

        verifyNever(onPasswordReset());
      });

      testWidgets('Resets password if form filled validly', (WidgetTester tester) async {
        await pumpMaterial(tester, ResetPasswordPage(onPasswordReset: onPasswordReset));

        await tester.enterText(passwordFieldFinder, password);
        await tester.enterText(passwordConfirmFieldFinder, password);

        whenRequest(
          processor,
          urlMatcher: equals('/auth/v1/user?'),
          methodMatcher: equals('PUT'),
          bodyMatcher: equals({'password': password}),
        ).thenReturnJson(userHash);

        await tester.tap(resetPasswordButtonFinder);
        await tester.pump();

        final ResetPasswordFormState resetPasswordFormState = tester.state(find.byType(ResetPasswordForm));
        expect(resetPasswordFormState.buttonState, ButtonState.loading);

        verify(onPasswordReset()).called(1);
      });
    });
  });
}
