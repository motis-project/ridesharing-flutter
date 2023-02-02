import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

void main() {
  group('Named constructors', () {
    test('Position.fromJson', () {
      final Map<String, dynamic> json = {
        //TODO Is is possible for this to be an int?
        'lat': 50.0,
        'lng': 8.2714,
      };
      final Position position = Position.fromJson(json);
      expect(position.lat, 50);
      expect(position.lng, 8.2714);
    });

    test('Position.fromDynamicValues', () {
      final Map<String, dynamic> json = {
        'lat': 50,
        'lng': 8.2714,
      };
      final Position position = Position.fromDynamicValues(json['lat'], json['lng']);
      expect(position.lat, 50);
      expect(position.lng, 8.2714);
    });
  });

  group('ProfileFeature.toJson', () {
    test('returns a json representation of the ProfileFeature', () async {
      final Position position = Position(50, 8.2714);
      final Map<String, dynamic> json = position.toJson();
      expect(json['lat'], 50);
      expect(json['lng'], 8.2714);
      expect(json.keys.length, 2);
    });
  });

  group('Position ==', () {
    test('equal', () {
      final Position position1 = Position(50, 8.2714);
      final Position position2 = Position(50, 8.2714);
      expect(position1 == position2, isTrue);
    });

    test('not equal', () {
      final Position position1 = Position(50, 8.2714);
      final Position position2 = Position(50, 8.2715);
      expect(position1 == position2, isFalse);
    });
  });

  group('Position.hashCode', () {
    test('Mainz', () {
      final Position position = Position(50, 8.2714);
      expect(position.hashCode, 9159982800490006);
    });
  });

  group('Position.distanceTo', () {
    test('Paris to Prague', () {
      final Position paris = Position(48.8566, 2.3522);
      final Position prague = Position(50.0755, 14.4378);
      final double distance = paris.distanceTo(prague);
      expect(distance.toInt(), 882);
    });
  });
}
