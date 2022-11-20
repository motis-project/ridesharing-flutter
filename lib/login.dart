import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_app/forgot_password.dart';
import 'package:flutter_app/password_field.dart';
import 'package:flutter_app/register.dart';
import 'package:flutter_app/submit_button.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
        ),
        body: const Center(
          child: CustomScrollView(physics: ClampingScrollPhysics(), slivers: [
            SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: LoginForm(),
                ))
          ]),
          /*bottomNavigationBar: BottomAppBar(
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
          )),*/
        ));
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await supabaseClient.auth.signInWithPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      } on AuthException catch (e) {
        // looks weird but needed later for i18n
        String text = e.statusCode == '400'
            ? (e.message.contains("credentials")
                ? "Invalid credentials"
                : "Please confirm your email address")
            : "Something went wrong";

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
        ));
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(child: Container()),
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email',
              hintText: 'Enter valid email',
            ),
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              } else if (!value.isValidEmail()) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          PasswordField(
            labelText: "Password",
            hintText: "Enter your password",
            controller: passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ForgotPasswordScreen(
                        initialEmail: emailController.text)));
              },
              child: const Text("Forgot password?")),
          Hero(
              tag: "LoginButton",
              transitionOnUserGestures: true,
              child: SubmitButton(text: "Submit", onPressed: onSubmit)),
          Expanded(
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const RegisterScreen()));
                      },
                      child: const Text("No account yet? Register")),
                )),
          )
        ],
      ),
    );
  }
}
