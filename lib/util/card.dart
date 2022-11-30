import 'package:flutter/material.dart';
import 'package:flutter_app/drives/pages/drive_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';

import '../drives/models/drive.dart';

class DriveCard extends StatelessWidget {
  final Drive drive;

  const DriveCard({super.key, required this.drive});

  String _formatTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DriveDetailPage(),
          ),
        ),
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
                    Text('${_formatTime(drive.startTime)}  ${drive.start}'),
                    Text(_formatDate(drive.startTime)),
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
                    Text('${_formatTime(drive.endTime)}  ${drive.end}'),
                  ],
                ),
              ),
              node: const TimelineNode(
                indicator: OutlinedDotIndicator(),
                startConnector: SolidLineConnector(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TestTimeline extends StatelessWidget {
  const TestTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Timeline.tileBuilder(
      builder: TimelineTileBuilder.fromStyle(
        contentsBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Timeline Event $index'),
        ),
        itemCount: 2,
      ),
    );
  }
}
