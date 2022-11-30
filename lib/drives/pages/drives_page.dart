import 'package:flutter/material.dart';
import 'package:flutter_app/drives/pages/create_drive_page.dart';

import '../../util/card.dart';
import '../../util/supabase.dart';
import '../models/drive.dart';

final List<DropdownMenuItem<String>> _items =
    ['upcoming', 'past', 'all'].map<DropdownMenuItem<String>>((String value) {
  return DropdownMenuItem<String>(
    value: value,
    child: Text(value),
  );
}).toList();

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  late final Stream<List<Drive>> _allDrives;
  late Stream<List<Drive>> _drives;
  String _filter = 'upcoming';

  void onChanged(String? value) {
    Stream<List<Drive>> drives = _drives;
    String filter = _filter;
    if (value == 'all') {
      filter = 'all';
      drives = _allDrives;
    } else if (value == 'upcoming') {
      filter = 'upcoming';
      drives = _allDrives.map((drives) => drives
          .where((drive) => drive.startTime.isAfter(DateTime.now()))
          .toList());
    } else if (value == 'past') {
      filter = 'past';
      drives = _allDrives.map((drives) => drives
          .where((drive) => drive.endTime.isBefore(DateTime.now()))
          .toList());
    }
    setState(() {
      _drives = drives;
      _filter = filter;
    });
  }

  @override
  void initState() {
    //todo: method to get userId
    const userId = 1;
    _allDrives = supabaseClient
        .from('drives')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId)
        .order('start_time')
        .map((drive) => Drive.fromJsonList(drive));
    _drives = _allDrives.map((drives) => drives
        .where((drive) => drive.startTime.isAfter(DateTime.now()))
        .toList());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drives'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filter',
                contentPadding: EdgeInsets.all(8.0),
                border: UnderlineInputBorder(),
              ),
              value: _filter,
              items: _items,
              onChanged: onChanged),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Drive>>(
              stream: _drives,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final drives = snapshot.data!;
                  return drives.isEmpty
                      ? const Center(child: Text('No drives yet'))
                      : ListView.builder(
                          itemCount: drives.length,
                          itemBuilder: (context, index) {
                            final drive = drives[index];
                            return DriveCard(drive: drive);
                          },
                        );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateDrivePage()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
