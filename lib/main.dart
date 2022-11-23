import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/account_page.dart';
import 'package:flutter_app/reset_password.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/welcome.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'own_theme_fields.dart';
import 'pages/drives_page.dart';
import 'pages/home_page.dart';
import 'pages/rides_page.dart';
import 'pages/settings_page.dart';

void main() async {
  await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_BASE_URL'),
    anonKey: dotenv.get('SUPABASE_BASE_KEY'),
  );

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ThemeData lightTheme = ThemeData.light()
    ..addOwn(
        const OwnThemeFields(success: Colors.green, onSuccess: Colors.white));
  final ThemeData darkTheme = ThemeData.dark()
    ..addOwn(
        const OwnThemeFields(success: Colors.green, onSuccess: Colors.white));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Motis Mitfahr-App',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: MotisApp());
  }
}

class MotisApp extends StatefulWidget {
  const MotisApp({super.key});

  @override
  State<MotisApp> createState() => _MotisAppState();
}

class _MotisAppState extends State<MotisApp> {
  late final StreamSubscription<AuthState> _authStateSubscription;
  User? _currentUser = supabaseClient.auth.currentSession?.user;
  bool _isLoggedIn = supabaseClient.auth.currentSession != null;
  int _selectedIndex = 0;
  bool _redirecting = false;

  static const List<Widget> _pages = [
    HomePage(),
    DrivesPage(),
    RidesPage(),
    AccountPage(),
  ];

  Future<void> getInitialAuthState() async {
    try {
      Session? initialSession = await SupabaseAuth.instance.initialSession;
      if (initialSession != null) {
        setState(() {
          _currentUser = initialSession.user;
          _isLoggedIn = true;
        });
      }
    } on Exception {
      // Do nothing, stay logged out
    }
  }

  @override
  void initState() {
    super.initState();

    //getInitialAuthState();

    Future.delayed(Duration.zero, _setupAuthStateSubscription);
  }

  void _setupAuthStateSubscription() {
    _authStateSubscription =
        supabaseClient.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;

      _redirecting = true;
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print("Auth event: ${event.toString()}");

      print(session != null);

      /*_isLoggedIn = session != null;
      _currentUser = session?.user;*/

      if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const ResetPasswordScreen()),
            (route) => false);
      } else if (event != AuthChangeEvent.userUpdated &&
          event != AuthChangeEvent.tokenRefreshed) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MotisApp()),
            (route) => false);
      }
    }, onError: (error) {
      if (error.runtimeType == AuthException) {
        error = error as AuthException;
        if (error.message == 'Email link is invalid or has expired') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Email link is invalid or has expired"),
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building MOTIS App");
    print(_isLoggedIn);
    return _isLoggedIn // || kDebugMode
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Motis Mitfahr-App'),
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.drive_eta),
                  label: 'Drives',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chair),
                  label: 'Rides',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  label: 'Account',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          )
        : const WelcomeScreen();
  }
}
