import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/fields/password_field.dart';
import '../../util/supabase.dart';

class ResetPasswordPage extends StatefulWidget {
  final Function() onPasswordReset;

  const ResetPasswordPage({super.key, required this.onPasswordReset});

  @override
  State<ResetPasswordPage> createState() => ResetPasswordPageState();
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageResetPasswordTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: ResetPasswordForm(onPasswordReset: widget.onPasswordReset),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  final Function() onPasswordReset;

  const ResetPasswordForm({super.key, required this.onPasswordReset});

  @override
  State<ResetPasswordForm> createState() => ResetPasswordFormState();
}

class ResetPasswordFormState extends State<ResetPasswordForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmationController = TextEditingController();
  ButtonState buttonState = ButtonState.idle;

  Future<void> onSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      buttonState = ButtonState.loading;
    });

    final UserAttributes newAttributes = UserAttributes(password: passwordController.text);
    await SupabaseManager.supabaseClient.auth.updateUser(newAttributes);

    // Will redirect to login screen if successful
    widget.onPasswordReset();
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: buttonState == ButtonState.loading || buttonState == ButtonState.success,
      child: Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            PasswordField(
              labelText: S.of(context).formPassword,
              hintText: S.of(context).pageResetPasswordHint,
              controller: passwordController,
              key: const Key('resetPasswordPasswordField'),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).pageResetPasswordValidateEmpty;
                } else if (value.length < 8) {
                  return S.of(context).formPasswordValidateMinLength;
                } else if (RegExp('[0-9]').hasMatch(value) == false) {
                  return S.of(context).formPasswordValidateMinLength;
                } else if (RegExp('[A-Z]').hasMatch(value) == false) {
                  return S.of(context).formPasswordValidateUppercase;
                } else if (RegExp('[a-z]').hasMatch(value) == false) {
                  return S.of(context).formPasswordValidateLowercase;
                } else if (RegExp('[^A-z0-9]').hasMatch(value) == false) {
                  return S.of(context).formPasswordValidateSpecial;
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            PasswordField(
              labelText: S.of(context).formPasswordConfirm,
              hintText: S.of(context).pageResetPasswordConfirmHint,
              controller: passwordConfirmationController,
              key: const Key('resetPasswordPasswordConfirmField'),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).pageResetPasswordConfirmValidateEmpty;
                } else if (value != passwordController.text) {
                  return S.of(context).formPasswordConfirmValidateMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            LoadingButton(
              idleText: S.of(context).pageResetPasswordButtonReset,
              onPressed: onSubmit,
              state: buttonState,
            )
          ],
        ),
      ),
    );
  }
}
