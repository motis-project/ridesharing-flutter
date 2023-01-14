import 'dart:convert';

abstract class Model {
  final int? id;
  final DateTime? createdAt;

  Model({
    this.id,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (other is Model) {
      return runtimeType == other.runtimeType && id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson();

  Map<String, dynamic> toJsonForApi() {
    return toJson()
      ..addAll(
        {
          'id': id,
          'created_at': createdAt?.toIso8601String(),
        },
      );
  }
}
