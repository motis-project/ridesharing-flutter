import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_app.dart';
import 'util/locale_manager.dart';
import 'util/supabase_manager.dart';
import 'util/theme_manager.dart';
import 'welcome/pages/reset_password_page.dart';
import 'welcome/pages/welcome_page.dart';

void main() async {
  await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();
  await supabaseManager.initialize();
  await themeManager.loadTheme();
  await localeManager.loadCurrentLocale();

  runApp(const AppWrapper());
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => AppWrapperState();
}

class AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    themeManager.addListener(
      () => setState(() {}),
    );
    localeManager.addListener(
      () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => S.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: themeManager.lightTheme,
      darkTheme: themeManager.darkTheme,
      themeMode: themeManager.currentThemeMode,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: localeManager.supportedLocales,
      locale: localeManager.currentLocale,
      home: const AuthApp(),
    );
  }
}

class AuthApp extends StatefulWidget {
  const AuthApp({super.key});

  @override
  State<AuthApp> createState() => AuthAppState();
}

class AuthAppState extends State<AuthApp> {
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isLoggedIn = supabaseManager.supabaseClient.auth.currentSession != null;
  bool _resettingPassword = false;

  @override
  void initState() {
    super.initState();

    _setupAuthStateSubscription();
  }

  void _setupAuthStateSubscription() {
    _authStateSubscription = supabaseManager.supabaseClient.auth.onAuthStateChange.listen(
      (AuthState data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        await supabaseManager.reloadCurrentProfile();

        setState(() {
          _isLoggedIn = session != null;
          if (event == AuthChangeEvent.passwordRecovery) {
            _resettingPassword = true;
          }

          if (event == AuthChangeEvent.signedOut ||
              event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.passwordRecovery) {
            Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resettingPassword) {
      return ResetPasswordPage(onPasswordReset: () => setState(() => _resettingPassword = false));
    } else if (_isLoggedIn) {
      return MainApp();
    } else {
      return const WelcomePage();
    }
  }
}
