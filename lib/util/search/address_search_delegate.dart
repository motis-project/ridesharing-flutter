import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/util/search/address_suggestion_manager.dart';
import 'package:flutter_app/util/search/address_suggestion.dart';

class AddressSearchDelegate extends SearchDelegate<AddressSuggestion?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // This method is used when pressing enter, so we just return the first result here
    returnFirstResult(context);
    return buildSuggestions(context);
  }

  // [bool mounted = true] is a hack to be able to use context
  // (StatelessWidget is always mounted, so this is fine)
  void returnFirstResult(BuildContext context, [bool mounted = true]) async {
    final List<AddressSuggestion> suggestions = await addressSuggestionManager.getAddressSuggestions(query);

    if (mounted) close(context, suggestions.firstOrNull);
  }

  @override
  void close(BuildContext context, AddressSuggestion? result) {
    if (result != null) addressSuggestionManager.storeSuggestion(result);
    super.close(context, result);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: addressSuggestionManager.getSuggestions(query),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<AddressSuggestion> suggestions = snapshot.data!;
          print("Suggestions: $suggestions");
          if (suggestions.isNotEmpty) {
            return ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var suggestion = suggestions[index];
                return ListTile(
                  leading: suggestion.getIcon(),
                  title: Text(suggestions[index].toString()),
                  onTap: () => close(context, suggestions[index]),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider();
              },
            );
          } else {
            return const Center(
              child: Text('Please enter more information to get results'),
            );
          }
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
