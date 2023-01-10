import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/custom_banner.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card_state.dart';
import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import '../supabase.dart';
import 'package:motis_mitfahr_app/util/trip/trip_overview.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    return drive!.cancelled
        ? const SizedBox()
        : numberofPendingRequests > 0
            ? Row(
                children: [
                  Text("+ $numberofPendingRequests "),
                  const Icon(
                    Icons.done_all,
                    color: Colors.grey,
                  ),
                ],
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
              child: buildCardInfo(context),
            ),
          );
  }

  @override
  Widget buildbanner() {
    if (drive!.cancelled) {
      return CustomBanner(kind: CustomBannerKind.error, text: S.of(context).pageDriveDetailBannerCancelled);
    }
    return const SizedBox();
  }
}
