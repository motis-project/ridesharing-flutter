import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

import '../../drives/models/drive.dart';
import '../../drives/models/recurring_drive.dart';
import '../../drives/pages/recurring_drive_detail_page.dart';
import '../supabase_manager.dart';
import 'drive_card.dart';

class RecurringDriveCard extends StatefulWidget {
  final int recurringDriveId;
  const RecurringDriveCard(this.recurringDriveId, {super.key});

  @override
  State<RecurringDriveCard> createState() => _RecurringDriveCardState();
}

class _RecurringDriveCardState extends State<RecurringDriveCard> {
  static const int _maxShownDrivesDefault = 4;

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
        _drives = _recurringDrive.drives!
            // .where(
            //   (Drive drive) =>
            //       drive.endDateTime.isAfter(DateTime.now()) && drive.status != DriveStatus.cancelledByRecurrenceRule,
            // )
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
            builder: (BuildContext context) => RecurringDriveDetailPage.fromRecurringDrive(_recurringDrive),
          ),
        )
        .then((_) => loadRecurringDrive());
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = fullyLoaded
        ? _drives
            .map(
              (Drive drive) => Container(
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface,
                      blurRadius: 8,
                      spreadRadius: -10,
                      offset: const Offset(2, -4),
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
            left: (index - 1) * 20,
            top: (cards.length - index - 1) * 36,
            child: cards[index],
          ),
        if (cards.isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: (cards.length - 2) * 36),
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
