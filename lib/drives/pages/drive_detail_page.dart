import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/custom_timeline_theme.dart';
import 'package:flutter_app/util/supabase.dart';
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
  List<Ride>? _rides;

  @override
  void initState() {
    super.initState();

    setState(() {
      _drive = widget.drive;
    });

    loadDrive();
  }

  Future<void> loadDrive() async {
    Map<String, dynamic> data = await supabaseClient.from('drives').select().eq('id', widget.id).single();

    List<dynamic> ridesData = await supabaseClient.from('rides').select('''
          *,
          rider:rider_id (*)
        ''').eq('drive_id', widget.id).order('start_time', ascending: true);

    setState(() {
      _drive = Drive.fromJson(data);
      _rides = Ride.fromJsonList(ridesData);
    });
  }

  @override
  Widget build(BuildContext context) {
    TimelineTile startTimelineTile = TimelineTile(
      contents: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${DateFormat.Hm().format(_drive!.startTime)} ${_drive!.start}"),
          ],
        ),
      ),
      node: const TimelineNode(
        indicator: OutlinedDotIndicator(),
        endConnector: SolidLineConnector(),
      ),
    );

    TimelineTile stopTimelineTile = TimelineTile(
      contents: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${DateFormat.Hm().format(_drive!.endTime)} ${_drive!.end}"),
            Text('3/${_drive!.seats} Seats'),
          ],
        ),
      ),
      node: const TimelineNode(
        indicator: OutlinedDotIndicator(),
        startConnector: SolidLineConnector(),
      ),
    );

    Widget shortTimeline = FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: [startTimelineTile, stopTimelineTile],
    );

    List<Stop> stops = [];
    if (_drive != null) {
      stops.add(Stop(
        actions: [StopAction(profile: SupabaseManager.getCurrentProfile()!, status: StopStatus.driveStart, seats: 0)],
        place: _drive!.start,
        time: _drive!.startTime,
      ));
      stops.add(Stop(
        actions: [StopAction(profile: SupabaseManager.getCurrentProfile()!, status: StopStatus.driveEnd, seats: 0)],
        place: _drive!.end,
        time: _drive!.endTime,
      ));
    }

    if (_rides != null) {
      for (Ride ride in _rides!) {
        bool startSaved = false;
        bool endSaved = false;
        for (Stop stop in stops) {
          if (ride.start == stop.place) {
            startSaved = true;
            stop.actions.add(StopAction(profile: ride.rider!, status: StopStatus.rideStart, seats: ride.seats));
          } else if (ride.end == stop.place) {
            endSaved = true;
            stop.actions.add(StopAction(profile: ride.rider!, status: StopStatus.rideEnd, seats: ride.seats));
          }
        }

        if (!startSaved) {
          stops.add(Stop(
            actions: [StopAction(profile: ride.rider!, status: StopStatus.rideStart, seats: ride.seats)],
            place: ride.start,
            time: ride.startTime,
          ));
        }

        if (!endSaved) {
          stops.add(Stop(
            actions: [StopAction(profile: ride.rider!, status: StopStatus.rideEnd, seats: ride.seats)],
            place: ride.end,
            time: ride.endTime,
          ));
        }
      }
      stops.sort((a, b) => a.time.compareTo(b.time));
    }

    Widget timeline = FixedTimeline.tileBuilder(
      theme: CustomTimelineTheme.of(context),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.after,
        indicatorBuilder: (context, index) {
          final stop = stops[index];
          return OutlinedDotIndicator(
            color: Color(0xff6ad192),
            backgroundColor: Color(0xffd4f5d6),
            borderWidth: 3.0,
          );
        },
        connectorBuilder: (context, index, type) {
          final stop = stops[index];
          final color = Color(0xff6ad192);

          return SolidLineConnector(
            color: color,
          );
        },
        contentsBuilder: (context, index) {
          final stop = stops[index];
          return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(1 + stop.actions.length, (index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${DateFormat.Hm().format(stop.time)} ",
                              style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(stop.place),
                          ],
                        ),
                      );
                    }
                    const startIcon = Icon(Icons.north_east, color: Colors.green);
                    const endIcon = Icon(Icons.south_west, color: Colors.red);
                    return Container(
                        decoration: const BoxDecoration(
                            color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(3.0))),
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                                onTap: () => print("Hey"),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      stop.actions[index - 1].status == StopStatus.rideStart ? startIcon : endIcon,
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        CircleAvatar(child: Text(stop.actions[index - 1].profile.username[0])),
                                        SizedBox(width: 5),
                                        Text(stop.actions[index - 1].profile.username)
                                      ]),
                                      const Icon(
                                        Icons.chat,
                                        color: Colors.black,
                                        size: 36.0,
                                      ),
                                    ],
                                  ),
                                ))));
                  })));
        },
        itemExtentBuilder: (context, index) {
          return (stops[index].actions.length + 1) * 50.0;
        },
        itemCount: stops.length,
      ),
    );

    List<Widget> widgets = [
      shortTimeline,
      Divider(thickness: 1),
      timeline,
    ];

    Widget ridersColumn = Container();
    if (_rides != null) {
      List<Profile> riders = [];
      for (Ride ride in _rides!) {
        if (ride.rider != null && !riders.contains(ride.rider)) {
          riders.add(ride.rider!);
        }
      }
      ridersColumn = Column(
        children: List.generate(
            riders.length,
            (index) => InkWell(
                onTap: () => print("Hey"),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(child: Text(riders[index].username[0])),
                        SizedBox(width: 5),
                        Text(riders[index].username)
                      ]),
                      const Icon(
                        Icons.chat,
                        color: Colors.black,
                        size: 36.0,
                      ),
                    ],
                  ),
                ))),
      );
      widgets.add(const Divider(
        thickness: 1,
      ));
      widgets.add(ridersColumn);
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widgets,
                    ),
                  ),
                ),
              ));
  }
}

// ATTENTION: Order is important (we show ride ends before starts)
enum StopStatus {
  driveStart,
  rideEnd,
  rideStart,
  driveEnd,
}

class StopAction {
  final Profile profile;
  final StopStatus status;
  final int seats;

  StopAction({required this.profile, required this.status, required this.seats});
}

class Stop {
  List<StopAction> actions;
  final String place;
  final DateTime time;

  Stop({
    required this.actions,
    required this.place,
    required this.time,
  });
}
