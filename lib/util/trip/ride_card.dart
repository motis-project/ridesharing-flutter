import 'dart:math';

import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../account/models/profile_feature.dart';
import '../../account/models/review.dart';
import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../../rides/pages/ride_detail_page.dart';
import '../own_theme_fields.dart';
import '../profiles/profile_widget.dart';
import '../profiles/reviews/custom_rating_bar_indicator.dart';
import '../profiles/reviews/custom_rating_bar_size.dart';
import '../supabase.dart';
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
    Ride trip = widget.trip;
    final Map<String, dynamic> data =
        await SupabaseManager.supabaseClient.from('drives').select(_driveQuery).eq('id', trip.driveId).single();
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
  Widget buildTopRight() {
    return Text(key: const Key('price'), ' ${_ride.price}€');
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
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 16),
            child: ProfileWidget(
              _driver,
              size: 16,
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
              size: CustomRatingBarSize.medium,
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
  Color pickStatusColor() {
    if (_ride.endTime.isBefore(DateTime.now())) {
      if (_ride.status == RideStatus.approved) {
        return Theme.of(context).own().success;
      } else {
        return Theme.of(context).disabledColor;
      }
    } else {
      switch (_ride.status) {
        case RideStatus.pending:
          return Theme.of(context).own().warning;
        case RideStatus.approved:
          return Theme.of(context).own().success;
        case RideStatus.rejected:
          return Theme.of(context).errorColor;
        case RideStatus.cancelledByDriver:
          return Theme.of(context).errorColor;
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
    if (_ride.status.isCancelled() || _ride.status == RideStatus.rejected) {
      return disabledDecoration;
    }
    return super.pickDecoration();
  }
}
