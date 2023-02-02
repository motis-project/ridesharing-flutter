import 'dart:async';

import 'package:deep_pick/deep_pick.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/buttons/button.dart';
import 'account/widgets/avatar.dart';
import 'drives/models/drive.dart';
import 'drives/pages/create_drive_page.dart';
import 'drives/pages/drive_detail_page.dart';
import 'rides/models/ride.dart';
import 'rides/pages/ride_detail_page.dart';
import 'rides/pages/search_ride_page.dart';
import 'util/chat/models/message.dart';
import 'util/chat/pages/chat_page.dart';
import 'util/locale_manager.dart';
import 'util/model.dart';
import 'util/parse_helper.dart';
import 'util/ride_event.dart';
import 'util/supabase.dart';
import 'util/trip/trip.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //needs to be initialized in case the subscription gets something new before load is done
  List<Model> _items = <Model>[];
  bool _fullyLoaded = false;
  int _upcomingTripsCount = 0;
  late RealtimeChannel _messagesSubscriptions;
  late RealtimeChannel _rideEventsSubscriptions;
  late RealtimeChannel _ridesSubscriptions;
  late RealtimeChannel _drivesSubscriptions;

  @override
  void initState() {
    load();
    final int profileId = SupabaseManager.getCurrentProfile()!.id!;

    _messagesSubscriptions = SupabaseManager.supabaseClient.channel('public:messages').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages', filter: 'sender_id=neq.$profileId'),
      (dynamic payload, [dynamic ref]) {
        if (pick(pick(payload, 'new').asMapOrEmpty(), 'sender_id').asIntOrThrow() != profileId) {
          _loadNewMessage(pick(pick(payload, 'new').asMapOrEmpty(), 'id').asIntOrThrow());
        }
      },
    ).on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'messages', filter: 'sender_id=neq.$profileId'),
      (dynamic payload, [dynamic ref]) {
        if (pick(pick(payload, 'new').asMapOrEmpty(), 'read').asBoolOrThrow() == true) {
          setState(() {
            _items.removeWhere(
              (Model element) =>
                  element is Message && element.id == pick(pick(payload, 'new').asMapOrEmpty(), 'id').asIntOrThrow(),
            );
          });
        }
      },
    );

    _rideEventsSubscriptions = SupabaseManager.supabaseClient.channel('public:ride_events').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'ride_events'),
      (dynamic payload, [dynamic ref]) {
        _loadNewRideEvent(pick(pick(payload, 'new').asMapOrEmpty(), 'id').asIntOrThrow());
      },
    ).on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'ride_events'),
      (dynamic payload, [dynamic ref]) {
        if (pick(pick(payload, 'new').asMapOrEmpty(), 'read').asBoolOrThrow()) {
          setState(() {
            _items.removeWhere(
              (Model element) =>
                  element is RideEvent && element.id == pick(pick(payload, 'new').asMapOrEmpty(), 'id').asIntOrThrow(),
            );
          });
        }
      },
    );
    final DateTime now = DateTime.now();

    _ridesSubscriptions = SupabaseManager.supabaseClient.channel('public:rides').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'rides', filter: 'rider_id=eq.$profileId'),
      (dynamic payload, [dynamic ref]) {
        final Map<String, dynamic> rideData = pick(payload, 'new').asMapOrEmpty();
        final DateTime startTime = DateTime.parse(rideData['start_time']);
        if (startTime.isAfter(now) && startTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
          if (rideData['status'] == RideStatus.approved.index) {
            setState(() {
              for (int i = 0; i <= _upcomingTripsCount; i++) {
                if (_items is! Trip || (_items[i] as Trip).startTime.isAfter(startTime)) {
                  _items.insert(i, Ride.fromJson(rideData));
                  break;
                }
              }
              _upcomingTripsCount++;
            });
          } else {
            setState(() {
              final List<Model> ride = _items
                  .where(
                    (Model element) => element is Ride && element.id == rideData['id'],
                  )
                  .toList();
              if (ride.isNotEmpty) {
                _items.remove(ride.first);
                _upcomingTripsCount--;
              }
              final List<RideEvent> events = _items
                  .where((Model element) => element is RideEvent && element.rideId == rideData['id'])
                  .map((Model e) => e as RideEvent)
                  .toList();
              _items.removeWhere((Model element) => events.contains(element));
              for (final RideEvent event in events) {
                event.markAsRead();
              }
            });
          }
        }
      },
    );

    _drivesSubscriptions = SupabaseManager.supabaseClient.channel('public:drives').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'drives',
        filter: 'driver_id=eq.$profileId',
      ),
      (dynamic payload, [dynamic ref]) {
        final Map<String, dynamic> driveData = pick(payload, 'new').asMapOrEmpty();
        final DateTime startTime = DateTime.parse(driveData['start_time']);
        if (startTime.isAfter(now) && startTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
          setState(() {
            for (int i = 0; i <= _upcomingTripsCount; i++) {
              if (_items is! Trip || (_items[i] as Trip).startTime.isAfter(startTime)) {
                _items.insert(i, Drive.fromJson(driveData));
                break;
              }
            }
            _upcomingTripsCount++;
          });
        }
      },
    ).on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'drives',
        filter: 'driver_id=eq.$profileId',
      ),
      (dynamic payload, [dynamic ref]) {
        final Map<String, dynamic> driveData = pick(payload, 'new').asMapOrEmpty();
        final DateTime startTime = DateTime.parse(driveData['start_time']);
        if (driveData['cancelled'] == true &&
            startTime.isAfter(now) &&
            startTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
          setState(() {
            final List<Model> drive = _items
                .where(
                  (Model element) => element is Drive && element.id == driveData['id'],
                )
                .toList();
            if (drive.isNotEmpty) {
              _items.remove(drive.first);
              _upcomingTripsCount--;
            }
            final List<RideEvent> events = _items
                .where((Model element) => element is RideEvent && element.ride!.driveId == driveData['id'])
                .map((Model e) => e as RideEvent)
                .toList();
            _items.removeWhere((Model element) => events.contains(element));
            for (final RideEvent event in events) {
              event.markAsRead();
            }
          });
        }
      },
    );

    _messagesSubscriptions.subscribe();
    _rideEventsSubscriptions.subscribe();
    _ridesSubscriptions.subscribe();
    _drivesSubscriptions.subscribe();

    super.initState();
  }

  @override
  void dispose() {
    SupabaseManager.supabaseClient.removeChannel(_messagesSubscriptions);
    SupabaseManager.supabaseClient.removeChannel(_rideEventsSubscriptions);
    SupabaseManager.supabaseClient.removeChannel(_ridesSubscriptions);
    SupabaseManager.supabaseClient.removeChannel(_drivesSubscriptions);
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
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 2));
    final List<Trip> trips = <Trip>[];
    trips.addAll(
      Ride.fromJsonList(
        parseHelper.parseListOfMaps(
          await SupabaseManager.supabaseClient
              .from('rides')
              .select()
              .eq('rider_id', profileId)
              .eq('status', RideStatus.approved.index)
              .lt('start_time', tomorrow)
              .gte('start_time', today),
        ),
      ),
    );
    trips.addAll(
      Drive.fromJsonList(
        parseHelper.parseListOfMaps(
          await SupabaseManager.supabaseClient
              .from('drives')
              .select()
              .eq('driver_id', profileId)
              .eq('cancelled', false)
              .lt('start_time', tomorrow)
              .gte('start_time', today),
        ),
      ),
    );
    trips.sort((Trip a, Trip b) => a.startTime.compareTo(b.startTime));
    _upcomingTripsCount = trips.length;
    items.insertAll(0, trips);

    setState(() {
      _items = items;
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${S.of(context).hello} ${SupabaseManager.getCurrentProfile()!.username} :)'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 30),
            Button(
              S.of(context).pageHomeSearchButton,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (BuildContext context) => const SearchRidePage()),
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
            const SizedBox(height: 15),
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
                            return const SizedBox(height: 2);
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
        _items.insert(_upcomingTripsCount, rideEvent);
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
    if (!message.read) {
      setState(() {
        _items.insert(_upcomingTripsCount, message);
      });
    }
  }

  Card _buildMessageWidget(Message message, BuildContext context) {
    return Card(
      child: InkWell(
        child: Dismissible(
          key: Key('message${message.id.toString()}'),
          onDismissed: (DismissDirection direction) async {
            unawaited(message.markAsRead());
            setState(() {
              _items.remove(message);
            });
          },
          child: ListTile(
            leading: Avatar(message.sender!),
            title: Text(message.sender!.username),
            subtitle: Text(message.content, maxLines: 1),
            trailing: Text(
              localeManager.formatTime(message.createdAt!),
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
      ),
    );
  }

  Widget _buildRideEventWidget(RideEvent rideEvent, BuildContext context) {
    final bool isForRide = rideEvent.ride!.rider!.isCurrentUser;
    return Card(
      child: InkWell(
        child: Dismissible(
          key: Key('rideEvent${rideEvent.id.toString()}'),
          onDismissed: (DismissDirection direction) async {
            unawaited(rideEvent.markAsRead());
            setState(() {
              _items.remove(rideEvent);
            });
          },
          child: ListTile(
            leading: isForRide ? const Icon(Icons.chair) : const Icon(Icons.drive_eta),
            title: Text(rideEvent.getTitle(context)),
            subtitle: Text(rideEvent.getMessage(context)),
            trailing: Text(
              localeManager.formatTime(rideEvent.createdAt!),
              style: Theme.of(context).textTheme.caption,
            ),
            onTap: () {
              rideEvent.markAsRead();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      isForRide ? RideDetailPage(id: rideEvent.rideId) : DriveDetailPage(id: rideEvent.ride!.driveId),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTripWidget(Trip trip, BuildContext context) {
    return Card(
      child: InkWell(
        child: Dismissible(
          key: Key('trip${trip.id.toString()}'),
          onDismissed: (DismissDirection direction) async {
            setState(() {
              _items.remove(trip);
            });
          },
          child: ListTile(
            leading: Icon(trip is Drive ? Icons.drive_eta : Icons.chair),
            title: Text(
              trip is Drive
                  ? trip.startTime.day == DateTime.now().day
                      ? S.of(context).pageHomeUpcomingDriveToday
                      : S.of(context).pageHomeUpcomingDriveTomorrow
                  : trip.startTime.day == DateTime.now().day
                      ? S.of(context).pageHomeUpcomingRideToday
                      : S.of(context).pageHomeUpcomingRideTomorrow,
            ),
            subtitle: Text(
              S.of(context).pageHomeUpcomingTripMessage(trip.start, trip.end, localeManager.formatTime(trip.startTime)),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      trip is Drive ? DriveDetailPage(id: trip.id!) : RideDetailPage(id: trip.id),
                ),
              );
            },
          ),
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
      return _buildTripWidget(model as Trip, context);
    }
  }
}
