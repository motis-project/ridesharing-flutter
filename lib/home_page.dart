import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/buttons/button.dart';
import 'account/widgets/avatar.dart';
import 'drives/pages/create_drive_page.dart';
import 'drives/pages/drive_detail_page.dart';
import 'rides/pages/ride_detail_page.dart';
import 'rides/pages/search_ride_page.dart';
import 'util/chat/models/message.dart';
import 'util/chat/pages/chat_page.dart';
import 'util/model.dart';
import 'util/parse_helper.dart';
import 'util/ride_event.dart';
import 'util/supabase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //needs to be initialized in case the subscription gets something new before load is done
  List<Model> _items = <Model>[];
  bool _fullyLoaded = false;

  @override
  void initState() {
    load();
    final int profileId = SupabaseManager.getCurrentProfile()!.id!;
    SupabaseManager.supabaseClient.channel('public:messages').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages', filter: 'sender_id=neq.$profileId'),
      // ignore: always_specify_types
      (payload, [ref]) {
        // ignore: avoid_dynamic_calls
        if (payload['new']['sender_id'] != profileId) {
          // ignore: avoid_dynamic_calls
          _loadNewMessage(payload['new']['id']);
        }
      },
    ).on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'messages', filter: 'sender_id=neq.$profileId'),

      // ignore: always_specify_types
      (payload, [ref]) {
        // ignore: avoid_dynamic_calls
        if (payload['new']['read'] == true) {
          setState(() {
            _items =
                // ignore: avoid_dynamic_calls
                _items.where((Model element) => element is RideEvent || element.id != payload['new']['id']).toList();
          });
        }
      },
    ).subscribe();
    SupabaseManager.supabaseClient.channel('public:ride_events').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'ride_events'), //, filter: 'sender_id=neq.$profileId'
      // ignore: always_specify_types
      (payload, [ref]) {
        // ignore: avoid_dynamic_calls
        if (payload['new']['sender_id'] != profileId) {
          // ignore: avoid_dynamic_calls
          _loadNewRideEvent(payload['new']['id']);
        }
      },
    ).on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'ride_events'), //, filter: 'sender_id=neq.$profileId'
      // ignore: always_specify_types
      (payload, [ref]) {
        // ignore: avoid_dynamic_calls
        if (payload['new']['read'] == true) {
          setState(() {
            // ignore: avoid_dynamic_calls
            _items = _items.where((Model element) => element is Message || element.id != payload['new']['id']).toList();
          });
        }
      },
    ).subscribe();

    super.initState();
  }

  @override
  void dispose() {
    SupabaseManager.supabaseClient.removeAllChannels();
    super.dispose();
  }

  Future<void> load() async {
    final List<Model> items = <Model>[];
    final int profileId = SupabaseManager.getCurrentProfile()!.id!;
    final List<Map<String, dynamic>> messagesData = parseHelper.parseListOfMaps(
      await SupabaseManager.supabaseClient.from('messages').select('''
      *,
      sender: sender_id(*)
      )
    ''').eq('read', false).neq('sender_id', profileId).order('created_at'),
    );
    items.addAll(Message.fromJsonList(messagesData));
    final List<Map<String, dynamic>> rideEventsData = parseHelper.parseListOfMaps(
      await SupabaseManager.supabaseClient.from('ride_events').select('''
      *,
      ride: ride_id(*,
        rider: rider_id(*),
        drive: drive_id(*,
          driver: driver_id(*)
          )
      )
      ''').eq('read', false).order('created_at'),
    );
    items.addAll(RideEvent.fromJsonList(rideEventsData).where((RideEvent rideEvent) => rideEvent.isForCurrentUser()));
    items.sort((Model a, Model b) => b.createdAt!.compareTo(a.createdAt!));

    setState(() {
      _items = items;
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageHomeTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 30),
            if (_fullyLoaded)
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  ),
                  child: _items.isNotEmpty
                      ? ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (BuildContext context, int index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (BuildContext context, int index) {
                            return _buildWidget(_items[index], context);
                          },
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset(
                              'assets/chat_shrug.png',
                              scale: 8,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              S.of(context).pageHomePageEmpty,
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            const SizedBox(height: 3),
                          ],
                        ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 35),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Hero(
                  tag: 'SearchButton',
                  transitionOnUserGestures: true,
                  child: Button(
                    S.of(context).pageHomeSearchButton,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (BuildContext context) => const SearchRidePage()),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Hero(
                  tag: 'createButton',
                  transitionOnUserGestures: true,
                  child: Button(
                    S.of(context).pageHomeCreateButton,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (BuildContext context) => const CreateDrivePage()),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNewRideEvent(int rideEventId) async {
    final Map<String, dynamic> data = await SupabaseManager.supabaseClient.from('ride_events').select('''
      *,
      ride: ride_id(*,
        rider: rider_id(*),
        drive: drive_id(*,
          driver: driver_id(*)
          )
      )
      ''').eq('id', rideEventId).single();
    final RideEvent rideEvent = RideEvent.fromJson(data);
    if (rideEvent.isForCurrentUser()) {
      setState(() {
        _items.insert(0, rideEvent);
      });
    }
  }

  Future<void> _loadNewMessage(int messageId) async {
    final Map<String, dynamic> data = await SupabaseManager.supabaseClient.from('messages').select('''
      *,
      sender: sender_id(*)
      )
    ''').eq('id', messageId).single();
    final Message message = Message.fromJson(data);
    if (message.read == false) {
      setState(() {
        _items.insert(0, message);
      });
    }
  }

  Card _buildMessageWidget(Message message, BuildContext context) {
    return Card(
      child: InkWell(
        child: ListTile(
          leading: Avatar(message.sender!),
          title: Text(message.sender!.username),
          subtitle: Text(message.content),
          trailing: Text(
            DateFormat('HH:mm').format(message.createdAt!),
            style: Theme.of(context).textTheme.caption,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => ChatPage(
                  chatId: message.chatId,
                  profile: message.sender!,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRideEventWidget(RideEvent rideEvent, BuildContext context) {
    final bool isforDrive = rideEvent.ride!.riderId != SupabaseManager.getCurrentProfile()!.id!;
    return Card(
      child: InkWell(
        child: ListTile(
          leading: isforDrive ? const Icon(Icons.drive_eta) : const Icon(Icons.chair),
          title: Text(rideEvent.getTitle(context)),
          subtitle: Text(rideEvent.getMessage(context)),
          trailing: Text(
            DateFormat('HH:mm').format(rideEvent.createdAt!),
            style: Theme.of(context).textTheme.caption,
          ),
          onTap: () {
            rideEvent.markAsRead();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    isforDrive ? DriveDetailPage(id: rideEvent.ride!.driveId) : RideDetailPage(id: rideEvent.rideId),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWidget(Model model, BuildContext context) {
    if (model is Message) {
      return _buildMessageWidget(model, context);
    } else if (model is RideEvent) {
      return _buildRideEventWidget(model, context);
    } else {
      throw Exception('Unknown model type');
    }
  }
}
