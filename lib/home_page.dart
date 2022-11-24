import 'package:flutter/material.dart';
import 'package:flutter_app/my_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const MyScaffold(
      body: Center(
        child: Text('Home'),
      ),
    );
  }
}
