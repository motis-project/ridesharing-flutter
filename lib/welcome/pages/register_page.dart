import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/fields/email_field.dart';
import '../../util/fields/password_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageRegisterTitle),
      ),
      body: const Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: RegisterForm(),
          ),
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmationController = TextEditingController();
  ButtonState _state = ButtonState.idle;

  void onSubmit() async {
    if (_formKey.currentState!.validate()) {
      late final AuthResponse res;
      try {
        setState(() {
          _state = ButtonState.loading;
        });
        res = await supabaseClient.auth.signUp(
          password: passwordController.text,
          email: emailController.text,
          emailRedirectTo: 'io.supabase.flutter://login-callback/',
        );
      } on AuthException {
        fail();
        showSnackBar(S.of(context).failureSnackBar);
        return;
      }
      final User? user = res.user;

      if (user != null) {
        try {
          await supabaseClient.from('profiles').insert({
            'auth_id': user.id,
            'email': user.email,
            'username': usernameController.text,
          });
        } on PostgrestException {
          fail();
          // TODO: Show error if user exists already?
          // if (e.message.contains('duplicate key value violates unique constraint "users_email_key"')) {
          if (mounted) showSnackBar(S.of(context).failureSnackBar);
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _state = ButtonState.success;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).pageRegisterSuccess),
            duration: Duration(seconds: double.infinity.toInt()),
          ));
        }
      }
    } else {
      fail();
    }
  }

  void showSnackBar(String text) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
    ));
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
    emailController.dispose();
    usernameController.dispose();
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
            EmailField(controller: emailController),
            const SizedBox(height: 15),
            TextFormField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: S.of(context).pageRegisterUsername,
                hintText: S.of(context).pageRegisterUsernameHint,
              ),
              controller: usernameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).pageRegisterUsernameValidateEmpty;
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            PasswordField(
              labelText: S.of(context).formPassword,
              hintText: S.of(context).formPasswordHint,
              controller: passwordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).formPasswordValidateEmpty;
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
              hintText: S.of(context).formPasswordConfirmHint,
              controller: passwordConfirmationController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).formPasswordConfirmValidateEmpty;
                } else if (value != passwordController.text) {
                  return S.of(context).formPasswordConfirmValidateMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            Hero(
              tag: "RegisterButton",
              transitionOnUserGestures: true,
              child: LoadingButton(
                idleText: S.of(context).pageRegisterButtonCreate,
                successText: S.of(context).pageRegisterButtonCreated,
                onPressed: onSubmit,
                state: _state,
              ),
            )
          ],
        ),
      ),
    );
  }
}
