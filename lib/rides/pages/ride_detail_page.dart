import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/account/models/review.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/util/custom_timeline_theme.dart';
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

      Widget cancelButton = BigButton(text: "DELETE", onPressed: _showDeleteDialog, color: Colors.red);
      widgets.add(const Divider(
        thickness: 1,
      ));
      widgets.add(cancelButton);
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
    List<Review> reviews = driver.reviewsReceived!;

    print(reviews.length);

    double averageStars =
        reviews.isEmpty ? 0 : reviews.map((review) => review.stars).reduce((a, b) => a + b) / reviews.length;

    List<Review> comfortReviews = reviews.where((review) => review.comfortStars != null).toList();
    double averageComfortStars = comfortReviews.isEmpty
        ? 0
        : comfortReviews.map((review) => review.comfortStars!).reduce((a, b) => a + b) / comfortReviews.length;

    List<Review> safetyReviews = reviews.where((review) => review.safetyStars != null).toList();
    double averageSafetyStars = safetyReviews.isEmpty
        ? 0
        : safetyReviews.map((review) => review.safetyStars!).reduce((a, b) => a + b) / safetyReviews.length;

    List<Review> reliabilityReviews = reviews.where((review) => review.reliabilityStars != null).toList();
    double averageReliabilityStars = reliabilityReviews.isEmpty
        ? 0
        : reliabilityReviews.map((review) => review.reliabilityStars!).reduce((a, b) => a + b) /
            reliabilityReviews.length;

    List<Review> hospitalityReviews = reviews.where((review) => review.hospitalityStars != null).toList();
    double averageHospitalityStars = hospitalityReviews.isEmpty
        ? 0
        : hospitalityReviews.map((review) => review.hospitalityStars!).reduce((a, b) => a + b) /
            hospitalityReviews.length;
    return Column(children: [
      Text("Average stars: ${averageStars.toStringAsFixed(1)}"),
      Text("Average comfort stars: ${averageComfortStars.toStringAsFixed(1)}"),
      Text("Average safety stars: ${averageSafetyStars.toStringAsFixed(1)}"),
      Text("Average reliability stars: ${averageReliabilityStars.toStringAsFixed(1)}"),
      Text("Average hospitality stars: ${averageHospitalityStars.toStringAsFixed(1)}"),
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
