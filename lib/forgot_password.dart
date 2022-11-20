import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/own_theme_fields.dart';
import 'package:flutter_app/submit_button.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ""});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Reset password"),
        ),
        body: Center(
            child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: ForgotPasswordForm(
            initialEmail: widget.initialEmail,
          ),
        ))));
  }
}

class ForgotPasswordForm extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordForm({super.key, this.initialEmail = ""});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  ButtonState _state = ButtonState.idle;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  void onSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _state = ButtonState.loading;
      });
      //TODO
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _state = ButtonState.success;
      });
      await Future.delayed(const Duration(seconds: 2));
      onMailSent();
    } else {
      setState(() {
        _state = ButtonState.fail;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _state = ButtonState.idle;
      });
    }
  }

  void onMailSent() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing:
            _state == ButtonState.loading || _state == ButtonState.success,
        child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                ProgressButton.icon(iconedButtons: {
                  ButtonState.idle: IconedButton(
                      text: "Recovery mail",
                      icon: Icon(Icons.send,
                          color: Theme.of(context).colorScheme.onPrimary),
                      color: Theme.of(context).colorScheme.primary),
                  ButtonState.loading: IconedButton(
                      color: Theme.of(context).colorScheme.primary),
                  ButtonState.fail: IconedButton(
                      text: "Failed",
                      icon: Icon(Icons.cancel,
                          color: Theme.of(context).colorScheme.onError),
                      color: Theme.of(context).colorScheme.error),
                  ButtonState.success: IconedButton(
                      text: "Sent",
                      icon: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).own().onSuccess,
                      ),
                      color: Theme.of(context).own().success)
                }, onPressed: onSubmit, state: _state)
              ],
            )));
  }
}
