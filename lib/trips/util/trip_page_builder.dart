import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'trip_stream_builder.dart';

class TripPageBuilder<T> extends StatelessWidget {
  final String title;
  final Map<String, TripStreamBuilder<T>> tabs;
  final FloatingActionButton floatingActionButton;

  const TripPageBuilder({
    super.key,
    required this.title,
    required this.tabs,
    required this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            labelPadding: EdgeInsets.zero,
            labelColor: Theme.of(context).colorScheme.onSurface,
            tabs: tabs.keys.map((String title) => Tab(text: title)).toList(),
          ),
        ),
        body: Semantics(
          sortKey: const OrdinalSortKey(1),
          child: TabBarView(children: tabs.values.toList()),
        ),
        floatingActionButton: Semantics(
          sortKey: const OrdinalSortKey(0),
          child: floatingActionButton,
        ),
      ),
    );
  }
}
