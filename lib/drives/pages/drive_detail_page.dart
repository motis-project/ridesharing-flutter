import 'package:flutter/material.dart';

class DriveDetailPage extends StatefulWidget {
  const DriveDetailPage({super.key});

  @override
  State<DriveDetailPage> createState() => _DriveDetailPageState();
}

class _DriveDetailPageState extends State<DriveDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Detail'),
      ),
      body: const Center(
        child: Text('Drive Detail'),
      ),
    );
  }
}
