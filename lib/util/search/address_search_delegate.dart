import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'address_suggestion.dart';
import 'address_suggestion_manager.dart';

class AddressSearchDelegate extends SearchDelegate<AddressSuggestion?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
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
  void returnFirstResult(BuildContext context, {bool mounted = true}) async {
    final List<AddressSuggestion> suggestions = await addressSuggestionManager.getSuggestions(query);

    if (mounted) close(context, suggestions.firstOrNull);
  }

  @override
  void close(BuildContext context, AddressSuggestion? result) {
    if (result != null) addressSuggestionManager.storeSuggestion(result);
    super.close(context, result);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, Function(VoidCallback) setState) {
        return FutureBuilder<List<AddressSuggestion>>(
          future: addressSuggestionManager.getSuggestions(query),
          builder: (BuildContext context, AsyncSnapshot<List<AddressSuggestion>> snapshot) {
            if (snapshot.hasData) {
              List<AddressSuggestion> suggestions = snapshot.data!;
              if (suggestions.isNotEmpty) {
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    AddressSuggestion suggestion = suggestions[index];
                    return ListTile(
                      leading: suggestion.getIcon(),
                      title: Text(suggestion.toString()),
                      trailing: suggestion.fromHistory
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                addressSuggestionManager.removeSuggestion(suggestion);
                                setState(() {
                                  suggestions.removeAt(index);
                                });
                              },
                            )
                          : null,
                      onTap: () => close(context, suggestion),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider();
                  },
                );
              }
            }
            return Center(
              child: query.length < AddressSuggestionManager.searchLengthRequirement
                  ? Text(S.of(context).searchAddressEnterMoreCharacters)
                  : const CircularProgressIndicator(),
            );
          },
        );
      },
    );
  }
}
