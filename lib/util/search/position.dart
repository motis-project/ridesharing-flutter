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
}
