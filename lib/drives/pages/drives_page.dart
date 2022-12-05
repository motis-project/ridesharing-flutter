import 'package:flutter/material.dart';
import 'package:flutter_app/drives/pages/create_drive_page.dart';
import 'package:flutter_app/util/trip/trip.dart';
import '../../util/supabase.dart';
import '../../util/trip/drive_card.dart';
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
    return Trip.buildTripPage<Drive>(
      context,
      'drives',
      _drives,
      (drive) => DriveCard(trip: drive),
      FloatingActionButton(
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
