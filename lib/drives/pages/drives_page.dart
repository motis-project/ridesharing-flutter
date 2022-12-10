import 'package:flutter/material.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/drives/pages/create_drive_page.dart';
import 'package:flutter_app/drives/pages/drive_detail_page.dart';
import 'package:flutter_app/util/supabase.dart';

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drives'),
      ),
      body: const Center(
        child: Text('Drives'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void onPressed() async {
    Map<String, dynamic> data = await supabaseClient.from('drives').select().eq('id', 33).limit(1).single();
    Drive drive = Drive.fromJson(data);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DriveDetailPage.fromDrive(drive)),
      );
    }
  }
}
