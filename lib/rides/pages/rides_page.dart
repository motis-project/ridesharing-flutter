import 'package:flutter/material.dart';
import 'package:flutter_app/rides/pages/search_ride_page.dart';
import 'package:flutter_app/rides/pages/search_deals_page.dart';


class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rides'),
      ),
      body: const Center(
        child: Text('Rides'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            // direction to SearchRidePage()
            MaterialPageRoute(builder: (context) => const SearchRidePage()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.search),
      ),
    );
  }
}
