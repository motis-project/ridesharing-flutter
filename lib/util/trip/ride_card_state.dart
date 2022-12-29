import 'package:flutter/material.dart';
import 'package:flutter_app/util/trip/ride_card.dart';
import 'package:flutter_app/util/trip/trip_card_state.dart';
import '../../account/models/profile.dart';
import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../../rides/pages/ride_detail_page.dart';
import '../supabase.dart';

class RideCardState<T extends RideCard> extends TripCardState<RideCard> {
  Ride? ride;
  bool fullyLoaded = false;

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
      fullyLoaded = true;
    });
  }

  @override
  Widget buildTopRight() {
    return Text("${ride!.price}\u{20AC} ");
  }

  @override
  Widget buildBottomLeft() {
    Profile driver = ride!.drive!.driver!;
    return Row(
      children: [
        CircleAvatar(
          child: Text(driver.username[0]),
        ),
        const SizedBox(width: 5),
        Text(driver.username),
      ],
    );
  }

  @override
  Widget buildBottomRight() {
    return Row(
      children: const [
        Text("3"),
        Icon(
          Icons.star,
          color: Colors.amberAccent,
        ),
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
