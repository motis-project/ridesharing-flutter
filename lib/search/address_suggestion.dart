import 'package:flutter/material.dart';

import 'position.dart';

class AddressSuggestion {
  final String name;
  final Position position;
  final AddressSuggestionType type;
  final String city;
  final String country;
  final String postalCode;

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
    final String name = json['name'] as String;
    const AddressSuggestionType type = AddressSuggestionType.place;

    final Map<String, dynamic> posJson = json['pos'] as Map<String, dynamic>;
    final Position pos = Position.fromDynamicValues(posJson['lat'], posJson['lng']);

    final List<Map<String, dynamic>> regions = List<Map<String, dynamic>>.from(json['regions'] as List<dynamic>);
    final String postalCode = _extractFromRegions(regions, <int>[13]);
    final String city = _extractFromRegions(regions, <int>[8, 7, 6, 5, 4]);
    final String country = _extractFromRegions(regions, <int>[2]);

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
    final String name = json['name'] as String;
    const AddressSuggestionType type = AddressSuggestionType.station;

    final Map<String, dynamic> posJson = json['pos'] as Map<String, dynamic>;
    final Position pos = Position.fromDynamicValues(posJson['lat'], posJson['lng']);

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
    final Set<AddressSuggestion> seen = <AddressSuggestion>{};
    return suggestions.where((AddressSuggestion suggestion) => seen.add(suggestion)).toList();
  }

  static String _extractFromRegions(List<Map<String, dynamic>> regions, List<int> adminLevels) {
    for (final int adminLevel in adminLevels) {
      try {
        final Map<String, dynamic> matchedRegion =
            regions.firstWhere((Map<String, dynamic> region) => region['admin_level'] == adminLevel);
        return matchedRegion['name'] as String;
      } catch (e) {
        continue;
      }
    }
    return '';
  }

  factory AddressSuggestion.fromJson(Map<String, dynamic> json, {bool fromHistory = false}) {
    return AddressSuggestion(
      name: json['name'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      type: AddressSuggestionType.values.firstWhere((AddressSuggestionType e) => e.name == json['type']),
      postalCode: json['postal_code'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      fromHistory: fromHistory,
      lastUsed: json['last_used'] != null ? DateTime.parse(json['last_used'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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
