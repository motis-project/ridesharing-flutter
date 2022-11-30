import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/rides/forms/search_ride_form.dart';

class SearchDealPage extends StatefulWidget {
  const SearchDealPage({Key? key}) : super(key: key);

  @override
  State<SearchDealPage> createState() => _SearchDealPageState();
}

class _SearchDealPageState extends State<SearchDealPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Ride'),
      ),
      body: ListView(

      ),
    );
  }
}
