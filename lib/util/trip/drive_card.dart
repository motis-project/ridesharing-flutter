import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card_state.dart';
import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import '../supabase.dart';
import 'package:motis_mitfahr_app/util/trip/trip_overview.dart';
import 'package:motis_mitfahr_app/util/own_theme_fields.dart';

class DriveCard extends TripCard<Drive> {
  const DriveCard(super.trip, {super.key});

  @override
  State<DriveCard> createState() => _DriveCard();
}

class _DriveCard extends TripCardState<DriveCard> {
  Drive? drive;
  bool fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      drive = widget.trip;
      super.trip = drive;
    });
    loadDrive();
  }

  // todo: changes when rides.status changes
  @override
  void didUpdateWidget(DriveCard oldWidget) {
    if (trip!.isDifferentFrom(widget.trip)) {
      loadDrive();
    }
    super.didUpdateWidget(oldWidget);
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
      drive = Drive.fromJson(data);
      super.trip = drive;
      fullyLoaded = true;
    });
  }

  @override
  Widget buildBottomLeft() {
    return const SizedBox();
  }

  @override
  Widget buildBottomRight() {
    return const SizedBox();
  }

  @override
  Widget buildRightSide() {
    return TripOverview.buildSeatIndicator(context, super.trip!);
  }

  // Notification
  @override
  Widget buildTopRight() {
    return drive!.cancelled
        ? const SizedBox()
        : drive!.rides!.any((ride) => ride.status == RideStatus.pending)
            ? Icon(
                Icons.done_all,
                color: Theme.of(context).disabledColor,
              )
            : Icon(
                Icons.done_all,
                color: Theme.of(context).own().success,
              );
  }

  @override
  Widget build(BuildContext context) {
    return !fullyLoaded
        ? const Center(child: CircularProgressIndicator())
        : Card(
            color: Theme.of(context).cardColor,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DriveDetailPage.fromDrive(drive),
                ),
              ),
              child: drive!.cancelled
                  ? Stack(alignment: AlignmentDirectional.topEnd, children: [
                      Container(
                          foregroundDecoration: const BoxDecoration(
                            color: Colors.grey,
                            backgroundBlendMode: BlendMode.saturation,
                          ),
                          child: buildCardInfo(context)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Icon(Icons.block, color: Theme.of(context).errorColor),
                      )
                    ])
                  : buildCardInfo(context),
            ),
          );
  }
}
