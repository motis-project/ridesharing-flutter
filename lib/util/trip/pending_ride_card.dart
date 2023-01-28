import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../icon_widget.dart';
import '../locale_manager.dart';
import '../profiles/profile_widget.dart';
import '../snackbar.dart';
import '../supabase.dart';
import 'trip_card.dart';

class PendingRideCard extends TripCard<Ride> {
  final Function() reloadPage;
  final Drive drive;
  const PendingRideCard(super.trip, {super.key, required this.reloadPage, required this.drive});

  @override
  State<PendingRideCard> createState() => _PendingRideCardState();
}

class _PendingRideCardState extends TripCardState<Ride, PendingRideCard> {
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
    return Text('+${localeManager.formatDuration(extraTime, shouldPadHours: false)}');
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
      child: Text('${_ride.price}€'),
    );
  }

  @override
  Widget buildRightSide() {
    return ButtonBar(
      children: <Widget>[
        IconButton(
          onPressed: () => showApproveDialog(context),
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 50.0),
          tooltip: S.of(context).approve,
        ),
        IconButton(
          onPressed: () => showRejectDialog(context),
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 50.0),
          tooltip: S.of(context).reject,
        ),
      ],
    );
  }

  Widget buildSeatsIndicator() {
    final Widget icon = Icon(
      Icons.chair,
      color: Theme.of(context).colorScheme.primary,
    );
    return IconWidget(icon: icon, count: trip.seats);
  }

  Future<void> approveRide() async {
    //custom rpc call to mark the ride as approved,
    //so the user does not need the write permission on the rides table.
    await SupabaseManager.supabaseClient.rpc(
      'approve_ride',
      params: <String, dynamic>{'ride_id': _ride.id},
    );
    // todo: notify rider
    widget.reloadPage();
  }

  Future<void> rejectRide() async {
    //custom rpc call to mark the ride as rejected,
    //so the user does not need the write permission on the rides table.
    await SupabaseManager.supabaseClient.rpc(
      'reject_ride',
      params: <String, dynamic>{'ride_id': _ride.id},
    );
    //todo: notify rider
    widget.reloadPage();
  }

  void showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
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
                showSnackBar(
                  context,
                  S.of(context).cardPendingRideApproveDialogSuccessSnackbar,
                  durationType: SnackBarDurationType.medium,
                );
              } else {
                Navigator.of(dialogContext).pop();
                showSnackBar(
                  context,
                  S.of(context).cardPendingRideApproveDialogErrorSnackbar,
                  durationType: SnackBarDurationType.medium,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
              showSnackBar(
                context,
                S.of(context).cardPendingRideRejectDialogSuccessSnackBar,
                durationType: SnackBarDurationType.medium,
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
