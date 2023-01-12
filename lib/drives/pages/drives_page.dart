import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/drives/pages/create_drive_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/util/trip/trip_page_builder.dart';
import '../../util/trip/drive_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  late final Stream<List<Drive>> _drives;
  late final List<Drive> _loadedDrives;
  bool _fullyloaded = false;

  @override
  void initState() {
    int userId = SupabaseManager.getCurrentProfile()!.id!;
    _drives = supabaseClient
        .from('drives')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId)
        .order('start_time', ascending: true)
        .map((drive) => Drive.fromJsonList(drive));

    super.initState();
  }

  Future<void> loadDrives(List<Map<String, dynamic>> drives) async {
    List<Drive> loadedDrives = [];
    for (Map<String, dynamic> drive in drives) {
      Map<String, dynamic> data = await supabaseClient.from('drives').select('''
        *,
        rides(
          *,
          rider: rider_id(*)
        )
      ''').eq('id', drive['id']).single();
      loadedDrives.add(Drive.fromJson(data));
    }
    setState(() {
      _loadedDrives = loadedDrives;
    });
  }

  // Future<void> loadDetails() async {
  //   _drives.map((drive) async {
  //   Map<String, dynamic> data = await supabaseClient.from('drives').select('''
  //     *,
  //     rides(
  //       *,
  //       rider: rider_id(*)
  //     )
  //   ''').eq('id', drive.id).single();
  //   return Drive.fromJson(data);
  //   })
  // }

  @override
  Widget build(BuildContext context) {
    return TripPageBuilder.build<Drive>(
      context,
      S.of(context).pageDrivesTitle,
      _drives,
      (drive) => DriveCard(drive),
      FloatingActionButton(
        heroTag: 'DriveFAB',
        tooltip: S.of(context).pageDrivesTooltipOfferRide,
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void onPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateDrivePage()),
    );
  }
}
