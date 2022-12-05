import 'package:flutter/material.dart';

class SearchRidePage extends StatefulWidget {
  const SearchRidePage({super.key});

  @override
  State<SearchRidePage> createState() => _SearchRidePageState();
}

class _SearchRidePageState extends State<SearchRidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Ride'),
      ),
      body: const Center(
        child: Text('Search Ride'),
      ),
    );
  }
}
