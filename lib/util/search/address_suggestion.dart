import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

class AddressSuggestion {
  final Position position;
  final String name;
  final String postalCode;
  final String city;
  final String country;
  final AddressSuggestionType type;

  bool fromHistory;
  DateTime lastUsed;

  AddressSuggestion({
    required this.name,
    required this.position,
    required this.type,
    required this.city,
    required this.country,
    required this.postalCode,
    this.fromHistory = false,
    required this.lastUsed,
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
      lastUsed: DateTime.now(),
    );
  }

  factory AddressSuggestion.fromMotisStationResponse(Map<String, dynamic> json) {
    String name = json['name'];
    AddressSuggestionType type = AddressSuggestionType.station;

    Position pos = Position(json['pos']['lat'], json['pos']['lng']);

    return AddressSuggestion(
      name: name,
      position: pos,
      type: type,
      postalCode: '',
      city: '',
      country: '',
      lastUsed: DateTime.now(),
    );
  }

  static List<AddressSuggestion> deduplicate(List<AddressSuggestion> suggestions) {
    var seen = <AddressSuggestion>{};
    return suggestions.where((suggestion) => seen.add(suggestion)).toList();
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

  factory AddressSuggestion.fromJson(Map<String, dynamic> json, {bool fromHistory = false}) {
    return AddressSuggestion(
      name: json['name'],
      position: Position.fromJson(json['position']),
      type: AddressSuggestionType.values.firstWhere((e) => e.name == json['type']),
      postalCode: json['postal_code'],
      city: json['city'],
      country: json['country'],
      fromHistory: fromHistory,
      lastUsed: json['last_used'] != null ? DateTime.parse(json['last_used']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'position': position.toJson(),
      'type': type.name,
      'postal_code': postalCode,
      'city': city,
      'country': country,
      'last_used': lastUsed.toIso8601String(),
    };
  }

  Icon getIcon() {
    if (fromHistory) return const Icon(Icons.history);

    switch (type) {
      case AddressSuggestionType.place:
        return const Icon(Icons.place);
      case AddressSuggestionType.station:
        return const Icon(Icons.train);
    }
  }

  int compareTo(AddressSuggestion other) {
    if (fromHistory && !other.fromHistory) return -1;
    if (!fromHistory && other.fromHistory) return 1;

    // Newer (higher) timestamp is better
    return other.lastUsed.compareTo(lastUsed);
  }

  @override
  bool operator ==(Object other) {
    if (other is! AddressSuggestion) return false;

    return name == other.name &&
        position == other.position &&
        type == other.type &&
        postalCode == other.postalCode &&
        city == other.city &&
        country == other.country;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    if (type == AddressSuggestionType.place) return "$name (${postalCode != '' ? '$postalCode ' : ''}$city, $country)";

    return name;
  }
}

enum AddressSuggestionType { place, station }
