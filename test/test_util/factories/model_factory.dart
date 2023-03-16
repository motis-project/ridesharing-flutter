import 'dart:convert';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:motis_mitfahr_app/model.dart';

abstract class ModelFactory<T extends Model> {
  Random get random => Random();
  Faker get faker => Faker();

  int get randomId => random.nextInt(10000000);

  T generateFake({
    int? id,
    DateTime? createdAt,
    bool createDependencies = true,
  });
  String generateFakeJson() => jsonEncode(generateFake().toJsonForApi());

  List<T> generateFakeList({int? length, bool createDependencies = true}) =>
      List.generate(length ?? random.nextInt(2) + 1, (index) => generateFake(createDependencies: createDependencies));

  List<Map<String, dynamic>> generateFakeJsonList({int? length}) =>
      generateFakeList(length: length).map((e) => e.toJsonForApi()).toList();

  U getNullableParameterOr<U>(NullableParameter? parameter, U defaultValue) {
    return parameter == null ? defaultValue : parameter.value;
  }
}

class NullableParameter<T> {
  T? value;

  NullableParameter(this.value);
}
