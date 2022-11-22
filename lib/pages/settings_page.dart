import 'package:flutter/material.dart';
import 'package:flutter_app/my_scaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return const MyScaffold(
      body: Center(
        child: Text('Settings'),
      ),
    );
  }
}
