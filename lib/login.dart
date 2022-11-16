import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app/password_field.dart';
import 'package:flutter_app/register.dart';
import 'package:flutter_app/submit_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _userExists = true;
  bool _passwordCorrect = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
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
                  errorText: _userExists ? null : "User does not exist!"),
            ),
            const SizedBox(height: 15),
            PasswordField(
                labelText: "Password",
                hintText: "Enter your password",
                errorText: _passwordCorrect ? null : "Incorrect password!"),
            TextButton(
                onPressed: () {
                  print("Forgot password");
                },
                child: const Text("Forgot password?")),
            SubmitButton(text: "Submit", onPressed: () => {print("Submit")})
          ],
        ),
      ))),
      bottomNavigationBar: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const RegisterScreen()));
                  },
                  child: const Text("No account yet? Register"))
            ],
          )),
    );
  }
}
