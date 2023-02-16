import 'package:flutter/material.dart';

import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import '../../rides/models/ride.dart';
import '../own_theme_fields.dart';
import '../supabase_manager.dart';
import 'seat_indicator.dart';
import 'trip_card.dart';

class DriveCard extends TripCard<Drive> {
  const DriveCard(super.trip, {super.key, super.loadData});

  @override
  State<DriveCard> createState() => DriveCardState();
}

class DriveCardState extends TripCardState<Drive, DriveCard> {
  late Drive drive;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      drive = widget.trip;
      trip = drive;
      _fullyLoaded = !widget.loadData;
    });

    if (widget.loadData) {
      loadDrive();
    }
  }

  @override
  void didUpdateWidget(DriveCard oldWidget) {
    if (!trip.equals(widget.trip)) {
      loadDrive();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> loadDrive() async {
    final Map<String, dynamic> data =
        await supabaseManager.supabaseClient.from('drives').select<Map<String, dynamic>>('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.trip.id).single();
    if (mounted) {
      setState(() {
        drive = Drive.fromJson(data);
        trip = drive;
        _fullyLoaded = true;
      });
    }
  }

  @override
  void Function() get onTap {
    return () => Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => DriveDetailPage.fromDrive(drive),
          ),
        )
        .then((_) => loadDrive());
  }

  @override
  Widget buildRightSide() {
    return SeatIndicator(trip);
  }

  @override
  Color pickStatusColor() {
    if (!_fullyLoaded) {
      return Theme.of(context).cardColor;
    } else if (drive.endDateTime.isBefore(DateTime.now())) {
      return Theme.of(context).disabledColor;
    } else {
      if (drive.status.isCancelled()) {
        return Theme.of(context).colorScheme.error;
      } else if (drive.rides!.any((Ride ride) => ride.status == RideStatus.pending)) {
        return Theme.of(context).own().warning;
      } else if (drive.rides!.any((Ride ride) => ride.status == RideStatus.approved)) {
        return Theme.of(context).own().success;
      } else {
        return Theme.of(context).disabledColor;
      }
    }
  }

  @override
  BoxDecoration pickDecoration() {
    if (drive.status.isCancelled()) {
      return disabledDecoration;
    }

    return super.pickDecoration();
  }
}
