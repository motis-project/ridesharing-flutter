import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../drives/models/drive.dart';
import '../../drives/models/recurring_drive.dart';
import '../../drives/pages/recurring_drive_detail_page.dart';
import '../supabase_manager.dart';
import 'drive_card.dart';

class RecurringDriveCard extends StatefulWidget {
  final List<Drive> drives;
  const RecurringDriveCard(this.drives, {super.key});

  @override
  State<RecurringDriveCard> createState() => _RecurringDriveCardState();
}

class _RecurringDriveCardState extends State<RecurringDriveCard> {
  static const int _maxShownDrivesDefault = 3;

  late List<Drive> _drives;
  bool fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _drives = widget.drives;
    });
    loadRecurringDrive();
  }

  @override
  void didUpdateWidget(RecurringDriveCard oldWidget) {
    if (const DeepCollectionEquality().equals(_drives, widget.drives)) {
      loadRecurringDrive();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> loadRecurringDrive() async {
    final Map<String, dynamic> data =
        await supabaseManager.supabaseClient.from('recurring_drives').select<Map<String, dynamic>>('''
      *,
      drives(
        *,
        rides(
          *,
          rider: rider_id(*)
        )
      )
    ''').eq('id', _drives[0].recurringDriveId).single();
    if (mounted) {
      setState(() {
        _drives = RecurringDrive.fromJson(data)
            .drives!
            .where((Drive drive) => drive.endDateTime.isAfter(DateTime.now()))
            .toList()
            .take(_maxShownDrivesDefault)
            .toList();
        fullyLoaded = true;
      });
    }
  }

  void Function() get onTap {
    return () => Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => RecurringDriveDetailPage(id: _drives[0].recurringDriveId!),
          ),
        )
        .then((_) => loadRecurringDrive());
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = fullyLoaded
        ? _drives.map((Drive drive) => DriveCard(drive)).toList()
        : List<Widget>.generate(
            3,
            (int index) => Shimmer.fromColors(
              baseColor: Theme.of(context).cardColor,
              highlightColor: Theme.of(context).colorScheme.onSurface,
              child: const SizedBox(width: double.infinity, height: 200),
            ),
          );
    return Stack(
      children: <Widget>[
        for (int index = 0; index < cards.length - 1; index++)
          Positioned(
            bottom: index * 20,
            child: Transform.scale(
              scale: 1 - (index / (_maxShownDrivesDefault * 3)),
              child: cards[index],
            ),
          ),
        Positioned(bottom: 0, child: cards.last),
      ],
    );
  }
}
