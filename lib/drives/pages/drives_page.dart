import 'package:flutter/material.dart';

import '../../util/supabase_manager.dart';
import '../../util/trip/trip_page_builder.dart';
import '../models/drive.dart';
import 'create_drive_page.dart';

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  late final Stream<List<Drive>> _drives;

  @override
  void initState() {
    final int userId = supabaseManager.currentProfile!.id!;
    _drives = supabaseManager.supabaseClient
        .from('drives')
        .stream(primaryKey: <String>['id'])
        .eq('driver_id', userId)
        .order('start_time', ascending: true)
        .map((List<Map<String, dynamic>> drive) => Drive.fromJsonList(drive));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TripPageBuilder<Drive>(
      _drives,
      onFabPressed: onPressed,
    );
  }

  void onPressed() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const CreateDrivePage()),
    );
  }
}
