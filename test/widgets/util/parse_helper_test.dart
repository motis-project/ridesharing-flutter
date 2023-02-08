import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/parse_helper.dart';

void main() {
  final ParseHelper parseHelper = ParseHelper();
  group('parseDouble', () {
    test('returns double', () async {
      expect(parseHelper.parseDouble(1), 1.0);
      expect(parseHelper.parseDouble(1.0), 1.0);
      expect(parseHelper.parseDouble(1.1), 1.1);
      expect(parseHelper.parseDouble(1.1), 1.1);
    });
    test('throws Exception when value is not num', () async {
      expect(() => parseHelper.parseDouble('1'), throwsException);
      expect(() => parseHelper.parseDouble(true), throwsException);
      expect(() => parseHelper.parseDouble(null), throwsException);
    });
  });

  group('parseListOfMaps', () {
    test('returns List of maps', () async {
      expect(parseHelper.parseListOfMaps([]), []);
      expect(parseHelper.parseListOfMaps([<String, dynamic>{}]), [{}]);
      expect(
          parseHelper.parseListOfMaps([
            {'a': 1},
            {'b': 2}
          ]),
          [
            {'a': 1},
            {'b': 2}
          ]);
    });
    test('throws Exception when value is not a List of Map', () async {
      expect(() => parseHelper.parseListOfMaps({}), throwsException);
      expect(() => parseHelper.parseListOfMaps('1'), throwsException);
      expect(() => parseHelper.parseListOfMaps(true), throwsException);
      expect(() => parseHelper.parseListOfMaps(null), throwsException);
    });
  });
}
