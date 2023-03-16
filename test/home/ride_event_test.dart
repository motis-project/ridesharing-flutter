import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/home/models/ride_event.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';

import '../test_util/factories/drive_factory.dart';
import '../test_util/factories/model_factory.dart';
import '../test_util/factories/profile_factory.dart';
import '../test_util/factories/ride_event_factory.dart';
import '../test_util/factories/ride_factory.dart';
import '../test_util/mocks/mock_server.dart';
import '../test_util/mocks/request_processor.dart';
import '../test_util/mocks/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor rideEventProcessor = MockRequestProcessor();

  setUp(() async {
    MockServer.setProcessor(rideEventProcessor);
  });

  test('mark as read', () async {
    final RideEvent rideEvent = RideEventFactory().generateFake(
      read: false,
    );
    whenRequest(rideEventProcessor).thenReturnJson('');

    await rideEvent.markAsRead();

    verifyRequest(
      rideEventProcessor,
      urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read'),
      bodyMatcher: equals({
        'ride_event_id': rideEvent.id,
      }),
    );

    expect(rideEvent.read, true);
  });

  group('RideEvent.isForCurrentUser', () {
    final Profile user = ProfileFactory().generateFake(id: 1);
    final Drive driveWithUserAsDriver = DriveFactory().generateFake(
      driverId: user.id,
    );
    final Drive driveWithUserNotDriver = DriveFactory().generateFake(
      id: 1,
      driverId: user.id! + 1,
    );

    setUp(() {
      supabaseManager.currentProfile = user;
    });

    test('returns true if rideEvent is for current user', () async {
      final RideEvent rideEventApproved = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          riderId: user.id,
        )),
        category: RideEventCategory.approved,
      );

      final RideEvent rideEventRejected = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          riderId: user.id,
        )),
        category: RideEventCategory.rejected,
      );

      final RideEvent rideEventCancelledByDriver = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          riderId: user.id,
        )),
        category: RideEventCategory.cancelledByDriver,
      );

      final RideEvent rideEventCancelledByRider = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          drive: NullableParameter(driveWithUserAsDriver),
        )),
        category: RideEventCategory.cancelledByRider,
      );

      final RideEvent rideEventPending = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          drive: NullableParameter(driveWithUserAsDriver),
        )),
        category: RideEventCategory.pending,
      );

      final RideEvent rideEventWithdrawn = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          drive: NullableParameter(driveWithUserAsDriver),
        )),
        category: RideEventCategory.withdrawn,
      );

      expect(rideEventApproved.isForCurrentUser(), true);
      expect(rideEventRejected.isForCurrentUser(), true);
      expect(rideEventCancelledByDriver.isForCurrentUser(), true);
      expect(rideEventCancelledByRider.isForCurrentUser(), true);
      expect(rideEventPending.isForCurrentUser(), true);
      expect(rideEventWithdrawn.isForCurrentUser(), true);
    });

    test('returns false if rideEvent is not current user', () async {
      final RideEvent rideEventApproved = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          drive: NullableParameter(driveWithUserAsDriver),
        )),
        category: RideEventCategory.approved,
      );

      final RideEvent rideEventRejected = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          drive: NullableParameter(driveWithUserAsDriver),
        )),
        category: RideEventCategory.rejected,
      );

      final RideEvent rideEventCancelledByDriver = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          drive: NullableParameter(driveWithUserAsDriver),
        )),
        category: RideEventCategory.cancelledByDriver,
      );

      final RideEvent rideEventCancelledByRider = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          riderId: user.id,
          drive: NullableParameter(driveWithUserNotDriver),
        )),
        category: RideEventCategory.cancelledByRider,
      );

      final RideEvent rideEventPending = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          riderId: user.id,
          drive: NullableParameter(driveWithUserNotDriver),
        )),
        category: RideEventCategory.pending,
      );

      final RideEvent rideEventWithdrawn = RideEventFactory().generateFake(
        ride: NullableParameter(RideFactory().generateFake(
          riderId: user.id,
          drive: NullableParameter(driveWithUserNotDriver),
        )),
        category: RideEventCategory.withdrawn,
      );
      expect(rideEventApproved.isForCurrentUser(), false);
      expect(rideEventRejected.isForCurrentUser(), false);
      expect(rideEventCancelledByDriver.isForCurrentUser(), false);
      expect(rideEventCancelledByRider.isForCurrentUser(), false);
      expect(rideEventPending.isForCurrentUser(), false);
      expect(rideEventWithdrawn.isForCurrentUser(), false);
    });
  });

  group('RideEvent.fromJson', () {
    test('parses a message from json', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'category': RideEventCategory.approved.index,
        'ride_id': 2,
        'read': false,
      };
      final rideEvent = RideEvent.fromJson(json);
      expect(rideEvent.id, 1);
      expect(rideEvent.createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(rideEvent.rideId, 2);
      expect(rideEvent.category, RideEventCategory.approved);
      expect(rideEvent.read, false);
    });

    test('can handle ride', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'category': RideEventCategory.approved.index,
        'ride_id': 2,
        'read': false,
        'ride': RideFactory().generateFake(id: 2).toJsonForApi(),
      };
      expect(json['ride'], isNotNull);
    });
  });

  group('Message.fromJsonList', () {
    test('parses a list of messages from json', () async {
      final List<Map<String, dynamic>> json = [
        {
          'id': 1,
          'created_at': '2021-01-01T00:00:00.000Z',
          'ride_id': 2,
          'category': RideEventCategory.approved.index,
          'read': true,
        },
        {
          'id': 2,
          'created_at': '2021-01-01T00:00:00.000Z',
          'ride_id': 3,
          'category': RideEventCategory.pending.index,
          'read': true,
        },
      ];
      final rideEvent = RideEvent.fromJsonList(json);
      expect(rideEvent.length, 2);
      expect(rideEvent[0].id, 1);
      expect(rideEvent[0].createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(rideEvent[0].rideId, 2);
      expect(rideEvent[0].category, RideEventCategory.approved);
      expect(rideEvent[0].read, true);
      expect(rideEvent[1].id, 2);
      expect(rideEvent[1].createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(rideEvent[1].rideId, 3);
      expect(rideEvent[1].category, RideEventCategory.pending);
      expect(rideEvent[1].read, true);
    });

    test('parses an empty list of messages from json', () async {
      final List<Map<String, dynamic>> json = [];
      final List<RideEvent> rideEvent = RideEvent.fromJsonList(json);
      expect(rideEvent.length, 0);
    });
  });

  group('RideEvent.toJson', () {
    test('converts rideEvent to json', () {
      final RideEvent rideEvent = RideEventFactory().generateFake();
      final json = rideEvent.toJson();
      expect(json['ride_id'], rideEvent.rideId);
      expect(json['category'], rideEvent.category.index);
      expect(json['read'], rideEvent.read);
      expect(json.keys.length, 3);
    });
  });

  group('Message.toString', () {
    test('convert rideEvent to String', () {
      final RideEvent rideEvent = RideEventFactory().generateFake();
      final string = rideEvent.toString();
      expect(string,
          'RideEvent{id: ${rideEvent.id}, createdAt: ${rideEvent.createdAt}, read: ${rideEvent.read}, category: ${rideEvent.category}, ride_id: ${rideEvent.rideId}}');
    });
  });
}
