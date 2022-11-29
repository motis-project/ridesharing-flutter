import 'package:flutter/material.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';

class DriveDetailPage extends StatefulWidget {
  final int id;
  final Drive? drive;

  const DriveDetailPage({super.key, required this.id}) : drive = null;
  DriveDetailPage.fromDrive({super.key, required this.drive}) : id = drive!.id!;

  @override
  State<DriveDetailPage> createState() => _DriveDetailPageState();
}

class _DriveDetailPageState extends State<DriveDetailPage> {
  Drive? _drive;

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

    setState(() {
      _drive = Drive.fromJson(data);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                child: FixedTimeline(
                  theme: TimelineTheme.of(context).copyWith(
                    nodePosition: 0.05,
                    color: Colors.black,
                  ),
                  children: [
                    TimelineTile(
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
                    ),
                    TimelineTile(
                      contents: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "${DateFormat.Hm().format(_drive!.endTime)} ${_drive!.end}"),
                            Text('3/${_drive!.seats} Seats'),
                          ],
                        ),
                      ),
                      node: const TimelineNode(
                        indicator: OutlinedDotIndicator(),
                        startConnector: SolidLineConnector(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
