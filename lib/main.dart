import 'package:flutter/material.dart';
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

  runApp(const MotisApp());
}

class MotisApp extends StatefulWidget {
  const MotisApp({super.key});

  @override
  State<MotisApp> createState() => _MotisAppState();
}

class _MotisAppState extends State<MotisApp> {
  bool _isLoggedIn = false;
  int _selectedIndex = 0;

  final ThemeData lightTheme = ThemeData.light()
    ..addOwn(
        const OwnThemeFields(success: Colors.green, onSuccess: Colors.white));
  final ThemeData darkTheme = ThemeData.dark()
    ..addOwn(
        const OwnThemeFields(success: Colors.green, onSuccess: Colors.white));

  static const List<Widget> _pages = [
    HomePage(),
    DrivesPage(),
    RidesPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    supabaseClient.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      setState(() {
        _isLoggedIn = event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.passwordRecovery;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Motis Mitfahr-App',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: _isLoggedIn //&& !kDebugMode
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
                      icon: Icon(Icons.settings),
                      label: 'Settings',
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
            : const WelcomeScreen());
  }
}
