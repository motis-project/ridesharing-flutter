import 'package:flutter/material.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:flutter_app/util/trip/trip_card_state.dart';
import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import '../locale_manager.dart';

class DriveCard extends TripCard<Drive> {
  const DriveCard(super.trip, {super.key});

  @override
  State<DriveCard> createState() => _DriveCard();
}

class _DriveCard extends TripCardState<DriveCard> {
  Drive? drive;

  @override
  void initState() {
    super.initState();

    setState(() {
      drive = widget.trip;
      super.trip = drive;
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
  Widget buildTopRight() {
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
