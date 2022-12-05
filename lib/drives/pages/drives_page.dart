import 'package:flutter/material.dart';
import 'package:flutter_app/drives/pages/create_drive_page.dart';

import '../../account/models/profile.dart';
import '../../util/card.dart';
import '../../util/supabase.dart';
import '../models/drive.dart';

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  late final Stream<List<Drive>> _drives;

  @override
  void initState() {
    //todo: method to get userId
    int userId = SupabaseManager.getCurrentProfile()!.id!;
    _drives = supabaseClient
        .from('drives')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId)
        .order('start_time', ascending: true)
        .map((drive) => Drive.fromJsonList(drive));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Drives'),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: 'Upcoming',
              ),
              Tab(
                text: 'Past',
              ),
              Tab(
                text: 'All',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DriveStreamBuilder(
              stream: _drives,
              emptyMessage: 'No upcoming drives',
              filterDrives: (drives) => drives
                  //we could change this to drive.starttime the question is what we are doing with
                  //drives that are in progress
                  .where((drive) => drive.endTime.isAfter(DateTime.now()))
                  .toList(),
            ),
            DriveStreamBuilder(
              stream: _drives,
              emptyMessage: 'No past drives',
              filterDrives: (drives) => drives.reversed
                  .where((drive) => drive.endTime.isBefore(DateTime.now()))
                  .toList(),
            ),
            DriveStreamBuilder(
              stream: _drives,
              emptyMessage: 'No drives',
              //we could reorder the stream her somehow, not shure how it's best
              filterDrives: (drives) => drives,
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
      ),
    );
  }
}

class DriveStreamBuilder extends StreamBuilder<List<Drive>> {
  late final String emptyMessage;
  late final List<Drive> Function(List<Drive> drives) filterDrives;

  DriveStreamBuilder({
    Key? key,
    required Stream<List<Drive>> stream,
    required String emptyMessage,
    required List<Drive> Function(List<Drive> drives) filterDrives,
  }) : super(
          key: key,
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Drive> drives = snapshot.data!;
              drives = filterDrives(drives);
              return drives.isEmpty
                  ? Center(child: Text(emptyMessage))
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
        );
}
