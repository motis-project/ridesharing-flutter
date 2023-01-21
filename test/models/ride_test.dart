import 'package:flutter_test/flutter_test.dart';

import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

void main() {
  MockUrlProcessor rideProcessor = MockUrlProcessor();
  setUp(() async {
    MockServer.setProcessor(rideProcessor);
  });

  group('Ride.previewFromDrive', () {});
  group('Ride.fromJson', () {});
  group('Ride.fromJsonList', () {});
  group('Ride.toJson', () {});
  group('Ride.toJsonforApi', () {});
  group('Ride.userHasRideAtTimeRange', () {});
  group('Ride.getRidesOfUser', () {});
  group('Ride.equals', () {});
  group('Ride.getDrive', () {});
  group('Ride.getDriver', () {});
  group('Ride.getRider', () {});
  group('Ride.cancel', () {});
  group('Ride.withdraw', () {});
  group('Ride.toString', () {});
  group('Ride.duration', () {});
  group('Ride.isFinished', () {});
  group('Ride.isOngoing', () {});
  group('Ride.overlapsWith', () {});
  group('Ride.overlapsWithTimeRange', () {});
  group('RideStatus enum', () {});
  group('RideStatus.isCancelled', () {});
  group('RideStatus.isApproved', () {});
}
