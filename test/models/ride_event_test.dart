import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/ride_event.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../util/factories/ride_event_factory.dart';
import '../util/mock_server.dart';

void main() {
  final UrlProcessor rideEventProcessor = UrlProcessor();

  setUp(() async {
    MockServer.setProcessor(rideEventProcessor);
  });

  group('markAsRead', () {
    test('marks rideEventas read', () async {
      final RideEvent rideEvent = RideEventFactory().generateFake(
        read: false,
      );
      await rideEvent.markAsRead();
      SupabaseManager.supabaseClient.from('messages').update({
        'read': true,
      }).eq('id', rideEvent.id);
      expect(rideEvent.read, true);
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
      expect(rideEvent.category, RideEventCategory.approved.index);
      expect(rideEvent.read, true);
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
      expect(rideEvent[0].rideId, 1);
      expect(rideEvent[0].category, RideEventCategory.approved.index);
      expect(rideEvent[0].read, true);
      expect(rideEvent[1].id, 2);
      expect(rideEvent[1].createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(rideEvent[1].rideId, 1);
      expect(rideEvent[1].category, RideEventCategory.pending.index);
      expect(rideEvent[1].read, true);
    });

    test('parses an empty list of messages from json', () async {
      final List<Map<String, dynamic>> json = [];
      final List<RideEvent> rideEvent = RideEvent.fromJsonList(json);
      expect(rideEvent.length, 0);
    });
  });

  group('RideEvent.toJson', () {
    final RideEvent rideEvent = RideEventFactory().generateFake();
    final json = rideEvent.toJson();
    expect(json['ride_id'], rideEvent.rideId);
    expect(json['category'], rideEvent.category.index);
    expect(json['read'], rideEvent.read);
    expect(json.keys.length, 3);
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
