import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/account/models/review.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/util/profiles/custom_rating_bar_indicator.dart';
import 'package:flutter_app/util/profiles/profile_row.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/trip/trip_overview.dart';

class RideDetailPage extends StatefulWidget {
  final int id;
  final Ride? ride;

  const RideDetailPage({super.key, required this.id}) : ride = null;
  RideDetailPage.fromRide(this.ride, {super.key}) : id = ride!.id!;

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  Ride? _ride;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _ride = widget.ride;
    });

    loadRide();
  }

  Future<void> loadRide() async {
    Map<String, dynamic> data = await supabaseClient.from('rides').select('''
      *,
      drive: drive_id(
        *,
        driver: driver_id(
          *,
          reviews_received: reviews!reviews_receiver_id_fkey(*)
        ),
        rides(
          *,
          rider: rider_id(*)
        )
      )
    ''').eq('id', widget.id).single();
    //reviews_receiver_id_fkey

    setState(() {
      _ride = Ride.fromJson(data);
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    if (_ride != null) {
      Widget overview = TripOverview(_ride!);
      widgets.add(overview);
    }

    if (_fullyLoaded) {
      widgets.add(const Divider(
        thickness: 1,
      ));

      Profile driver = _ride!.drive!.driver!;
      Widget driverRow = ProfileRow(driver);
      // TODO: Show more info about the driver
      widgets.add(driverRow);

      widgets.add(Row(
        children: [Flexible(child: Text(driver.description ?? "No description"))],
      ));

      widgets.add(const Divider(
        thickness: 1,
      ));

      widgets.add(_buildReviewsColumn(driver));

      widgets.add(const Divider(
        thickness: 1,
      ));

      Set<Profile> riders =
          _ride!.drive!.rides!.where((otherRide) => _ride!.overlapsWith(otherRide)).map((ride) => ride.rider!).toSet();

      Widget ridersColumn = Column(
        children: List.generate(
          riders.length,
          (index) => InkWell(
            onTap: () => print("Hey"),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: ProfileRow(
                riders.elementAt(index),
              ),
            ),
          ),
        ),
      );

      widgets.add(ridersColumn);

      if (_ride!.approved) {
        Widget cancelButton = BigButton(text: "DELETE", onPressed: _showDeleteDialog, color: Colors.red);
        widgets.add(const Divider(
          thickness: 1,
        ));
        widgets.add(cancelButton);
      } else if (_ride!.id == null) {
        Widget requestButton = BigButton(text: "REQUEST RIDE", onPressed: () {}, color: Theme.of(context).primaryColor);
        widgets.add(const Divider(
          thickness: 1,
        ));
        widgets.add(requestButton);
      } else {
        Widget requestButton = const BigButton(text: "RIDE REQUESTED", color: Colors.grey);
        widgets.add(const Divider(
          thickness: 1,
        ));
        widgets.add(requestButton);
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Detail'),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat),
          )
        ],
      ),
      body: _ride == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadRide,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widgets,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReviewsColumn(Profile driver) {
    List<Review> reviews = driver.reviewsReceived ?? [];
    AggregateReview aggregateReview = AggregateReview.fromReviews(reviews);

    return Column(children: [
      Row(
        children: [
          Text("Rating: ${aggregateReview.rating.toStringAsFixed(1)}"),
          const SizedBox(width: 10),
          CustomRatingBarIndicator(rating: aggregateReview.rating)
        ],
      ),
      Row(
        children: [
          Column(
            children: [
              Row(children: [
                Text("Comfort: ${aggregateReview.comfortRating.toStringAsFixed(1)}"),
                const SizedBox(width: 10),
                CustomRatingBarIndicator(rating: aggregateReview.comfortRating)
              ]),
              Row(children: [
                Text("Safety: ${aggregateReview.safetyRating.toStringAsFixed(1)}"),
                const SizedBox(width: 10),
                CustomRatingBarIndicator(rating: aggregateReview.safetyRating)
              ]),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Row(children: [
                Text("Reliability: ${aggregateReview.reliabilityRating.toStringAsFixed(1)}"),
                const SizedBox(width: 10),
                CustomRatingBarIndicator(rating: aggregateReview.reliabilityRating)
              ]),
              Row(children: [
                Text("Hospitality: ${aggregateReview.hospitalityRating.toStringAsFixed(1)}"),
                const SizedBox(width: 10),
                CustomRatingBarIndicator(rating: aggregateReview.hospitalityRating)
              ]),
            ],
          ),
        ],
      ),
    ]);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this ride?"),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              _ride!.cancel();
              Navigator.of(context).pop();
              Navigator.of(context).maybePop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ride deleted"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
