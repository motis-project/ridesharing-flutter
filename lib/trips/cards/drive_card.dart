import 'package:flutter/material.dart';

import '../../managers/locale_manager.dart';
import '../../managers/supabase_manager.dart';
import '../../util/own_theme_fields.dart';
import '../models/drive.dart';
import '../models/ride.dart';
import '../pages/drive_detail_page.dart';
import '../util/seat_indicator.dart';
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
    });

    loadDrive();
  }

  @override
  void didUpdateWidget(DriveCard oldWidget) {
    if (!trip.equals(widget.trip)) {
      loadDrive();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> loadDrive() async {
    if (widget.loadData) {
      final Map<String, dynamic> data =
          await supabaseManager.supabaseClient.from('drives').select<Map<String, dynamic>>('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.trip.id).single();
      drive = Drive.fromJson(data);
      trip = drive;
    }
    if (mounted) {
      setState(() {
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
  Widget buildTopLeft() {
    return Text(localeManager.formatDate(trip.startDateTime));
  }

  @override
  Widget buildRightSide() {
    return SeatIndicator(trip);
  }

  @override
  Widget buildTopRight() {
    if (!_fullyLoaded || drive.isFinished) {
      return const SizedBox();
    } else if (drive.status.isCancelled()) {
      return Icon(
        Icons.block,
        color: statusColor,
        key: const Key('cancelledIcon'),
      );
    } else if (drive.rides!.any((Ride ride) => ride.status == RideStatus.pending)) {
      return Icon(
        Icons.access_time_outlined,
        color: statusColor,
        key: const Key('pendingIcon'),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  Color get statusColor {
    if (!_fullyLoaded) {
      return Theme.of(context).cardColor;
    } else if (drive.status == DriveStatus.preview) {
      return Theme.of(context).primaryColor;
    } else if (drive.isFinished) {
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
