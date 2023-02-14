import 'package:faker/faker.dart';
import 'package:motis_mitfahr_app/util/search/address_suggestion.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

class AddressSuggestionFactory {
  AddressSuggestion generateFake({
    String? name,
    Position? position,
    AddressSuggestionType? type,
    String? city,
    String? country,
    String? postalCode,
    bool? fromHistory,
    DateTime? lastUsed,
    bool createDependencies = true,
  }) {
    final String fakerCity = faker.address.city();
    return AddressSuggestion(
        name: name ?? fakerCity,
        position: position ?? Position(faker.geo.latitude(), faker.geo.longitude()),
        type: type ?? AddressSuggestionType.place,
        city: city ?? fakerCity,
        country: country ?? faker.address.country(),
        postalCode: postalCode ?? faker.address.zipCode(),
        lastUsed: lastUsed ?? faker.date.dateTime());
  }
}
