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
}
