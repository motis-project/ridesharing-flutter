import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/util/search/address_suggestion.dart';

class MotisHandler {
  static final HttpClient _httpClient = HttpClient();
  static const String _motisHost = 'europe.motis-project.de';

  // If the search is shorter than this, the server will return an empty list anyways.
  static const int searchLengthRequirement = 4;

  // Would be easier, but does not work:
  // http.Response res = await http.post(
  //   Uri.parse('https://europe.motis-project.de/?elm=AddressSuggestions'),
  //   body: json.encode({
  //     "destination": {"type": "Module", "target": "/address"},
  //     "content_type": "AddressRequest",
  //     "content": {"input": "Berlin Hsbf (tief)"}
  //   }),
  //   headers: {
  //     'Content-Type': 'application/json',
  //   },
  // );
  static Future<List<AddressSuggestion>> getAddressSuggestions(
    String input,
  ) async {
    if (input.length < searchLengthRequirement) return [];

    HttpClientRequest request = await _httpClient.postUrl(
      Uri(
        scheme: 'https',
        host: _motisHost,
        queryParameters: {'elm': 'AddressSuggestions'},
      ),
    );

    request.add(utf8.encode(json.encode({
      "destination": {"type": "Module", "target": "/address"},
      "content_type": "AddressRequest",
      "content": {"input": input}
    })));

    String response = await request.close().then((value) => value.transform(utf8.decoder).join());
    String response = await request.close().then((value) => value.transform(utf8.decoder).join());

    List<dynamic> guesses = json.decode(response)['content']['guesses'];

    var seen = <String>{};
    List<AddressSuggestion> addressSuggestions = guesses
        .map((guess) => AddressSuggestion.fromMotisResponse(guess))
        .where((suggestion) => seen.add(suggestion.toString()))
        .toList();

    return addressSuggestions;
  }
}
