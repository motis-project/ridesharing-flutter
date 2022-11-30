import 'package:flutter/material.dart';

import '../../util/card.dart';

class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Rides'),
        ),
        body: const Center(
          child: Text('Rides'),
        ));
  }
}
