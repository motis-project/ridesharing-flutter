import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/fields/password_field.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
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
    supabaseManager.supabaseClient.auth.getSessionFromUrl(
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
    final Finder passwordFieldFinder = find.byKey(PasswordField.passwordFieldKey);
    final Finder passwordConfirmFieldFinder = find.byKey(PasswordField.passwordConfirmationFieldKey);
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

      final PasswordField passwordField = tester.widget(
        find.ancestor(of: passwordFieldFinder, matching: find.byType(PasswordField)),
      );

      expect(passwordField.validateSecurity, isTrue);
    });

    testWidgets('Validates the password confirmation', (WidgetTester tester) async {
      await pumpMaterial(tester, ResetPasswordPage(onPasswordReset: onPasswordReset));
      await tester.enterText(passwordFieldFinder, 'abc&EFG0');

      final PasswordField passwordConfirmationField = tester.widget(
        find.ancestor(of: passwordConfirmFieldFinder, matching: find.byType(PasswordField)),
      );

      expect(passwordConfirmationField.originalPasswordController!.text, 'abc&EFG0');
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

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, ResetPasswordPage(onPasswordReset: onPasswordReset));
    });
  });
}
