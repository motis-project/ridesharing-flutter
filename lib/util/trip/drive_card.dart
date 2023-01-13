import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card_state.dart';
import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import '../buttons/custom_banner.dart';
import '../supabase.dart';
import 'package:motis_mitfahr_app/util/trip/trip_overview.dart';

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
    int numberofPendingRequests = 0;
    for (var ride in drive!.rides!) {
      if (ride.status == RideStatus.pending) numberofPendingRequests++;
    }
    return numberofPendingRequests > 0
        ? Badge(
            badgeContent: Text(
              numberofPendingRequests.toString(),
              style: const TextStyle(color: Colors.white),
              textScaleFactor: 1.0,
            ),
            position: BadgePosition.topEnd(top: -12),
            child: const Icon(
              Icons.done_all,
              color: Colors.grey,
            ),
          )
        : const Icon(
            Icons.done_all,
            color: Colors.green,
          );
  }

  @override
  Widget build(BuildContext context) {
    return !fullyLoaded
        ? const Center(child: CircularProgressIndicator())
        : Card(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DriveDetailPage.fromDrive(drive),
                ),
              ),
              child: drive!.cancelled
                  ? Stack(
                      children: [
                        Container(
                          foregroundDecoration: const BoxDecoration(
                            color: Colors.grey,
                            backgroundBlendMode: BlendMode.saturation,
                          ),
                          child: buildCardInfo(context),
                        ),
                        CustomBanner.translucenterror('cancelled'),
                      ],
                    )
                  : buildCardInfo(context),
            ),
          );
  }
}
