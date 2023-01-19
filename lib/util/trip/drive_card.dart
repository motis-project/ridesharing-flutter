import 'package:flutter/material.dart';

import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import '../../rides/models/ride.dart';
import '../own_theme_fields.dart';
import '../supabase.dart';
import 'seat_indicator.dart';
import 'trip_card.dart';

class DriveCard extends TripCard<Drive> {
  const DriveCard(super.trip, {super.key});

  @override
  State<DriveCard> createState() => _DriveCardState();
}

class _DriveCardState extends TripCardState<DriveCard> {
  late Drive _drive;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _drive = widget.trip;
      trip = _drive;
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
    Map<String, dynamic> data = await SupabaseManager.supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.trip.id).single();
    if (mounted) {
      setState(() {
        _drive = Drive.fromJson(data);
        trip = _drive;
        _fullyLoaded = true;
      });
    }
  }

  @override
  void Function() get onTap {
    return () => Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => DriveDetailPage.fromDrive(_drive),
          ),
        )
        .then((value) => loadDrive());
  }

  @override
  Widget buildRightSide() {
    return SeatIndicator(trip);
  }

  @override
  Color pickStatusColor() {
    if (!_fullyLoaded) {
      return Theme.of(context).cardColor;
    } else if (_drive.endTime.isBefore(DateTime.now())) {
      return Theme.of(context).disabledColor;
    } else {
      if (_drive.cancelled) {
        return Theme.of(context).errorColor;
      } else if (_drive.rides!.any((ride) => ride.status == RideStatus.pending)) {
        return Theme.of(context).own().warning;
      } else if (_drive.rides!.any((ride) => ride.status == RideStatus.approved)) {
        return Theme.of(context).own().success;
      } else {
        return Theme.of(context).disabledColor;
      }
    }
  }

  @override
  BoxDecoration pickDecoration() {
    if (_drive.cancelled) {
      return disabledDecoration;
    }

    return super.pickDecoration();
  }
}
