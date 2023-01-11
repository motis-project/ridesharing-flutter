// import 'package:flutter/material.dart';
// import 'package:motis_mitfahr_app/drives/models/drive.dart';
// import 'package:motis_mitfahr_app/drives/pages/create_drive_page.dart';
// import 'package:motis_mitfahr_app/util/supabase.dart';
// import 'package:motis_mitfahr_app/util/trip/trip_page_builder.dart';
// import '../../util/trip/drive_card.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _DrivesPageState extends State<HomePage> {
//   late final Stream<List<Drive>> _drives;

//   @override
//   void initState() {
//     int userId = SupabaseManager.getCurrentProfile()!.id!;
//     _drives = supabaseClient
//         .from('drives')
//         .stream(primaryKey: ['id'])
//         .eq('driver_id', userId)
//         .order('start_time', ascending: true)
//         .map((drive) => Drive.fromJsonList(drive));
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return null;
//   }

//   void onPressed() {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (context) => const CreateDrivePage()),
//     );
//   }
// }
