import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:fuzzywuzzy/model/extracted_result.dart';

import '../storage_manager.dart';
import '../supabase.dart';
import 'address_suggestion.dart';

final AddressSuggestionManager addressSuggestionManager = AddressSuggestionManager();

class AddressSuggestionManager {
  static final HttpClient _httpClient = HttpClient();
  static const String _motisHost = 'europe.motis-project.de';
  static const String _storageKey = 'suggestions';
  static const int _maxSuggestionsStored = 100;

  static List<AddressSuggestion> _historySuggestions = <AddressSuggestion>[];

  // If the search is shorter than this, the server will return an empty list anyways.
  static const int searchLengthRequirement = 3;

  static const Map<String, int> _suggestionsCount = <String, int>{
    'history': 3,
    'station': 3,
    'address': 5,
  };

  // If the fuzzy search score is below this, the result will not be shown.
  static const int _fuzzySearchCutoff = 60;

  Future<List<AddressSuggestion>> getSuggestions(String query) async {
    final List<List<AddressSuggestion>> suggestionsByCategory = await Future.wait(<Future<List<AddressSuggestion>>>[
      getHistorySuggestions(query),
      getStationSuggestions(query),
      getAddressSuggestions(query),
    ]);

    final List<AddressSuggestion> suggestionsList =
        suggestionsByCategory.expand((List<AddressSuggestion> element) => element).toList();

    return AddressSuggestion.deduplicate(suggestionsList);
  }

  Future<void> loadHistorySuggestions() async {
    final List<String> data = await StorageManager.readStringList(getStorageKey());

    final Iterable<Map<String, dynamic>> suggestions = data.map((String suggestion) => jsonDecode(suggestion));
    _historySuggestions = suggestions
        .map((Map<String, dynamic> suggestion) => AddressSuggestion.fromJson(suggestion, fromHistory: true))
        .toList();
  }

  Future<void> storeSuggestion(AddressSuggestion suggestion) async {
    final AddressSuggestion? previousSuggestion =
        _historySuggestions.firstWhereOrNull((AddressSuggestion element) => element == suggestion);

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
    final List<String> data =
        _historySuggestions.map((AddressSuggestion suggestion) => jsonEncode(suggestion.toJson())).toList();

    StorageManager.saveData(getStorageKey(), data);
  }

  void sortHistorySuggestions() {
    _historySuggestions.sort((AddressSuggestion a, AddressSuggestion b) => a.compareTo(b));
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
  Future<List<Map<String, dynamic>>> _doRequest(
    String elm,
    String target,
    String contentType,
    String query,
  ) async {
    if (query.length < searchLengthRequirement) return <Map<String, dynamic>>[];

    final HttpClientRequest request = await _httpClient.postUrl(
      Uri(
        scheme: 'https',
        host: _motisHost,
        queryParameters: <String, String>{'elm': elm},
      ),
    );

    request.add(
      utf8.encode(
        json.encode(<String, dynamic>{
          'destination': <String, dynamic>{'type': 'Module', 'target': target},
          'content_type': contentType,
          'content': <String, dynamic>{'input': query}
        }),
      ),
    );

    final String response =
        await request.close().then((HttpClientResponse value) => value.transform(utf8.decoder).join());

    final Map<String, dynamic> responseMap = json.decode(response);

    final List<Map<String, dynamic>> guesses =
        pick(responseMap, 'content', 'guesses').asListOrEmpty((RequiredPick p0) => p0.value as Map<String, dynamic>);

    return guesses;
  }

  Future<List<AddressSuggestion>> getHistorySuggestions(String query) async {
    sortHistorySuggestions();

    if (query == '') return _historySuggestions.take(15).toList();

    final List<ExtractedResult<AddressSuggestion>> fuzzyResults = extractTop<AddressSuggestion>(
      query: query,
      choices: _historySuggestions,
      getter: (AddressSuggestion suggestion) => suggestion.toString(),
      limit: _suggestionsCount['history']!,
      cutoff: _fuzzySearchCutoff,
    ).toList();

    fuzzyResults.sort((ExtractedResult<AddressSuggestion> a, ExtractedResult<AddressSuggestion> b) {
      final int scoreDifference = b.score - a.score;
      final int timeDifference = a.choice.lastUsed.millisecondsSinceEpoch - b.choice.lastUsed.millisecondsSinceEpoch;

      return scoreDifference + timeDifference ~/ 100000000;
    });

    return fuzzyResults.map((ExtractedResult<AddressSuggestion> result) => result.choice).toList();
  }

  Future<List<AddressSuggestion>> getStationSuggestions(String query) async {
    final List<Map<String, dynamic>> suggestions = await _doRequest(
      'StationSuggestions',
      '/guesser',
      'StationGuesserRequest',
      query,
    );

    final Iterable<AddressSuggestion> stationSuggestions =
        suggestions.map((Map<String, dynamic> suggestion) => AddressSuggestion.fromMotisStationResponse(suggestion));

    return stationSuggestions.take(_suggestionsCount['station']!).toList();
  }

  Future<List<AddressSuggestion>> getAddressSuggestions(String query) async {
    final List<Map<String, dynamic>> suggestions = await _doRequest(
      'AddressSuggestions',
      '/address',
      'AddressRequest',
      query,
    );

    final List<AddressSuggestion> addressSuggestions = suggestions
        .map((Map<String, dynamic> suggestion) => AddressSuggestion.fromMotisAddressResponse(suggestion))
        .toList();

    final List<AddressSuggestion> deduplicatedSuggestions = AddressSuggestion.deduplicate(addressSuggestions);

    return deduplicatedSuggestions.take(_suggestionsCount['address']!).toList();
  }

  String getStorageKey() {
    return '$_storageKey.${SupabaseManager.getCurrentProfile()?.id}';
  }
}
