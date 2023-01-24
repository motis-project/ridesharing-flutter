import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/buttons/button.dart';
import 'login_page.dart';

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
              children: <Widget>[
                Text(
                  S.of(context).pageAfterRegistrationHi,
                  style: const TextStyle(fontSize: 50),
                ),
                const SizedBox(height: 20),
                Image.asset('assets/handwave.png'),
                const SizedBox(height: 5),
                Text(
                  S.of(context).pageAfterRegistrationHelpText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Button(
                  S.of(context).pageWelcomeLogin,
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (BuildContext context) => const LoginPage()),
                    (Route<void> route) => route.isFirst,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
