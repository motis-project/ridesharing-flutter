import 'package:flutter/material.dart';
import 'package:flutter_app/my_scaffold.dart';

class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  @override
  Widget build(BuildContext context) {
    return const MyScaffold(
      body: Center(
        child: Text('Rides'),
      ),
    );
  }
}
