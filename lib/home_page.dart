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
import 'util/supabase_manager.dart';
import 'util/trip/trip.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  //needs to be initialized in case the subscription gets something new before load is done
  List<Message> _messages = <Message>[];
  List<RideEvent> _rideEvents = <RideEvent>[];
  final List<Trip> _trips = <Trip>[];

  bool _fullyLoaded = false;
  late RealtimeChannel _messagesSubscriptions;
  late RealtimeChannel _rideEventsSubscriptions;
  late RealtimeChannel _ridesSubscriptions;
  late RealtimeChannel _drivesSubscriptions;

  @override
  void initState() {
    load();
    final int profileId = supabaseManager.currentProfile!.id!;

    _messagesSubscriptions = supabaseManager.supabaseClient.channel('public:messages').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages', filter: 'sender_id=neq.$profileId'),
      (dynamic payload, [dynamic ref]) {
        insertMessage(pick(payload, 'new').asMapOrEmpty());
      },
    ).on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'messages', filter: 'sender_id=neq.$profileId'),
      (dynamic payload, [dynamic ref]) {
        updateMessage(pick(payload, 'new').asMapOrEmpty());
      },
    );

    _rideEventsSubscriptions = supabaseManager.supabaseClient.channel('public:ride_events').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'ride_events'),
      (dynamic payload, [dynamic ref]) {
        insertRideEvent(pick(payload, 'new').asMapOrEmpty());
      },
    ).on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'ride_events'),
      (dynamic payload, [dynamic ref]) {
        updateRideEvent(pick(payload, 'new').asMapOrEmpty());
      },
    );

    _ridesSubscriptions = supabaseManager.supabaseClient.channel('public:rides').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'UPDATE', schema: 'public', table: 'rides', filter: 'rider_id=eq.$profileId'),
      (dynamic payload, [dynamic ref]) {
        updateRide(pick(payload, 'new').asMapOrEmpty());
      },
    );

    _drivesSubscriptions = supabaseManager.supabaseClient.channel('public:drives').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'drives',
        filter: 'driver_id=eq.$profileId',
      ),
      (dynamic payload, [dynamic ref]) {
        insertDrive(pick(payload, 'new').asMapOrEmpty());
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
        updateDrive(pick(payload, 'new').asMapOrEmpty());
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
    supabaseManager.supabaseClient.removeChannel(_messagesSubscriptions);
    supabaseManager.supabaseClient.removeChannel(_rideEventsSubscriptions);
    supabaseManager.supabaseClient.removeChannel(_ridesSubscriptions);
    supabaseManager.supabaseClient.removeChannel(_drivesSubscriptions);
    super.dispose();
  }

  Future<void> load() async {
    final int profileId = supabaseManager.currentProfile!.id!;
    final List<Map<String, dynamic>> messagesData = parseHelper.parseListOfMaps(
      await supabaseManager.supabaseClient.from('messages').select<List<Map<String, dynamic>>>('''
      *,
      sender: sender_id(*)
      )
    ''').eq('read', false).neq('sender_id', profileId).order('created_at'),
    );
    _messages = Message.fromJsonList(messagesData);
    final List<Map<String, dynamic>> rideEventsData = parseHelper.parseListOfMaps(
      await supabaseManager.supabaseClient.from('ride_events').select<List<Map<String, dynamic>>>('''
      *,
      ride: ride_id(*,
        rider: rider_id(*),
        drive: drive_id(*,
          driver: driver_id(*)
          )
      )
      ''').eq('read', false).order('created_at'),
    );
    _rideEvents =
        RideEvent.fromJsonList(rideEventsData).where((RideEvent rideEvent) => rideEvent.isForCurrentUser()).toList();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 2));
    _trips.addAll(
      Ride.fromJsonList(
        parseHelper.parseListOfMaps(
          await supabaseManager.supabaseClient
              .from('rides')
              .select<List<Map<String, dynamic>>>()
              .eq('rider_id', profileId)
              .eq('status', RideStatus.approved.index)
              .lt('start_time', tomorrow)
              .gte('start_time', today),
        ),
      ),
    );
    _trips.addAll(
      Drive.fromJsonList(
        parseHelper.parseListOfMaps(
          await supabaseManager.supabaseClient
              .from('drives')
              .select<List<Map<String, dynamic>>>()
              .eq('driver_id', profileId)
              .eq('cancelled', false)
              .lt('start_time', tomorrow)
              .gte('start_time', today),
        ),
      ),
    );
    _trips.sort((Trip a, Trip b) => a.startTime.compareTo(b.startTime));

    setState(() {
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget searchButton = Hero(
      tag: 'SearchButton',
      transitionOnUserGestures: true,
      child: Button(
        S.of(context).pageHomeSearchButton,
        key: const Key('SearchButton'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (BuildContext context) => const SearchRidePage()),
        ),
      ),
    );
    final Widget createButton = Hero(
      tag: 'CreateButton',
      transitionOnUserGestures: true,
      child: Button(
        S.of(context).pageHomeCreateButton,
        key: const Key('CreateButton'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (BuildContext context) => const CreateDrivePage()),
        ),
      ),
    );
    late final Widget messagesColumn;
    late final Widget rideEventsColumn;
    late final Widget tripsColumn;
    if (_fullyLoaded) {
      messagesColumn = Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(S.of(context).pageHomePageMessages, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 10),
          if (_messages.isNotEmpty)
            ..._messages.map(_buildMessageWidget)
          else
            ...buildEmptyRideSuggestions('assets/shrug.png', S.of(context).pageHomePageEmptyMessages)
        ],
      );
      rideEventsColumn = Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(S.of(context).pageHomePageRideEvents, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 10),
          if (_rideEvents.isNotEmpty)
            ..._rideEvents.map(_buildRideEventWidget)
          else
            ...buildEmptyRideSuggestions('assets/shrug.png', S.of(context).pageHomePageEmptyRideEvents)
        ],
      );
      tripsColumn = Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(S.of(context).pageHomePageTrips, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 10),
          if (_trips.isNotEmpty)
            ..._trips.map(_buildTripWidget)
          else
            ...buildEmptyRideSuggestions('assets/shrug.png', S.of(context).pageHomePageEmptyTrips)
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageHomePageHello(supabaseManager.currentProfile!.username)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 10),
              searchButton,
              const SizedBox(height: 15),
              createButton,
              const SizedBox(height: 30),
              if (_fullyLoaded) ...[
                messagesColumn,
                const SizedBox(height: 30),
                rideEventsColumn,
                const SizedBox(height: 30),
                tripsColumn,
              ] else
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> insertRideEvent(Map<String, dynamic> rideEventData) async {
    final Map<String, dynamic> data =
        await supabaseManager.supabaseClient.from('ride_events').select<Map<String, dynamic>>('''
      *,
      ride: ride_id(*,
        rider: rider_id(*),
        drive: drive_id(*,
          driver: driver_id(*)
          )
      )
      ''').eq('id', rideEventData['id']).single();
    final RideEvent rideEvent = RideEvent.fromJson(data);
    if (rideEvent.isForCurrentUser()) {
      setState(() {
        _rideEvents.insert(0, rideEvent);
      });
    }
  }

  void updateRideEvent(Map<String, dynamic> rideEventData) {
    if (rideEventData['read'] as bool) {
      setState(() {
        _rideEvents.removeWhere(
          (RideEvent element) => element.id == rideEventData['id'],
        );
      });
    }
  }

  Future<void> insertMessage(Map<String, dynamic> messageData) async {
    if (messageData['sender_id'] != supabaseManager.currentProfile!.id) {
      final Map<String, dynamic> data =
          await supabaseManager.supabaseClient.from('messages').select<Map<String, dynamic>>('''
      *,
      sender: sender_id(*)
      )
    ''').eq('id', messageData['id']).single();
      final Message message = Message.fromJson(data);
      setState(() {
        _messages.insert(0, message);
      });
    }
  }

  void updateMessage(Map<String, dynamic> messageData) {
    if (messageData['read'] == true) {
      setState(() {
        _messages.removeWhere(
          (Message element) => element.id == messageData['id'],
        );
      });
    }
  }

  void updateRide(Map<String, dynamic> rideData) {
    final DateTime now = DateTime.now();
    final DateTime startTime = DateTime.parse(rideData['start_time'] as String);
    if (startTime.isAfter(now) && startTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
      if (rideData['status'] == RideStatus.approved.index) {
        setState(() {
          for (int i = 0; i <= _trips.length; i++) {
            if (_trips[i].startTime.isAfter(startTime)) {
              _trips.insert(i, Ride.fromJson(rideData));
              break;
            }
          }
        });
      } else {
        setState(() {
          final List<Model> ride = _trips
              .where(
                (Trip element) => element is Ride && element.id == rideData['id'],
              )
              .toList();
          if (ride.isNotEmpty) {
            _trips.remove(ride.first);
          }
        });
      }
    }
  }

  void insertDrive(Map<String, dynamic> driveData) {
    final DateTime now = DateTime.now();
    final DateTime startTime = DateTime.parse(driveData['start_time'] as String);
    if (startTime.isAfter(now) && startTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
      setState(() {
        for (int i = 0; i <= _trips.length; i++) {
          if (_trips[i].startTime.isAfter(startTime)) {
            _trips.insert(i, Drive.fromJson(driveData));
            break;
          }
        }
      });
    }
  }

  void updateDrive(Map<String, dynamic> driveData) {
    final DateTime now = DateTime.now();
    final DateTime startTime = DateTime.parse(driveData['start_time'] as String);
    if (driveData['cancelled'] == true &&
        startTime.isAfter(now) &&
        startTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
      setState(() {
        final List<Trip> drive = _trips
            .where(
              (Trip element) => element is Drive && element.id == driveData['id'],
            )
            .toList();
        if (drive.isNotEmpty) {
          _trips.remove(drive.first);
        }
      });
    }
  }

  Widget _buildMessageWidget(Message message) {
    return Dismissible(
      key: Key('message${message.id}'),
      onDismissed: (DismissDirection direction) async {
        unawaited(message.markAsRead());
        setState(() {
          _messages.remove(message);
        });
      },
      child: Card(
        child: InkWell(
          child: ListTile(
            leading: Avatar(message.sender!),
            title: Text(message.sender!.username),
            subtitle: Text(message.content, maxLines: 1),
            trailing: Text(
              localeManager.formatTime(message.createdAt!),
              style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildRideEventWidget(RideEvent rideEvent) {
    final bool isForRide = rideEvent.ride!.rider!.isCurrentUser;
    return Dismissible(
      key: Key('rideEvent${rideEvent.id}'),
      onDismissed: (DismissDirection direction) async {
        unawaited(rideEvent.markAsRead());
        setState(() {
          _rideEvents.remove(rideEvent);
        });
      },
      child: Card(
        child: InkWell(
          child: ListTile(
            leading: isForRide ? const Icon(Icons.chair) : const Icon(Icons.drive_eta),
            title: Text(rideEvent.getTitle(context)),
            subtitle: Text(rideEvent.getMessage(context)),
            trailing: Text(
              localeManager.formatTime(rideEvent.createdAt!),
              style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildTripWidget(Trip trip) {
    return Dismissible(
      key: trip is Ride ? Key('ride${trip.id}') : Key('drive${trip.id}'),
      onDismissed: (DismissDirection direction) async {
        setState(() {
          _trips.remove(trip);
        });
      },
      child: Card(
        child: InkWell(
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
              S.of(context).pageHomeUpcomingTripMessage(trip.end, trip.start, localeManager.formatTime(trip.startTime)),
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

  List<Widget> buildEmptyRideSuggestions(String asset, String title) {
    return <Widget>[
      const SizedBox(height: 10),
      Image.asset(asset, scale: 8),
      const SizedBox(height: 10),
      Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
        textAlign: TextAlign.center,
      ),
    ];
  }
}
