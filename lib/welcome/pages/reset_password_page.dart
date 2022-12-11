import 'package:flutter/material.dart';
import 'package:flutter_app/util/loading_button.dart';
import 'package:flutter_app/util/password_field.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        title: const Text("Reset password"),
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
              labelText: "Password",
              hintText: "Enter your new password",
              controller: passwordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your new password';
                } else if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                } else if (RegExp('[0-9]').hasMatch(value) == false) {
                  return 'Password must contain at least one number';
                } else if (RegExp('[A-Z]').hasMatch(value) == false) {
                  return 'Password must contain at least one uppercase letter';
                } else if (RegExp('[a-z]').hasMatch(value) == false) {
                  return 'Password must contain at least one lowercase letter';
                } else if (RegExp('[^A-z0-9]').hasMatch(value) == false) {
                  return 'Password must contain at least one special character';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            PasswordField(
              labelText: "Confirm password",
              hintText: "Re-enter your new password",
              controller: passwordConfirmationController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                } else if (value != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            LoadingButton(
              idleText: "Reset password",
              onPressed: onSubmit,
              state: _state,
            )
          ],
        ),
      ),
    );
  }
}
