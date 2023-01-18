ParseHelper parseHelper = ParseHelper();

class ParseHelper {
  double parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    throw Exception('Cannot parse $value to double');
  }

  List<Map<String, dynamic>> parseListOfMaps(dynamic value) {
    if (value is List) {
      return value.cast<Map<String, dynamic>>();
    }
    throw Exception('Cannot parse $value to List<Map<String, dynamic>>');
  }
}
