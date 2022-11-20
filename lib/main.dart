import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/reset_password.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/welcome.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/login.dart';

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

void exampleCalls() async {
  final List<Map<String, dynamic>> usersJson =
      await supabaseClient.from('users').select();
  List<models.User> users = models.User.fromJsonList(usersJson);
  print(users.map((e) => e.name));

  await supabaseClient.from('users').update({'name': 'Fynn2'}).eq('id', 1);
  final Map<String, dynamic> data = await supabaseClient
      .from('users')
      .select()
      .order('id', ascending: true)
      .limit(1)
      .single();
  models.User user = models.User.fromJson(data);
  assert(user.name == 'Fynn2');
}

class MotisApp extends StatefulWidget {
  const MotisApp({super.key});

  @override
  State<MotisApp> createState() => _MotisAppState();
}

class _MotisAppState extends State<MotisApp> {
  bool _isLoggedIn = false;
  int _selectedIndex = 0;

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
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
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
