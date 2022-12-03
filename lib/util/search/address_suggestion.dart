import 'package:flutter_app/util/search/position.dart';

class AddressSuggestion {
  final Position position;
  final String name;
  final String type;

  AddressSuggestion(this.name, this.position, this.type);

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      json['name'],
      Position(json['pos']['lat'], json['pos']['lng']),
      json['type'],
    );
  }
}
