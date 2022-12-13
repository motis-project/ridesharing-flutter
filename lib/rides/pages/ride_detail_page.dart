import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/util/custom_timeline_theme.dart';
import 'package:flutter_app/util/profiles/profile_row.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/trip/trip_overview.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';

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
        driver: driver_id(*),
        rides(
          *,
          rider: rider_id(*)
        )
      )
    ''').eq('id', widget.id).single();

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
