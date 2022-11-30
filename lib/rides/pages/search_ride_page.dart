import 'package:flutter/material.dart';
import 'package:flutter_app/rides/forms/search_ride_form.dart';

class SearchRidePage extends StatefulWidget {
  const SearchRidePage({Key? key}) : super(key: key);

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
      body: const Padding(
        padding: EdgeInsets.symmetric(),
        child: SingleChildScrollView(child: SearchRideForm()),
      ),
    );
  }
}
