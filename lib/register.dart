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
              const TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Enter valid email'),
              ),
              const SizedBox(height: 15),
              const TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    hintText: 'We recommend you choose your real name'),
              ),
              const SizedBox(height: 15),
              const PasswordField(
                labelText: "Password",
                hintText: "Enter your password",
              ),
              const SizedBox(height: 15),
              const PasswordField(
                labelText: "Confirm password",
                hintText: "Re-enter your password",
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
