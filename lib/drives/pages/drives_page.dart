import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/supabase.dart';
import '../../util/trip/drive_card.dart';
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
    int userId = SupabaseManager.getCurrentProfile()!.id!;
    _drives = SupabaseManager.supabaseClient
        .from('drives')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId)
        .order('start_time', ascending: true)
        .map((drive) => Drive.fromJsonList(drive));
    super.initState();
  }

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
