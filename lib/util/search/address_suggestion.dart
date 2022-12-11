import 'package:flutter_app/util/search/position.dart';

class AddressSuggestion {
  final Position position;
  final String name;
  final String postalCode;
  final String city;
  final String country;
  final String type;

  AddressSuggestion({
    required this.name,
    required this.position,
    required this.type,
    required this.city,
    required this.country,
    required this.postalCode,
  });

  factory AddressSuggestion.fromMotisResponse(Map<String, dynamic> json) {
    String name = json['name'];

    List<Map<String, dynamic>> regions = List<Map<String, dynamic>>.from(json['regions']);
    Position pos = Position(json['pos']['lat'], json['pos']['lng']);

    String postalCode = _extractFromRegion(regions, [13]);
    String city = _extractFromRegion(regions, [8, 7, 6, 5, 4]);
    String country = _extractFromRegion(regions, [2]);

    return AddressSuggestion(
      name: name,
      position: pos,
      type: json['type'],
      postalCode: postalCode,
      city: city,
      country: country,
    );
  }

  static String _extractFromRegion(List<Map<String, dynamic>> regions, List<int> adminLevels) {
    for (int adminLevel in adminLevels) {
      try {
        return regions.firstWhere((region) => region['admin_level'] == adminLevel)['name'];
      } catch (e) {
        continue;
      }
    }
    return '';
  }

  @override
  String toString() {
    return "$name (${postalCode != '' ? '$postalCode ' : ''}$city, $country)";
  }
}
