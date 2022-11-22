import 'package:flutter/material.dart';

class MyScaffold extends StatelessWidget {
  const MyScaffold(
      {super.key, this.appBar, this.body, this.floatingActionButton});

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          AppBar(
            title: const Text('Motis Mitfahr-App'),
          ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
