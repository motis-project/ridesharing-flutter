import 'package:flutter/material.dart';
import 'package:flutter_app/drives/pages/create_drive_page.dart';

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
