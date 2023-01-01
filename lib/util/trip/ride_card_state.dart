import 'package:flutter/material.dart';
import 'package:flutter_app/util/trip/ride_card.dart';
import 'package:flutter_app/util/trip/trip_card_state.dart';
import '../../account/models/profile.dart';
import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../../rides/pages/ride_detail_page.dart';
import '../profiles/reviews/custom_rating_bar_indicator.dart';
import '../profiles/reviews/custom_rating_bar_size.dart';
import '../supabase.dart';
import 'package:flutter_app/account/models/review.dart';

class RideCardState<T extends RideCard> extends TripCardState<RideCard> {
  Ride? ride;
  bool fullyLoaded = false;
  Profile? driver;

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
      ride = widget.trip;
      super.trip = ride;
    });
    loadRide();
  }

  Future<void> loadRide() async {
    Ride trip = ride!;

    Map<String, dynamic> data = await supabaseClient.from('drives').select(_driveQuery).eq('id', trip.driveId).single();

    trip.drive = Drive.fromJson(data);

    setState(() {
      ride = ride;
      driver = ride!.drive!.driver!;
      fullyLoaded = true;
    });
  }

  @override
  Widget buildTopRight() {
    Icon progress;
    switch (ride!.status) {
      case RideStatus.approved:
        progress = const Icon(
          Icons.done_all,
          color: Colors.green,
        );
        break;
      case RideStatus.preview:
        progress = const Icon(
          Icons.done,
          color: Colors.grey,
        );
        break;
      case RideStatus.pending:
        progress = const Icon(
          Icons.done_all,
          color: Colors.grey,
        );
        break;
      case RideStatus.rejected:
        progress = const Icon(
          Icons.remove_done,
          color: Colors.red,
        );
        break;
      case RideStatus.cancelledByDriver:
        progress = const Icon(
          Icons.block,
          color: Colors.red,
        );
        break;
      case RideStatus.cancelledByRider:
        progress = const Icon(
          Icons.done_all,
          color: Colors.red,
        );
        break;
    }
    return Row(
      children: [
        progress,
        const SizedBox(width: 4),
        Text("${ride!.price}\u{20AC} "),
      ],
    );
  }

  @override
  Widget buildBottomLeft() {
    return Row(
      children: [
        CircleAvatar(
          child: Text(driver!.username[0]),
        ),
        const SizedBox(width: 5),
        Text(driver!.username),
      ],
    );
  }

  @override
  Widget buildBottomRight() {
    AggregateReview aggregateReview = AggregateReview.fromReviews(ride!.drive!.driver!.reviewsReceived!);

    return Row(
      children: [
        Text(aggregateReview.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        CustomRatingBarIndicator(rating: aggregateReview.rating, size: CustomRatingBarSize.large),
      ],
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
                  builder: (context) => RideDetailPage.fromRide(ride!),
                ),
              ),
              child: buildCardInfo(context),
            ),
          );
  }
}
