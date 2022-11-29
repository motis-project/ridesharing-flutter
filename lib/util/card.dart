import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

class DriveCard extends StatelessWidget {
  const DriveCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
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
                  children: const [
                    Text('12:30 Start'),
                    Icon(
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
                  children: const [
                    Text('14:30 Destination'),
                    Text('3/4 Seats'),
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
