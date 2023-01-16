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
  State<DriveCard> createState() => _DriveCardState();
}

class _DriveCardState extends TripCardState<DriveCard> {
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

  @override
  void didUpdateWidget(DriveCard oldWidget) {
    if (!trip!.equals(widget.trip)) {
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
        drive = Drive.fromJson(data);
        super.trip = drive;
        fullyLoaded = true;
      });
    }
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
    return TripOverview(super.trip!).buildSeatIndicator(context, super.trip!);
  }

  // Notification
  @override
  Widget buildTopRight() {
    return drive!.cancelled
        ? Icon(Icons.block, color: Theme.of(context).errorColor)
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

  Color pickColor() {
    return drive!.cancelled ? Theme.of(context).disabledColor.withOpacity(0.05) : Theme.of(context).cardColor;
  }

  @override
  Widget build(BuildContext context) {
    return !fullyLoaded
        ? const Center(child: SizedBox())
        : Card(
            color: pickColor(),
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
}
