import '../../account/models/profile.dart';
import '../../managers/supabase_manager.dart';
import '../../search/position.dart';
import '../../trips/models/trip.dart';
import '../../util/parse_helper.dart';
import 'recurring_drive.dart';
import 'ride.dart';

class Drive extends Trip {
  DriveStatus status;

  final int driverId;
  final Profile? driver;

  final int? recurringDriveId;
  final RecurringDrive? recurringDrive;

  final List<Ride>? rides;

  Drive({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required super.startDateTime,
    required super.end,
    required super.endPosition,
    required super.endDateTime,
    required super.seats,
    this.status = DriveStatus.plannedOrFinished,
    super.hideInListView,
    required this.driverId,
    this.driver,
    this.recurringDriveId,
    this.recurringDrive,
    this.rides,
  });

  @override
  factory Drive.fromJson(Map<String, dynamic> json) {
    return Drive(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      start: json['start'] as String,
      startPosition: Position.fromDynamicValues(json['start_lat'], json['start_lng']),
      startDateTime: DateTime.parse(json['start_time'] as String),
      end: json['end'] as String,
      endPosition: Position.fromDynamicValues(json['end_lat'], json['end_lng']),
      endDateTime: DateTime.parse(json['end_time'] as String),
      seats: json['seats'] as int,
      status: DriveStatus.values[json['status'] as int],
      hideInListView: json['hide_in_list_view'] as bool,
      driverId: json['driver_id'] as int,
      driver: json.containsKey('driver') ? Profile.fromJson(json['driver'] as Map<String, dynamic>) : null,
      recurringDriveId: json['recurring_drive_id'] as int?,
      recurringDrive: json.containsKey('recurring_drive')
          ? RecurringDrive.fromJson(json['recurring_drive'] as Map<String, dynamic>)
          : null,
      rides: json.containsKey('rides') ? Ride.fromJsonList(parseHelper.parseListOfMaps(json['rides'])) : null,
    );
  }

  static List<Drive> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Drive.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'status': status.index,
        'driver_id': driverId,
        'recurring_drive_id': recurringDriveId,
      });
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        ...driver == null ? <String, dynamic>{} : <String, dynamic>{'driver': driver?.toJsonForApi()},
        ...recurringDrive == null
            ? <String, dynamic>{}
            : <String, dynamic>{'recurring_drive': recurringDrive?.toJsonForApi()},
        'rides': rides?.map((Ride ride) => ride.toJsonForApi()).toList() ?? <Map<String, dynamic>>[],
      });
  }

  /// Returns all rides belonging to this drive that are approved
  ///
  /// Expects [rides] to be not null
  List<Ride> get approvedRides => rides!.where((Ride ride) => ride.status == RideStatus.approved).toList();

  /// Returns all rides belonging to this drive that are pending
  ///
  /// Expects [rides] to be not null
  List<Ride> get pendingRides => rides!.where((Ride ride) => ride.status == RideStatus.pending).toList();

  /// Returns all rides belonging to this drive that have an active chat, i.e. have been approved in the past
  ///
  /// Expects [rides] to be not null
  List<Ride> get ridesWithChat => rides!.where((Ride ride) => ride.status.activeChat()).toList();

  /// Returns whether this drive belongs to a recurring drive and should be shown in the list view.
  bool get isUpcomingRecurringDriveInstance =>
      recurringDriveId != null &&
      startDateTime.isAfter(DateTime.now()) &&
      !hideInListView &&
      !(status == DriveStatus.cancelledByRecurrenceRule && (rides?.isEmpty ?? false));

  /// Returns the maximum number of seats occupied during the course of this drive
  ///
  /// Returns null if [rides] is null
  int? getMaxUsedSeats() {
    if (rides == null) return null;

    final Set<DateTime> times = approvedRides
        .map((Ride ride) => <DateTime>[ride.startDateTime, ride.endDateTime])
        .expand((List<DateTime> x) => x)
        .toSet();

    int maxUsedSeats = 0;
    for (final DateTime time in times) {
      int usedSeats = 0;
      for (final Ride ride in approvedRides) {
        final bool startTimeBeforeOrEqual =
            ride.startDateTime.isBefore(time) || ride.startDateTime.isAtSameMomentAs(time);
        final bool endTimeAfter = ride.endDateTime.isAfter(time);
        if (startTimeBeforeOrEqual && endTimeAfter) {
          usedSeats += ride.seats;
        }
      }

      if (usedSeats > maxUsedSeats) {
        maxUsedSeats = usedSeats;
      }
    }
    return maxUsedSeats;
  }

  /// Returns whether the given [ride] can be added to this drive, i.e. whether there are enough seats available at the time
  ///
  /// Expects [rides] to be not null
  bool isRidePossible(Ride ride) {
    final List<Ride> consideredRides = approvedRides..add(ride);
    final Set<DateTime> times = consideredRides
        .map((Ride consideredRide) => <DateTime>[consideredRide.startDateTime, consideredRide.endDateTime])
        .expand((List<DateTime> x) => x)
        .toSet();
    for (final DateTime time in times) {
      int usedSeats = 0;
      for (final Ride consideredRide in consideredRides) {
        final bool startTimeBeforeOrEqual =
            consideredRide.startDateTime.isBefore(time) || consideredRide.startDateTime.isAtSameMomentAs(time);
        final bool endTimeAfter = consideredRide.endDateTime.isAfter(time);
        if (startTimeBeforeOrEqual && endTimeAfter) {
          usedSeats += consideredRide.seats;
        }
      }

      if (usedSeats > seats) {
        return false;
      }
    }
    return true;
  }

  /// Cancels the drive, sending a request to supabase. The rides get updated automatically by a supabase function.
  Future<void> cancel() async {
    status = DriveStatus.cancelledByDriver;
    await supabaseManager.supabaseClient.from('drives').update(<String, dynamic>{'status': status.index}).eq('id', id);
  }

  /// Returns the number of rides with unread messages
  ///
  /// Expects [rides] to be not null
  /// Expects [messages] of all rides to be not null
  int getUnreadMessagesCount() {
    return ridesWithChat.where((Ride ride) => ride.chat!.getUnreadMessagesCount() > 0).length;
  }

  @override
  String toString() {
    return 'Drive{id: $id, from: $start at $startDateTime, to: $end at $endDateTime, by: $driverId}';
  }

  @override
  bool equals(Trip other) {
    if (other is! Drive) return false;
    final Drive drive = other;
    return super.equals(other) && status == drive.status && driverId == drive.driverId;
  }
}

enum DriveStatus { preview, plannedOrFinished, cancelledByDriver, cancelledByRecurrenceRule }

extension DriveStatusExtension on DriveStatus {
  /// Returns whether the drive is cancelled, either by the driver or by the recurrence rule
  bool isCancelled() {
    return this == DriveStatus.cancelledByDriver || this == DriveStatus.cancelledByRecurrenceRule;
  }
}
