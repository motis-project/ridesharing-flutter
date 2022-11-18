import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app/password_field.dart';
import 'package:flutter_app/submit_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _validEmail = true;
  bool _validPassword = true;
  bool _correctPasswordRepeat = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Register"),
        ),
        body: Center(
            child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Enter valid email',
                    errorText:
                        _validEmail ? null : "Not a valid e-mail address!"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              const TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    hintText: 'We recommend you choose your real name'),
              ),
              const SizedBox(height: 15),
              PasswordField(
                labelText: "Password",
                hintText: "Enter your password",
                helperText: "Must contain at least 8 characters",
                errorText: _validPassword
                    ? null
                    : "Must contain at least 8 characters",
              ),
              const SizedBox(height: 15),
              PasswordField(
                labelText: "Confirm password",
                hintText: "Re-enter your password",
                errorText: _correctPasswordRepeat
                    ? null
                    : "Failed to confirm your password",
              ),
              const SizedBox(height: 15),
              SubmitButton(
                text: "Create account",
                onPressed: () => {print("Create Account")},
              )
            ],
          ),
        ))));
  }
}
