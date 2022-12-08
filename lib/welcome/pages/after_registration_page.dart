import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/welcome/pages/login_page.dart';

class AfterRegistrationPage extends StatelessWidget {
  const AfterRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const Text(
                  "Hi!",
                  style: TextStyle(fontSize: 50),
                ),
                const SizedBox(height: 20),
                Image.asset("assets/handwave.png"),
                const SizedBox(height: 5),
                const Text(
                  "Nice to see you! To finish the registration, please open your email app and confirm your address.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                BigButton(
                  text: "Login",
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()), (route) => route.isFirst),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
