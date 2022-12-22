import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/trip/pending_ride_card.dart';
import '../../util/supabase.dart';
import '../models/drive.dart';

class DriveChatPage extends StatefulWidget {
  final Drive drive;
  const DriveChatPage({required this.drive, super.key});

  @override
  State<DriveChatPage> createState() => _DriveChatPageState();
}

class _DriveChatPageState extends State<DriveChatPage> {
  late Drive _drive;
  late Set<Profile> _riders;
  late Set<Ride> _pendingRides;

  @override
  void initState() {
    super.initState();
    _drive = widget.drive;
    _riders = _drive.approvedRides!.map((ride) => ride.rider!).toSet();
    _pendingRides = _drive.pendingRides!.toSet();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    if (_riders.isEmpty && _pendingRides.isEmpty) {
      widgets.add(const Center(
        child: Text("No riders or pending rides"),
      ));
    } else {
      if (_riders.isNotEmpty) {
        List<Widget> riderColumn = [
          const Text(
            "Riders",
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
          riderList(),
        ];
        widgets.addAll(riderColumn);
      }
      widgets.add(const SizedBox(height: 10.0));
      if (_pendingRides.isNotEmpty) {
        List<Widget> pendingRidesColumn = [
          const Text(
            "Pending Rides",
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
        ];
        pendingRidesColumn.addAll(pendingRidesList());
        widgets.addAll(pendingRidesColumn);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Chat'),
      ),
      body: RefreshIndicator(
        onRefresh: loadDrive,
        child: ListView.separated(
          itemCount: widgets.length,
          itemBuilder: (context, index) {
            return widgets[index];
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 10);
          },
        ),
      ),
    );
  }

  List<Widget> pendingRidesList() {
    List<Widget> pendingRidesColumn = [];
    if (_pendingRides.isNotEmpty) {
      pendingRidesColumn = List.generate(
        _pendingRides.length,
        (index) => PendingRideCard(
          _pendingRides.elementAt(index),
          reloadPage: loadDrive,
          drive: _drive,
        ),
      );
    }
    return pendingRidesColumn;
  }

  Row profileRow(Profile profile) {
    return Row(
      children: [
        CircleAvatar(
          child: Text(profile.username[0]),
        ),
        const SizedBox(width: 5),
        Text(profile.username),
      ],
    );
  }

  Widget riderList() {
    Widget ridersColumn = Container();
    if (_riders.isNotEmpty) {
      ridersColumn = Column(
        children: List.generate(
          _riders.length,
          (index) => InkWell(
            onTap: () => print("Hey"),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  profileRow(_riders.elementAt(index)),
                  const Icon(
                    Icons.chat,
                    color: Colors.black,
                    size: 36.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ridersColumn;
  }

  Future<void> loadDrive() async {
    Map<String, dynamic> data = await supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.drive.id).single();
    setState(() {
      _drive = Drive.fromJson(data);

      _riders = _drive.approvedRides!.map((ride) => ride.rider!).toSet();
      _pendingRides = _drive.pendingRides!.toSet();
    });
  }
}
