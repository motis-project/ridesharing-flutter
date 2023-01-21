import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';

import '../util/factories/ride_factory.dart';
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
  group('Ride.cancel', () {});
  group('Ride.withdraw', () {});
  group('Ride.toString', () {});
  group('Ride.duration', () {});
  group('Ride.isFinished', () {});
  group('Ride.isOngoing', () {});
  group('Ride.overlapsWith', () {});
  group('Ride.overlapsWithTimeRange', () {});
  group('RideStatus.isCancelled', () {
    test('returns false if ride is not cancelled', () {
      Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      expect(ride.status.isCancelled(), false);
    });
    test('returns true if ride is cancelledByDriver', () {
      Ride ride = RideFactory().generateFake(status: RideStatus.cancelledByDriver);
      expect(ride.status.isCancelled(), true);
    });
    test('returns true if ride is cancelledByRide', () {
      Ride ride = RideFactory().generateFake(status: RideStatus.cancelledByRider);
      expect(ride.status.isCancelled(), true);
    });
  });
  group('RideStatus.isApproved', () {
    test('returns true if ride is approved', () {
      Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      expect(ride.status.isApproved(), true);
    });
    test('returns false if ride is not approved', () {
      Ride ride = RideFactory().generateFake(status: RideStatus.pending);
      expect(ride.status.isApproved(), false);
    });
  });
}
