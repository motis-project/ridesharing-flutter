import 'package:flutter/material.dart';
import 'package:flutter_app/rides/pages/search_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/submit_button.dart';

class SearchDealPage extends StatefulWidget {
  const SearchDealPage(this.start, this.end, this.date, this.seats, {super.key});

  final String start;
  final String end;
  final int seats;
  final DateTime date;

  @override
  State<SearchDealPage> createState() => _SearchDealPageState(this.start, this.end, this.date, this.seats);
}

class _SearchDealPageState extends State<SearchDealPage> {
  String start;
  String end;
  int seats;
  DateTime date;
  _SearchDealPageState(this.start, this.end, this.date, this.seats);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Ride'),
      ),
      body: Column(
        children: [
          //todo Ansicht der Momentanen Suche
          Container(
            padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,  // red as border color
                ),
              ),
              child: Text("Your text...")
          ),
          //todo filter der Suchergebnisse
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(500, 20),
                maximumSize: const Size(500, 20),
              ),
              onPressed: null,
              child:Text("Filter")
          ),
          Expanded(
            child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: 10,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  return const SearchCard();
                },
              ),
          ),
        ],
      ),
    );
  }
}
