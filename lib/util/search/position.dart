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
}
