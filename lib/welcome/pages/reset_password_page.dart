import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/supabase.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageResetPasswordTitle),
      ),
      body: const Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: ResetPasswordForm(),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final passwordConfirmationController = TextEditingController();
  ButtonState _state = ButtonState.idle;

  void onSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _state = ButtonState.loading;
      });

      UserAttributes newAttributes = UserAttributes(password: passwordController.text);
      await supabaseClient.auth.updateUser(newAttributes);
      // will be redirected to login screen if successful (onAuthStateChange)
    } else {
      fail();
    }
  }

  void fail() async {
    setState(() {
      _state = ButtonState.fail;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _state = ButtonState.idle;
    });
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
      absorbing: _state == ButtonState.loading || _state == ButtonState.success,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            PasswordField(
              labelText: S.of(context).formPassword,
              hintText: S.of(context).pageResetPasswordHint,
              controller: passwordController,
              validator: (value) {
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
              validator: (value) {
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
              state: _state,
            )
          ],
        ),
      ),
    );
  }
}
