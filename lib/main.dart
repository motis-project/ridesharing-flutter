import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/main_app.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/theme_manager.dart';
import 'package:flutter_app/welcome/pages/reset_password_page.dart';
import 'package:flutter_app/welcome/pages/welcome_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_BASE_URL'),
    anonKey: dotenv.get('SUPABASE_BASE_KEY'),
  );
  await SupabaseManager.reloadCurrentProfile();
  await themeManager.loadTheme();

  runApp(const AppWrapper());
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    themeManager.addListener(
      () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motis Mitfahr-App',
      debugShowCheckedModeBanner: false,
      theme: themeManager.lightTheme,
      darkTheme: themeManager.darkTheme,
      themeMode: themeManager.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthApp(),
    );
  }
}

class AuthApp extends StatefulWidget {
  const AuthApp({super.key});

  @override
  State<AuthApp> createState() => _AuthAppState();
}

class _AuthAppState extends State<AuthApp> {
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isLoggedIn = supabaseClient.auth.currentSession != null;
  bool _resettingPassword = false;

  @override
  void initState() {
    super.initState();

    _setupAuthStateSubscription();
  }

  void _setupAuthStateSubscription() {
    _authStateSubscription = supabaseClient.auth.onAuthStateChange.listen(
      (data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        await SupabaseManager.reloadCurrentProfile();

        setState(() {
          _isLoggedIn = session != null;
          _resettingPassword = event == AuthChangeEvent.passwordRecovery;

          if (event == AuthChangeEvent.signedOut ||
              event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.passwordRecovery ||
              event == AuthChangeEvent.userDeleted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      },
      onError: (error) {
        if (error.runtimeType == AuthException) {
          error = error as AuthException;
          if (error.message == 'Email link is invalid or has expired') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email link is invalid or has expired"),
              ),
            );
          }
        }
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
      return const ResetPasswordPage();
    } else if (_isLoggedIn) {
      return const MainApp();
    } else {
      return const WelcomePage();
    }
  }
}
