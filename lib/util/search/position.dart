import 'dart:math';

import '../parse_helper.dart';

class Position {
  final double lat;
  final double lng;

  Position(this.lat, this.lng);

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position.fromDynamicValues(json['lat'], json['lng']);
  }

  factory Position.fromDynamicValues(dynamic lat, dynamic lng) {
    return Position(parseHelper.parseDouble(lat), parseHelper.parseDouble(lng));
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lat': lat,
      'lng': lng,
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! Position) return false;

    return lat == other.lat && lng == other.lng;
  }

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;

  double distanceTo(Position other) {
    //https://stackoverflow.com/a/69437789/13763039
    const double p = 0.017453292519943295;
    const double Function(num) c = cos;
    final double a =
        0.5 - c((other.lat - lat) * p) / 2 + c(lat * p) * c(other.lat * p) * (1 - c((other.lng - lng) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
