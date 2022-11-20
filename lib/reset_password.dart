import 'package:flutter/material.dart';
import 'package:flutter_app/password_field.dart';
import 'package:flutter_app/submit_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
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
        ))));
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

  void onSubmit() async {
    if (_formKey.currentState!.validate()) {
      //TODO
      onPasswordReset();
    }
  }

  void onPasswordReset() {
    //Navigator.of(context).pop();
    // TODO
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
            SubmitButton(
              text: "Reset password",
              onPressed: onSubmit,
            )
          ],
        ));
  }
}
