import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/util/custom_timeline_theme.dart';
import 'package:flutter_app/util/profiles/profile_chip.dart';
import 'package:flutter_app/util/profiles/profile_row.dart';
import 'package:flutter_app/util/profiles/profile_wrap_list.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/trip/trip_overview.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';

class DriveDetailPage extends StatefulWidget {
  final int id;
  final Drive? drive;

  const DriveDetailPage({super.key, required this.id}) : drive = null;
  DriveDetailPage.fromDrive(this.drive, {super.key}) : id = drive!.id!;

  @override
  State<DriveDetailPage> createState() => _DriveDetailPageState();
}

class _DriveDetailPageState extends State<DriveDetailPage> {
  Drive? _drive;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _drive = widget.drive;
    });

    loadDrive();
  }

  Future<void> loadDrive() async {
    Map<String, dynamic> data = await supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.id).single();

    setState(() {
      _drive = Drive.fromJson(data);
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    if (_drive != null) {
      Widget overview = TripOverview(_drive!);
      widgets.add(overview);
      widgets.add(const Divider(thickness: 1));
    }

    if (_fullyLoaded) {
      List<Waypoint> stops = [];
      stops.add(Waypoint(
        actions: [],
        place: _drive!.start,
        time: _drive!.startTime,
      ));
      stops.add(Waypoint(
        actions: [],
        place: _drive!.end,
        time: _drive!.endTime,
      ));

      for (Ride ride in _drive!.rides!) {
        bool startSaved = false;
        bool endSaved = false;

        WaypointAction rideStartAction = WaypointAction(profile: ride.rider!, isStart: true, seats: ride.seats);
        WaypointAction rideEndAction = WaypointAction(profile: ride.rider!, isStart: false, seats: ride.seats);
        for (Waypoint stop in stops) {
          if (ride.start == stop.place) {
            startSaved = true;
            stop.actions.add(rideStartAction);
          } else if (ride.end == stop.place) {
            endSaved = true;
            stop.actions.add(rideEndAction);
          }
        }

        if (!startSaved) {
          stops.add(Waypoint(
            actions: [rideStartAction],
            place: ride.start,
            time: ride.startTime,
          ));
        }

        if (!endSaved) {
          stops.add(Waypoint(
            actions: [rideEndAction],
            place: ride.end,
            time: ride.endTime,
          ));
        }
      }

      stops.sort((a, b) => a.time.compareTo(b.time));
      for (Waypoint stop in stops) {
        stop.actions.sort((a, b) => a.isStart ? 1 : -1);
      }

      Widget timeline = FixedTimeline.tileBuilder(
        theme: CustomTimelineThemeForBuilder.of(context),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          indicatorBuilder: (context, index) => const CustomOutlinedDotIndicator(),
          connectorBuilder: (context, index, type) => const CustomSolidLineConnector(),
          contentsBuilder: (context, index) {
            final stop = stops[index];
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                children: [
                  const SizedBox(height: 10.0),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 1.0, color: Colors.grey.shade500),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: buildCard(stop),
                    ),
                  ),
                  const SizedBox(height: 10.0)
                ],
              ),
            );
          },
          itemCount: stops.length,
        ),
      );
      widgets.add(timeline);

      if (_drive!.rides != null) {
        widgets.add(const Divider(
          thickness: 1,
        ));

        Set<Profile> riders = _drive!.rides!.map((ride) => ride.rider!).toSet();
        widgets.add(ProfileWrapList(riders, title: 'Riders'));

        Widget deleteButton = BigButton(text: "DELETE", onPressed: _showDeleteDialog, color: Colors.red);
        widgets.add(const Divider(
          thickness: 1,
        ));
        widgets.add(deleteButton);
        widgets.add(const SizedBox(height: 5));
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Detail'),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat),
          )
        ],
      ),
      body: _drive == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDrive,
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

  List<Widget> buildCard(Waypoint stop) {
    List<Widget> list = [];
    list.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.Hm().format(stop.time),
              style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4.0),
            Text(stop.place),
          ],
        ),
      ),
    );

    final startIcon = Icon(Icons.north_east_rounded, color: Colors.green.shade700);
    const endIcon = Icon(Icons.south_west_rounded, color: Colors.red);
    for (int index = 0, length = stop.actions.length; index < length; index++) {
      final action = stop.actions[index];
      final icon = action.isStart ? startIcon : endIcon;
      final profile = action.profile;

      Widget container = Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => print("Hey"),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: action.seats <= 2
                              ? List.generate(action.seats, (index) => icon)
                              : [
                                  icon,
                                  const SizedBox(width: 2),
                                  Text("x${action.seats}"),
                                ]),
                    ),
                  ),
                  ProfileRow(profile, size: 15),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.chat,
                        color: Colors.black,
                        size: 30.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      list.add(container);

      if (index < length - 1) {
        list.add(const SizedBox(height: 6.0));
      }
    }

    return list;
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this drive?"),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              _drive!.cancel();
              Navigator.of(context).pop();
              Navigator.of(context).maybePop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Drive deleted"),
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

class WaypointAction {
  final Profile profile;
  final bool isStart;
  final int seats;

  WaypointAction({required this.profile, required this.isStart, required this.seats});
}

class Waypoint {
  List<WaypointAction> actions;
  final String place;
  final DateTime time;

  Waypoint({
    required this.actions,
    required this.place,
    required this.time,
  });
}
