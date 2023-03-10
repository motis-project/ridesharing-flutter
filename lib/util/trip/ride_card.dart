import 'dart:math';

import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../account/models/profile_feature.dart';
import '../../account/models/review.dart';
import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../../rides/pages/ride_detail_page.dart';
import '../locale_manager.dart';
import '../own_theme_fields.dart';
import '../profiles/profile_widget.dart';
import '../profiles/reviews/custom_rating_bar_indicator.dart';
import '../supabase_manager.dart';
import 'trip_card.dart';

class RideCard extends TripCard<Ride> {
  const RideCard(super.trip, {super.key});

  @override
  State<RideCard> createState() => _RideCardState();
}

class _RideCardState extends TripCardState<Ride, RideCard> {
  late Ride _ride;
  late Profile _driver;
  bool _fullyLoaded = false;

  BorderRadius cardPreviewBorder = BorderRadius.circular(10);

  static const String _driveQuery = '''
    *,
    driver: driver_id(
      *,
      reviews_received: reviews!reviews_receiver_id_fkey(
        *,
        writer: writer_id(*)
      ),
      profile_features(*)
    ),
    rides(
      *,
      rider: rider_id(*)
    )
  ''';

  @override
  void initState() {
    super.initState();
    setState(() {
      _ride = widget.trip;
      trip = _ride;
    });
    loadRide();
  }

  @override
  void didUpdateWidget(RideCard oldWidget) {
    if (!trip.equals(widget.trip)) {
      loadRide();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> loadRide() async {
    if (_ride.status == RideStatus.preview) {
      setState(() {
        _fullyLoaded = true;
        _driver = _ride.drive!.driver!;
      });
      return;
    }

    Ride trip = widget.trip;
    final Map<String, dynamic> data = await supabaseManager.supabaseClient
        .from('drives')
        .select<Map<String, dynamic>>(_driveQuery)
        .eq('id', trip.driveId)
        .single();
    trip.drive = Drive.fromJson(data);
    if (mounted) {
      setState(() {
        _ride = trip;
        _driver = trip.drive!.driver!;
        trip = _ride;
        _fullyLoaded = true;
      });
    }
  }

  @override
  void Function() get onTap {
    return () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => RideDetailPage.fromRide(_ride),
          ),
        );
  }

  @override
  Widget buildTopLeft() {
    return Text(localeManager.formatDate(trip.startDateTime));
  }

  @override
  Widget buildTopRight() {
    if (!_fullyLoaded || _ride.isFinished) {
      return const Center(
        child: SizedBox(),
      );
    } else {
      switch (_ride.status) {
        case RideStatus.preview:
          return Text(key: const Key('price'), ' ${_ride.price?.toStringAsFixed(2)}€');
        case RideStatus.pending:
          return Icon(
            Icons.access_time_outlined,
            color: getStatusColor,
            key: const Key('pendingIcon'),
          );
        case RideStatus.approved:
          return Icon(
            Icons.done_all,
            color: getStatusColor,
            key: const Key('approvedIcon'),
          );
        case RideStatus.rejected:
        case RideStatus.cancelledByDriver:
        case RideStatus.cancelledByRider:
        case RideStatus.withdrawnByRider:
          return Icon(
            Icons.block,
            color: getStatusColor,
            key: const Key('cancelledOrRejectedIcon'),
          );
      }
    }
  }

  @override
  Widget buildBottomLeft() {
    return !_fullyLoaded
        ? const Center(
            child: SizedBox(
              height: 56,
              width: 72,
            ),
          )
        : Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 16),
              child: ProfileWidget(
                _driver,
                size: 16,
                isTappable: false,
              ),
            ),
          );
  }

  @override
  Widget buildBottomRight() {
    return _fullyLoaded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
            child: CustomRatingBarIndicator(
              rating: AggregateReview.fromReviews(_ride.drive!.driver!.reviewsReceived!).rating,
            ),
          )
        : const Center(
            child: SizedBox(height: 44, width: 52),
          );
  }

  @override
  Widget buildRightSide() {
    if (!_fullyLoaded) {
      return const Center(
        child: SizedBox(
          height: 24,
          width: 24,
        ),
      );
    }

    final List<ProfileFeature> profileFeatures = _driver.profileFeatures!;
    final List<Icon> featureicons = <Icon>[];
    for (int i = 0; i < min(profileFeatures.length, 3); i++) {
      featureicons.add(profileFeatures[i].feature.getIcon(context));
    }
    return Row(
      key: const Key('profileFeatures'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: featureicons,
    );
  }

  @override
  Color get getStatusColor {
    if (_ride.isFinished) {
      return Theme.of(context).disabledColor;
    } else {
      switch (_ride.status) {
        case RideStatus.pending:
          return Theme.of(context).own().warning;
        case RideStatus.approved:
          return Theme.of(context).own().success;
        case RideStatus.rejected:
          return Theme.of(context).colorScheme.error;
        case RideStatus.cancelledByDriver:
          return Theme.of(context).colorScheme.error;
        case RideStatus.cancelledByRider:
        case RideStatus.withdrawnByRider:
          return Theme.of(context).disabledColor;
        case RideStatus.preview:
          return Theme.of(context).colorScheme.primary;
      }
    }
  }

  @override
  BoxDecoration pickDecoration() {
    if (_ride.status.isCancelled() ||
        _ride.status == RideStatus.rejected ||
        (_ride.isFinished && _ride.status != RideStatus.approved)) {
      return disabledDecoration;
    }
    return super.pickDecoration();
  }
}
