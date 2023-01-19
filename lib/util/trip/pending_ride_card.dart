import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../icon_widget.dart';
import '../locale_manager.dart';
import '../profiles/profile_widget.dart';
import '../supabase.dart';
import 'trip_card.dart';

class PendingRideCard extends TripCard<Ride> {
  final Function() reloadPage;
  final Drive drive;
  const PendingRideCard(super.trip, {super.key, required this.reloadPage, required this.drive});

  @override
  State<PendingRideCard> createState() => _PendingRideCardState();
}

class _PendingRideCardState extends TripCardState<PendingRideCard> {
  static const Duration extraTime = Duration(minutes: 5);

  late Ride _ride;

  @override
  void initState() {
    super.initState();
    setState(() {
      _ride = widget.trip;
      trip = widget.trip;
    });
  }

  @override
  Widget buildTopLeft() {
    return ProfileWidget(_ride.rider!);
  }

  @override
  Widget buildTopRight() {
    return Text("+${localeManager.formatDuration(extraTime, shouldPadHours: false)}");
  }

  @override
  Widget buildBottomLeft() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: buildSeatsIndicator(),
    );
  }

  @override
  Widget buildBottomRight() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text("${_ride.price}€"),
    );
  }

  @override
  Widget buildRightSide() {
    return ButtonBar(
      children: [
        IconButton(
          onPressed: (() => showApproveDialog(context)),
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 50.0),
          tooltip: S.of(context).approve,
        ),
        IconButton(
          onPressed: (() => showRejectDialog(context)),
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 50.0),
          tooltip: S.of(context).reject,
        ),
      ],
    );
  }

  buildSeatsIndicator() {
    Widget icon = Icon(
      Icons.chair,
      color: Theme.of(context).colorScheme.primary,
    );
    return IconWidget(icon: icon, count: _ride.seats);
  }

  void approveRide() async {
    await SupabaseManager.supabaseClient.rpc(
      'approve_ride',
      params: {'ride_id': _ride.id},
    );
    // todo: notify rider
    widget.reloadPage();
  }

  void rejectRide() async {
    await SupabaseManager.supabaseClient.rpc(
      'reject_ride',
      params: {'ride_id': _ride.id},
    );
    //todo: notify rider
    widget.reloadPage();
  }

  showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).cardPendingRideApproveDialogTitle),
        content: Text(S.of(context).cardPendingRideApproveDialogMessage),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(S.of(context).yes),
            onPressed: () {
              // check if there are enough seats available
              if (widget.drive.isRidePossible(_ride)) {
                approveRide();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).cardPendingRideApproveDialogSuccessSnackbar),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).cardPendingRideApproveDialogErrorSnackbar),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).cardPendingRideRejectDialogTitle),
        content: Text(S.of(context).cardPendingRideRejectDialogMessage),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(S.of(context).yes),
            onPressed: () {
              rejectRide();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).cardPendingRideRejectDialogSuccessSnackBar),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  EdgeInsets get middlePadding => const EdgeInsets.only(left: 16);

  @override
  void Function()? get onTap {
    return null;
  }
}
