import 'package:flutter/material.dart';

class RideDetailPage extends StatefulWidget {
  const RideDetailPage({super.key});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Detail'),
      ),
      body: const Center(
        child: Text('Ride Detail'),
      ),
    );
  }
}
