import 'dart:async';

import 'package:deep_pick/deep_pick.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../util/buttons/button.dart';
import '../../account/pages/profile_page.dart';
import '../../account/widgets/avatar.dart';
import '../../chat/models/message.dart';
import '../../chat/pages/chat_page.dart';
import '../../main_app.dart';
import '../../managers/locale_manager.dart';
import '../../managers/supabase_manager.dart';
import '../../model.dart';
import '../../trips/models/drive.dart';
import '../../trips/models/ride.dart';
import '../../trips/models/trip.dart';
import '../../trips/pages/create_drive_page.dart';
import '../../trips/pages/drive_detail_page.dart';
import '../../trips/pages/ride_detail_page.dart';
import '../../trips/pages/search_ride_page.dart';
import '../../util/empty_search_results.dart';
import '../../util/parse_helper.dart';
import '../models/ride_event.dart';
import '../widgets/dismissible_list_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  //needs to be initialized in case the subscription gets something new before load is done
  final List<Trip> _trips = <Trip>[];
  List<RideEvent> _rideEvents = <RideEvent>[];
  List<Message> _messages = <Message>[];

  bool _fullyLoaded = false;
  late RealtimeChannel _messagesSubscriptions;
  late RealtimeChannel _rideEventsSubscriptions;
  late RealtimeChannel _ridesSubscriptions;
  late RealtimeChannel _drivesSubscriptions;

  @override
  void initState() {
    load();
    final int profileId = supabaseManager.currentProfile!.id!;

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
    _ridesSubscriptions.subscribe();
    _drivesSubscriptions.subscribe();
    _rideEventsSubscriptions.subscribe();
    _messagesSubscriptions.subscribe();

    super.initState();
  }

  @override
  void dispose() {
    supabaseManager.supabaseClient.removeChannel(_ridesSubscriptions);
    supabaseManager.supabaseClient.removeChannel(_drivesSubscriptions);
    supabaseManager.supabaseClient.removeChannel(_rideEventsSubscriptions);
    supabaseManager.supabaseClient.removeChannel(_messagesSubscriptions);
    super.dispose();
  }

  Future<void> load() async {
    final int profileId = supabaseManager.currentProfile!.id!;

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
              .lt('start_date_time', tomorrow)
              .gte('start_date_time', today),
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
              .eq('status', DriveStatus.plannedOrFinished.index)
              .lt('start_date_time', tomorrow)
              .gte('start_date_time', today),
        ),
      ),
    );
    _trips.sort((Trip a, Trip b) => a.startDateTime.compareTo(b.startDateTime));

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

    final List<Map<String, dynamic>> messagesData = parseHelper.parseListOfMaps(
      await supabaseManager.supabaseClient.from('messages').select<List<Map<String, dynamic>>>('''
      *,
      sender: sender_id(*)
      )
    ''').eq('read', false).neq('sender_id', profileId).order('created_at'),
    );
    _messages = Message.fromJsonList(messagesData);

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
        onPressed: () => mainAppKey.currentState!.selectTabAndPush(TabItem.rides, const SearchRidePage()),
      ),
    );
    final Widget createButton = Hero(
      tag: 'CreateButton',
      transitionOnUserGestures: true,
      child: Button(
        S.of(context).pageHomeCreateButton,
        key: const Key('CreateButton'),
        onPressed: () => mainAppKey.currentState!.selectTabAndPush(TabItem.drives, const CreateDrivePage()),
      ),
    );
    List<Widget> notifications = <Widget>[];
    if (_fullyLoaded) {
      if (_trips.isNotEmpty) {
        notifications.add(
          Column(
            key: const Key('tripsColumn'),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(S.of(context).pageHomePageTrips, style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 10),
              ..._trips.map(_buildTripWidget)
            ],
          ),
        );
        notifications.add(const SizedBox(height: 10));
      }
      if (_rideEvents.isNotEmpty) {
        notifications.add(
          Column(
            key: const Key('rideEventsColumn'),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(S.of(context).pageHomePageRideEvents, style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 10),
              ..._rideEvents.map(_buildRideEventWidget)
            ],
          ),
        );
        notifications.add(const SizedBox(height: 10));
      }
      if (_messages.isNotEmpty) {
        notifications.add(
          Column(
            key: const Key('messagesColumn'),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(S.of(context).pageHomePageMessages, style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 10),
              ..._messages.map(_buildMessageWidget)
            ],
          ),
        );
        notifications.add(const SizedBox(height: 10));
      }
      if (notifications.isEmpty) {
        if (supabaseManager.currentProfile!.hasNoPersonalInformation) {
          notifications = <Widget>[
            EmptySearchResults(
              key: const Key('completeProfileColumn'),
              asset: 'assets/ninja.png',
              title: S.of(context).pageHomePageCompleteProfile,
              subtitle: Button(
                key: const Key('completeProfileButton'),
                S.of(context).pageHomePageCompleteProfileButton,
                onPressed: () => mainAppKey.currentState!
                    .selectTabAndPush(TabItem.account, ProfilePage.fromProfile(supabaseManager.currentProfile))
                    .then((_) => setState(() {})),
              ),
            ),
          ];
        } else {
          notifications = <Widget>[
            EmptySearchResults(
              key: const Key('emptyColumn'),
              asset: EmptySearchResults.pointingUpAsset,
              title: S.of(context).pageHomePageEmpty,
              subtitle: Text(
                S.of(context).pageHomePageEmptySubtitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ];
        }
      }
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
              if (_fullyLoaded)
                ...notifications
              else
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void updateRide(Map<String, dynamic> rideData) {
    final DateTime now = DateTime.now();
    final DateTime startDateTime = DateTime.parse(rideData['start_date_time'] as String);
    if (startDateTime.isAfter(now) && startDateTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
      if (rideData['status'] == RideStatus.approved.index) {
        setState(() {
          bool inserted = false;
          for (int i = 0; i < _trips.length; i++) {
            if (_trips[i].startDateTime.isAfter(startDateTime)) {
              _trips.insert(i, Ride.fromJson(rideData));
              inserted = true;
              break;
            }
          }
          if (!inserted) _trips.add(Ride.fromJson(rideData));
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
    final DateTime startDateTime = DateTime.parse(driveData['start_date_time'] as String);
    if (startDateTime.isAfter(now) && startDateTime.isBefore(DateTime(now.year, now.month, now.day + 2))) {
      setState(() {
        bool inserted = false;
        for (int i = 0; i < _trips.length; i++) {
          if (_trips[i].startDateTime.isAfter(startDateTime)) {
            _trips.insert(i, Drive.fromJson(driveData));
            inserted = true;
            break;
          }
        }
        if (!inserted) _trips.add(Drive.fromJson(driveData));
      });
    }
  }

  void updateDrive(Map<String, dynamic> driveData) {
    final DateTime now = DateTime.now();
    final DateTime startTime = DateTime.parse(driveData['start_date_time'] as String);
    if (driveData['status'] != DriveStatus.plannedOrFinished.index &&
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

  Widget _buildTripWidget(Trip trip) {
    return DismissibleListTile(
      dismissibleKey: trip is Ride ? Key('ride${trip.id}') : Key('drive${trip.id}'),
      onDismissed: (DismissDirection direction) async {
        setState(() {
          _trips.remove(trip);
        });
      },
      semanticsLabel: S.of(context).openDetails,
      title: Text(
        trip is Drive
            ? trip.startDateTime.day == DateTime.now().day
                ? S.of(context).pageHomeUpcomingDriveToday
                : S.of(context).pageHomeUpcomingDriveTomorrow
            : trip.startDateTime.day == DateTime.now().day
                ? S.of(context).pageHomeUpcomingRideToday
                : S.of(context).pageHomeUpcomingRideTomorrow,
      ),
      subtitle: Text(
        S.of(context).pageHomeUpcomingTripMessage(
              trip.destination,
              trip.start,
              localeManager.formatTime(trip.startDateTime),
            ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                trip is Drive ? DriveDetailPage(id: trip.id) : RideDetailPage(id: trip.id),
          ),
        );
      },
    );
  }

  Widget _buildRideEventWidget(RideEvent rideEvent) {
    final bool isForRide = rideEvent.ride!.rider!.isCurrentUser;
    return DismissibleListTile(
      dismissibleKey: Key('rideEvent${rideEvent.id}'),
      semanticsLabel: S.of(context).openDetails,
      onDismissed: (DismissDirection direction) async {
        unawaited(rideEvent.markAsRead());
        setState(() {
          _rideEvents.remove(rideEvent);
        });
      },
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
    );
  }

  Widget _buildMessageWidget(Message message) {
    return DismissibleListTile(
      dismissibleKey: Key('message${message.id}'),
      onDismissed: (DismissDirection direction) async {
        unawaited(message.markAsRead());
        setState(() {
          _messages.remove(message);
        });
      },
      semanticsLabel: S.of(context).openDetails,
      leading: Avatar(message.sender!),
      title: Text(message.sender!.username),
      subtitle: Text(message.content, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    );
  }
}
