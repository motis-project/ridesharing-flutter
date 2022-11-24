import 'package:flutter/material.dart';
import 'package:flutter_app/email_field.dart';
import 'package:flutter_app/loading_button.dart';
import 'package:flutter_app/login.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/password_field.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        body: const Center(
            child: SingleChildScrollView(
                child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: RegisterForm(),
        ))));
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
            password: passwordController.text, email: emailController.text);
      } on AuthException {
        //AuthException, PostgrestException
        fail();
        showSnackBar("Something went wrong.");
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
          showSnackBar("Something went wrong.");
          return;
        }
        onSuccess();
        await Future.delayed(const Duration(seconds: 2));
        goBack();
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

  void onSuccess() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Account created. Please log in"),
    ));
    setState(() {
      _state = ButtonState.success;
    });
  }

  void goBack() async {
    // Navigator.of(context).pushAndRemoveUntil(
    //     PageRouteBuilder(
    //         pageBuilder: (context, animation1, animation2) => const MotisApp(),
    //         transitionDuration: Duration.zero),
    //     (route) => false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const LoginScreen(),
    ));
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
        absorbing:
            _state == ButtonState.loading || _state == ButtonState.success,
        child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                EmailField(controller: emailController),
                const SizedBox(height: 15),
                TextFormField(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Username',
                      hintText: 'We recommend you choose your real name'),
                  controller: usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
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
                  hintText: "Re-enter your password",
                  controller: passwordConfirmationController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    } else if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                Hero(
                    tag: "RegisterButton",
                    transitionOnUserGestures: true,
                    child: LoadingButton(
                      idleText: "Create account",
                      successText: "Account created",
                      onPressed: onSubmit,
                      state: _state,
                    ))
              ],
            )));
  }
}
