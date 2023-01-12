import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:motis_mitfahr_app/util/search/address_suggestion.dart';
import 'package:motis_mitfahr_app/util/storage_manager.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:fuzzywuzzy/model/extracted_result.dart';

final addressSuggestionManager = AddressSuggestionManager();

class AddressSuggestionManager {
  static final HttpClient _httpClient = HttpClient();
  static const String _motisHost = 'europe.motis-project.de';
  static const String _storageKey = 'suggestions';
  static const int _maxSuggestionsStored = 100;

  static late List<AddressSuggestion> _historySuggestions;

  // If the search is shorter than this, the server will return an empty list anyways.
  static const int searchLengthRequirement = 3;

  static const Map<String, int> _suggestionsCount = {
    'history': 3,
    'station': 3,
    'address': 5,
  };

  // If the fuzzy search score is below this, the result will not be shown.
  static const int _fuzzySearchCutoff = 60;

  Future<List<AddressSuggestion>> getSuggestions(String query) async {
    final suggestionsByCategory = await Future.wait([
      getHistorySuggestions(query),
      getStationSuggestions(query),
      getAddressSuggestions(query),
    ]);

    List<AddressSuggestion> suggestionsList = suggestionsByCategory.expand((element) => element).toList();

    return AddressSuggestion.deduplicate(suggestionsList);
  }

  void loadHistorySuggestions() async {
    List<String> data = await StorageManager.readStringList(getStorageKey());

    Iterable<Map<String, dynamic>> suggestions = data.map((suggestion) => jsonDecode(suggestion));
    _historySuggestions =
        suggestions.map((suggestion) => AddressSuggestion.fromJson(suggestion, fromHistory: true)).toList();
  }

  Future<void> storeSuggestion(AddressSuggestion suggestion) async {
    AddressSuggestion? previousSuggestion = _historySuggestions.firstWhereOrNull((element) => element == suggestion);

    if (previousSuggestion != null) {
      previousSuggestion.lastUsed = DateTime.now();
    } else {
      suggestion.fromHistory = true;
      _historySuggestions.add(suggestion);

      if (_historySuggestions.length > _maxSuggestionsStored) {
        sortHistorySuggestions();
        _historySuggestions.removeLast();
      }

      saveHistorySuggestionsToStorage();
    }
  }

  void removeSuggestion(AddressSuggestion suggestion) {
    _historySuggestions.remove(suggestion);

    saveHistorySuggestionsToStorage();
  }

  void saveHistorySuggestionsToStorage() {
    List<String> data = _historySuggestions.map((suggestion) => jsonEncode(suggestion.toJson())).toList();

    StorageManager.saveData(getStorageKey(), data);
  }

  void sortHistorySuggestions() {
    _historySuggestions.sort((a, b) => a.compareTo(b));
  }

  // Would be easier, but does not work:
  // http.Response res = await http.post(
  //   Uri.parse('https://europe.motis-project.de/?elm=$elm'),
  //   body: json.encode({
  //     "destination": {"type": "Module", "target": target},
  //     "content_type": contentType,
  //     "content": {"input": query}
  //   }),
  //   headers: {
  //     'Content-Type': 'application/json',
  //   },
  // );
  Future<List<dynamic>> _doRequest(
    String elm,
    String target,
    String contentType,
    String query,
  ) async {
    if (query.length < searchLengthRequirement) return [];

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
      "content": {"input": query}
    })));

    String response = await request.close().then((value) => value.transform(utf8.decoder).join());

    return json.decode(response)['content']['guesses'];
  }

  Future<List<AddressSuggestion>> getHistorySuggestions(String query) async {
    sortHistorySuggestions();

    if (query == '') return _historySuggestions.take(15).toList();

    List<ExtractedResult<AddressSuggestion>> fuzzyResults = extractTop<AddressSuggestion>(
      query: query,
      choices: _historySuggestions,
      getter: (suggestion) => suggestion.toString(),
      limit: _suggestionsCount['history']!,
      cutoff: _fuzzySearchCutoff,
    ).toList();

    fuzzyResults.sort((a, b) {
      int scoreDifference = b.score - a.score;
      int timeDifference = a.choice.lastUsed.millisecondsSinceEpoch - b.choice.lastUsed.millisecondsSinceEpoch;

      return scoreDifference + timeDifference ~/ 100000000;
    });

    return fuzzyResults.map((result) => result.choice).toList();
  }

  Future<List<AddressSuggestion>> getStationSuggestions(String query) async {
    List<dynamic> suggestions = await _doRequest(
      'StationSuggestions',
      '/guesser',
      'StationGuesserRequest',
      query,
    );

    Iterable<AddressSuggestion> stationSuggestions =
        suggestions.map((suggestion) => AddressSuggestion.fromMotisStationResponse(suggestion));

    return stationSuggestions.take(_suggestionsCount['station']!).toList();
  }

  Future<List<AddressSuggestion>> getAddressSuggestions(String query) async {
    List<dynamic> suggestions = await _doRequest(
      'AddressSuggestions',
      '/address',
      'AddressRequest',
      query,
    );

    List<AddressSuggestion> addressSuggestions =
        suggestions.map((suggestion) => AddressSuggestion.fromMotisAddressResponse(suggestion)).toList();

    List<AddressSuggestion> deduplicatedSuggestions = AddressSuggestion.deduplicate(addressSuggestions);

    return deduplicatedSuggestions.take(_suggestionsCount['address']!).toList();
  }

  String getStorageKey() {
    return "$_storageKey.${SupabaseManager.getCurrentProfile()?.id}";
  }
}
