import 'package:flutter_app/util/search/position.dart';

class AddressSuggestion {
  final Position position;
  final String name;
  final String postalCode;
  final String city;
  final String country;
  final AddressSuggestionType type;

  AddressSuggestion({
    required this.name,
    required this.position,
    required this.type,
    required this.city,
    required this.country,
    required this.postalCode,
  });

  factory AddressSuggestion.fromMotisAddressResponse(Map<String, dynamic> json) {
    String name = json['name'];
    AddressSuggestionType type = AddressSuggestionType.place;

    Position pos = Position(json['pos']['lat'], json['pos']['lng']);

    List<Map<String, dynamic>> regions = List<Map<String, dynamic>>.from(json['regions']);
    String postalCode = _extractFromRegions(regions, [13]);
    String city = _extractFromRegions(regions, [8, 7, 6, 5, 4]);
    String country = _extractFromRegions(regions, [2]);

    return AddressSuggestion(
      name: name,
      position: pos,
      type: type,
      postalCode: postalCode,
      city: city,
      country: country,
    );
  }

  static String _extractFromRegions(List<Map<String, dynamic>> regions, List<int> adminLevels) {
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
    if (type == AddressSuggestionType.place) return "$name (${postalCode != '' ? '$postalCode ' : ''}$city, $country)";

    return name;
  }
}

enum AddressSuggestionType { place, station }
