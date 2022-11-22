import 'package:flutter/material.dart';
import 'package:flutter_app/my_scaffold.dart';
import 'package:flutter_app/pages/create_drive_page.dart';

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      body: const Center(child: Text('Drives')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateDrivePage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
