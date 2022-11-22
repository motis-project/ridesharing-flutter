import 'package:flutter/material.dart';
import 'package:flutter_app/my_scaffold.dart';

class DriveDetailPage extends StatefulWidget {
  const DriveDetailPage({super.key});

  @override
  State<DriveDetailPage> createState() => _DriveDetailPageState();
}

class _DriveDetailPageState extends State<DriveDetailPage> {
  @override
  Widget build(BuildContext context) {
    return const MyScaffold(
      body: Center(child: Text('Drive Detail')),
    );
  }
}
