import 'package:flutter/material.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:flutter_app/util/trip/trip_card_state.dart';
import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import '../supabase.dart';
import 'package:flutter_app/util/trip/trip_overview.dart';

class DriveCard extends TripCard<Drive> {
  const DriveCard(super.trip, {super.key});

  @override
  State<DriveCard> createState() => _DriveCard();
}

class _DriveCard extends TripCardState<DriveCard> {
  Drive? _drive;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _drive = widget.trip;
      super.trip = _drive;
    });
    loadDrive();
  }

  Future<void> loadDrive() async {
    Map<String, dynamic> data = await supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.trip.id).single();

    setState(() {
      _drive = Drive.fromJson(data);
      super.trip = _drive;
      _fullyLoaded = true;
    });
  }

  @override
  Widget buildBottomLeft() {
    return const SizedBox();
  }

  @override
  Widget buildBottomRight() {
    return TripOverview.buildSeatIndicator(context, super.trip!);
  }

  @override
  Widget buildTopRight() {
    return _drive!.cancelled
        ? const Icon(
            Icons.block,
            color: Colors.red,
          )
        : _drive!.rides!.any((ride) => ride.status == RideStatus.cancelledByRider)
            ? const Icon(
                Icons.warning,
                color: Colors.orange,
              )
            : _drive!.rides!.any((ride) => ride.status == RideStatus.pending)
                ? const Icon(
                    Icons.add_task,
                    color: Colors.grey,
                  )
                : const Icon(
                    Icons.add_task,
                    color: Colors.green,
                  );
  }

  @override
  Widget build(BuildContext context) {
    return !_fullyLoaded
        ? const Center(child: CircularProgressIndicator())
        : Card(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DriveDetailPage.fromDrive(_drive),
                ),
              ),
              child: buildCardInfo(context),
            ),
          );
  }
}
