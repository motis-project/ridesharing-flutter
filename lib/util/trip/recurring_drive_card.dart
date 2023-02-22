import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

import '../../drives/models/drive.dart';
import '../../drives/models/recurring_drive.dart';
import '../../drives/pages/recurring_drive_detail_page.dart';
import '../supabase_manager.dart';
import 'drive_card.dart';
import 'recurring_drive_empty_card.dart';

class RecurringDriveCard extends StatefulWidget {
  final int recurringDriveId;
  const RecurringDriveCard(this.recurringDriveId, {super.key});

  @override
  State<RecurringDriveCard> createState() => _RecurringDriveCardState();
}

class _RecurringDriveCardState extends State<RecurringDriveCard> {
  static const int _maxShownDrivesDefault = 3;

  late int _id;
  late RecurringDrive _recurringDrive;
  late List<Drive> _drives;
  bool fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _id = widget.recurringDriveId;
    });
    loadRecurringDrive();
  }

  /*@override
  void didUpdateWidget(RecurringDriveCard oldWidget) {
    if (const DeepCollectionEquality().equals(_drives, widget.drives)) {
      loadRecurringDrive();
    }
    super.didUpdateWidget(oldWidget);
  }*/

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
    ''').eq('id', _id).single();
    if (mounted) {
      setState(() {
        _recurringDrive = RecurringDrive.fromJson(data);
        final List<Drive> sortedDrives = _recurringDrive.upcomingDrives
          ..sort((Drive a, Drive b) => a.startDateTime.compareTo(b.startDateTime));

        _drives = sortedDrives.take(_maxShownDrivesDefault).toList();
        fullyLoaded = true;
      });
    }
  }

  void Function() get onTap {
    return () => Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => RecurringDriveDetailPage.fromRecurringDrive(_recurringDrive),
          ),
        )
        .then((_) => loadRecurringDrive());
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = fullyLoaded
        ? _drives.isEmpty
            ? <Widget>[RecurringDriveEmptyCard(_recurringDrive)]
            : _drives
                .map(
                  (Drive drive) => Container(
                    decoration: BoxDecoration(
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSurface,
                          blurRadius: 8,
                          spreadRadius: -10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: DriveCard(drive),
                  ),
                )
                .toList()
        : List<Widget>.generate(
            _maxShownDrivesDefault,
            (int index) => Shimmer.fromColors(
              baseColor: Theme.of(context).cardColor,
              highlightColor: Theme.of(context).colorScheme.onSurface,
              child: const SizedBox(height: 200),
            ),
          );
    return Stack(
      children: <Widget>[
        for (int index = cards.length - 1; index > 0; index--)
          Positioned(
            left: index * 20,
            top: 4 + (cards.length - index - 1) * 36,
            child: cards[index],
            /*left: -10,
            top: (cards.length - index - 1) * 36,
            child: Transform.scale(
              scale: 1 - index * 0.1,
              child: cards[index],
            ),*/
          ),
        // This column determines the size of the stack. The Positioned widgets can only be placed on top of the stack,
        // the size of which has to be calculated beforehand.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: 4 + (cards.length - 1) * 36),
            cards[0],
          ],
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              tooltip: S.of(context).openDetails,
              child: InkWell(
                onTap: onTap,
                key: const Key('avatarTappable'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
