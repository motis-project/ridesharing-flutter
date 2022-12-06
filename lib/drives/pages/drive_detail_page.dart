import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/settings/models/profile.dart';
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
    Map<String, dynamic> data = await supabaseClient
        .from('drives')
        .select()
        .eq('id', widget.id)
        .single();

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
            Text(
                "${DateFormat.Hm().format(_drive!.startTime)} ${_drive!.start}"),
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
        profiles: [],
        place: _drive!.start,
        time: _drive!.startTime,
        status: StopStatus.driveStart,
        seats: _drive!.seats,
      ));
    }

    if (_rides != null) {
      for (Ride ride in _rides!) {
        bool startSaved = false;
        bool endSaved = false;
        for (Stop stop in stops) {
          if (ride.start == stop.place && stop.status == StopStatus.rideStart) {
            startSaved = true;
            stop.profiles.add(ride.rider!);
          } else if (ride.end == stop.place &&
              stop.status == StopStatus.rideEnd) {
            endSaved = true;
            stop.profiles.add(ride.rider!);
          }
        }

        if (!startSaved) {
          stops.add(Stop(
            profiles: [ride.rider!],
            place: ride.start,
            time: ride.startTime,
            status: StopStatus.rideStart,
            seats: ride.seats,
          ));
        }

        if (!endSaved) {
          stops.add(Stop(
            profiles: [ride.rider!],
            place: ride.end,
            time: ride.endTime,
            status: StopStatus.rideEnd,
            seats: ride.seats,
          ));
        }
      }
      stops.sort((a, b) {
        int aBeforeB = a.time.compareTo(b.time);
        if (aBeforeB != 0) return aBeforeB;

        return a.status.index.compareTo(b.status.index);
      });

      if (_drive != null) {
        stops.add(Stop(
          profiles: [],
          place: _drive!.end,
          time: _drive!.endTime,
          status: StopStatus.driveEnd,
          seats: _drive!.seats,
        ));
      }
    }

    Widget timeline = FixedTimeline.tileBuilder(
      theme: CustomTimelineTheme.of(context),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.after,
        indicatorBuilder: (context, index) {
          final stop = stops[index];
          return OutlinedDotIndicator(
            color: stop.status == StopStatus.rideStart
                ? Color(0xff6ad192)
                : Color(0xffe6e7e9),
            backgroundColor: stop.status == StopStatus.rideStart
                ? Color(0xffd4f5d6)
                : Color(0xffc2c5c9),
            borderWidth: stop.status == StopStatus.rideStart ? 3.0 : 2.5,
          );
        },
        connectorBuilder: (context, index, type) {
          final stop = stops[index];
          final color =
              stop.status == StopStatus.rideStart ? Color(0xff6ad192) : null;

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
                  children: List.generate(1 + stop.profiles.length, (index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${DateFormat.Hm().format(stop.time)} ",
                              style: DefaultTextStyle.of(context)
                                  .style
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(stop.place),
                          ],
                        ),
                      );
                    }
                    const startIcon =
                        Icon(Icons.north_east, color: Colors.green);
                    const endIcon = Icon(Icons.south_west, color: Colors.red);
                    return Container(
                        decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius:
                                BorderRadius.all(Radius.circular(3.0))),
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                                onTap: () => print("Hey"),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0, vertical: 5.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      stop.status == StopStatus.rideStart
                                          ? startIcon
                                          : endIcon,
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                                child: Text(stop
                                                    .profiles[index - 1]
                                                    .username[0])),
                                            SizedBox(width: 5),
                                            Text(stop
                                                .profiles[index - 1].username)
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
          return (stops[index].profiles.length + 1) * 50.0;
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 5.0),
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

class Stop {
  List<Profile> profiles;
  final String place;
  final DateTime time;
  final StopStatus status;
  final int seats;

  Stop({
    required this.profiles,
    required this.place,
    required this.time,
    required this.status,
    required this.seats,
  });
}
