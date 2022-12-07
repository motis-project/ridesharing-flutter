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
  //   Uri.parse('https://europe.motis-project.de/?elm=$elm'),
  //   body: json.encode({
  //     "destination": {"type": "Module", "target": target},
  //     "content_type": contentType,
  //     "content": {"input": input, "guess_count": guessCount}
  //   }),
  //   headers: {
  //     'Content-Type': 'application/json',
  //   },
  // );
  static Future<List<dynamic>> _doRequest(
    String elm,
    String target,
    String contentType,
    String input,
    int guessCount,
  ) async {
    if (input.length < searchLengthRequirement) return [];

    HttpClientRequest request = await _httpClient.postUrl(
      Uri(
        scheme: 'https',
        host: _motisHost,
        queryParameters: {'elm': elm},
      ),
    );

    request.add(utf8.encode(json.encode({
      "destination": {"type": "Module", "target": target},
      "content_type": contentType,
      "content": {"input": input, "guess_count": guessCount}
    })));

    String response = await request.close().then((value) => value.transform(utf8.decoder).join());
    String response = await request.close().then((value) => value.transform(utf8.decoder).join());

    return json.decode(response)['content']['guesses'];
  }

  static Future<List<AddressSuggestion>> getSuggestions(String input) async {
    List<AddressSuggestion> stationSuggestions = await getStationSuggestions(input);
    List<AddressSuggestion> addressSuggestions = await getAddressSuggestions(input);

    return stationSuggestions + addressSuggestions;
  }

  static Future<List<AddressSuggestion>> getStationSuggestions(String input) async {
    List<dynamic> suggestions = await _doRequest('StationSuggestions', '/guesser', 'StationGuesserRequest', input, 5);

    List<AddressSuggestion> stationSuggestions =
        suggestions.map((suggestion) => AddressSuggestion.fromMotisStationResponse(suggestion)).toList();

    return stationSuggestions;
  }

  static Future<List<AddressSuggestion>> getAddressSuggestions(String input) async {
    List<dynamic> suggestions = await _doRequest('AddressSuggestions', '/address', 'AddressRequest', input, 8);

    var seen = <String>{};
    List<AddressSuggestion> addressSuggestions = suggestions
        .map((suggestion) => AddressSuggestion.fromMotisAddressResponse(suggestion))
        .where((suggestion) => seen.add(suggestion.toString()))
        .toList();

    return addressSuggestions;
  }
}
