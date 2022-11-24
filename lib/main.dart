import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_BASE_URL'),
    anonKey: dotenv.get('SUPABASE_BASE_KEY'),
  );

  runApp(const MotisApp());
}

class MotisApp extends StatelessWidget {
  const MotisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motis Mitfahr-App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const App(),
    );
  }
}
