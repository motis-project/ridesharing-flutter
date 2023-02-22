import 'dart:math';

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
  static const int _maxShownDrivesDefault = 3;

  late int _id;
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
            _maxShownDrivesDefault,
            (int index) => Shimmer.fromColors(
              baseColor: Theme.of(context).cardColor,
              highlightColor: Theme.of(context).colorScheme.onSurface,
              child: const SizedBox(height: 200),
            ),
          );
    return SizedBox(
      height: 400,
      width: 50,
      child: Stack(
        children: <Widget>[
          for (int index = 0; index < cards.length; index++)
            Positioned(
              top: (pow(index, 1.2)) * 36,
              child: Transform.scale(
                scale: 1 - (cards.length - index - 1) * 0.1,
                child: Container(
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
                  child: cards[cards.length - index - 1],
                ),
              ),
            ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Semantics(
                button: true,
                tooltip: S.of(context).openDetails,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (BuildContext context) => RecurringDriveDetailPage(id: _id)),
                  ),
                  key: const Key('avatarTappable'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
