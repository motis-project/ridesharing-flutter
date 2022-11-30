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

    List<Widget> widgets = [
      FixedTimeline(
        theme: CustomTimelineTheme.of(context),
        children: [startTimelineTile, stopTimelineTile],
      ),
    ];

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

      // nodes.addAll(
      //   stops.map(
      //     (stop) => TimelineTile(
      //       contents: Padding(
      //         padding: const EdgeInsets.all(16.0),
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: [
      //             Text("${DateFormat.Hm().format(stop.time)} ${stop.place}"),
      //             const Icon(
      //               Icons.chat,
      //               color: Colors.black,
      //               size: 36.0,
      //             ),
      //           ],
      //         ),
      //       ),
      //       node: TimelineNode(
      //         overlap: true,
      //         indicator: OutlinedDotIndicator(),
      //         startConnector: Random().nextBool()
      //             ? SolidLineConnector()
      //             : DashedLineConnector(),
      //         endConnector: SolidLineConnector(),
      //       ),
      //     ),
      //   ),
      // );
      if (_drive != null) {
        stops.add(Stop(
          profiles: [],
          place: _drive!.end,
          time: _drive!.endTime,
          status: StopStatus.driveEnd,
          seats: _drive!.seats,
        ));
      }

      widgets.add(const Divider(
        thickness: 1,
      ));
    }

    Timeline timeline = Timeline.tileBuilder(
      theme: CustomTimelineTheme.of(context),
      padding: const EdgeInsets.only(top: 20.0),
      builder: TimelineTileBuilder.connected(
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
          return SizedBox(
            height: 60.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${DateFormat.Hm().format(stop.time)} ${stop.place}"),
                const Icon(
                  Icons.chat,
                  color: Colors.black,
                  size: 36.0,
                ),
              ],
            ),
          );
        },
        itemCount: stops.length,
      ),
    );

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
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    startTimelineTile,
                    Divider(thickness: 1),
                    Row(children: [timeline]),
                  ],
                ),
              ),
            ),
    );
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
