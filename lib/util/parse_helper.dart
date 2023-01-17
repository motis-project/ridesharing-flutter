ParseHelper parseHelper = ParseHelper();

class ParseHelper {
  parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  parseListOfMaps(dynamic value) {
    if (value is List) {
      return value.cast<Map<String, dynamic>>();
    }
    return null;
  }
}
