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
            const Icon(
              Icons.chat,
              color: Colors.black,
              size: 36.0,
            ),
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

    if (_rides != null) {
      List<Stop> stops = [];
      for (Ride ride in _rides!) {
        bool startSaved = false;
        bool endSaved = false;
        for (Stop stop in stops) {
          if (ride.start == stop.place && stop.isStart) {
            startSaved = true;
            stop.profiles.add(ride.rider!);
          } else if (ride.end == stop.place && !stop.isStart) {
            endSaved = true;
            stop.profiles.add(ride.rider!);
          }
        }

        if (!startSaved) {
          stops.add(Stop(
            profiles: [ride.rider!],
            place: ride.start,
            time: ride.startTime,
            isStart: true,
            seats: ride.seats,
          ));
        }

        if (!endSaved) {
          stops.add(Stop(
            profiles: [ride.rider!],
            place: ride.end,
            time: ride.endTime,
            isStart: false,
            seats: ride.seats,
          ));
        }
      }
      stops.sort((a, b) {
        int aBeforeB = a.time.compareTo(b.time);
        if (aBeforeB != 0) return aBeforeB;
        return a.isStart ? 1 : -1;
      });

      List<TimelineTile> nodes = [startTimelineTile];
      nodes.addAll(
        stops.map(
          (stop) => TimelineTile(
            contents: Padding(
              padding: const EdgeInsets.all(16.0),
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
            ),
            node: const TimelineNode(
              indicator: OutlinedDotIndicator(),
              startConnector: SolidLineConnector(),
              endConnector: SolidLineConnector(),
            ),
          ),
        ),
      );
      nodes.add(stopTimelineTile);

      Widget stopsTimeline = FixedTimeline(
        theme: CustomTimelineTheme.of(context),
        children: nodes,
      );

      widgets.add(const Divider());
      widgets.add(stopsTimeline);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Detail'),
      ),
      body: _drive == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDrive,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: widgets,
                ),
              ),
            ),
    );
  }
}

class Stop {
  List<Profile> profiles;
  final String place;
  final DateTime time;
  final bool isStart;
  final int seats;

  Stop({
    required this.profiles,
    required this.place,
    required this.time,
    required this.isStart,
    required this.seats,
  });
}
