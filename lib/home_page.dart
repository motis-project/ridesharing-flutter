import 'package:flutter/material.dart';

import 'util/buttons/button.dart';
import 'util/chat/models/message.dart';
import 'util/ride_event.dart';
import 'util/supabase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<List<RideEvent>> _events;
  late Stream<List<Message>> _messages;

  @override
  void initState() {
    load();

    super.initState();
  }

  Future<void> load() async {
    final int? profileId = SupabaseManager.getCurrentProfile()!.id;
    _events = SupabaseManager.supabaseClient
        .from('ride_events')
        .stream(primaryKey: <String>['id'])
        //rls only allows to select ride_events the User is a part of (rider or driver)
        .eq('read', false)
        .order('created_at')
        .map(
          (List<Map<String, dynamic>> rideEvents) => RideEvent.fromJsonList(
              rideEvents.where((Map<String, dynamic> rideEvent) => rideEvent['sender_id'] != profileId).toList()),
        );
    _messages =
        SupabaseManager.supabaseClient.from('messages').stream(primaryKey: <String>['id']).eq('read', false).map(
              (List<Map<String, dynamic>> messages) => Message.fromJsonList(
                  messages.where((Map<String, dynamic> rideEvent) => rideEvent['sender_id'] != profileId).toList()),
            );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: Text(S.of(context).homePageTitle),
          ),
      body: Center(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Hero(
                  tag: 'SearchButton',
                  transitionOnUserGestures: true,
                  child: Button.submit(
                    '',
                    // S.of(context).searchRideButton,
                    // onPressed: () => Navigator.of(context).push(
                    //   MaterialPageRoute<void>(builder: (BuildContext context) => const SearchRidePage()),
                    // ),
                  ),
                ),
                const SizedBox(width: 10),
                Hero(
                  tag: 'createButton',
                  transitionOnUserGestures: true,
                  child: Button.submit(
                    '',
                    // S.of(context).createDriveButton,
                    // onPressed: () => Navigator.of(context).push(
                    //   MaterialPageRoute<void>(builder: (BuildContext context) => const CreateDrivePage()),
                    // ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
                //anzahl mit supabase von tabelle abfragen

                itemCount: 20,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (BuildContext context, int index) {
                  return buildcard(index, context);
                },
              ),
            )
            // Container(
            //   color: Colors.black,
            //   height: 40,
            //   width: double.infinity,
            //   child: Text("Hallo"),
            // )
          ],
        ),
      ),
    );
  }
}

Widget buildcard(int index, context) => Container(
      color: Colors.blueAccent,
      width: double.infinity,
      height: 50,
      child: const Center(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => DriveDetailPage.fromDrive(trip),
            ),
          ),
        ),
      ),
    );
