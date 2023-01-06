class Position {
  final double lat;
  final double lng;

  Position(this.lat, this.lng);

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(json['lat'], json['lng']);
  }

  Map<String, dynamic> toJson() {
    return {
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
