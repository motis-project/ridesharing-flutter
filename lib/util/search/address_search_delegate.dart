import 'package:flutter/material.dart';
import 'package:flutter_app/util/motis_handler.dart';
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
    returnFirstResult(context);
    return buildSuggestions(context);
  }

  // [bool mounted = true] is a hack to be able to use context
  // (StatelessWidget is always mounted, so this is fine)
  void returnFirstResult(BuildContext context, [bool mounted = true]) async {
    final List<AddressSuggestion> suggestions =
        await MotisHandler.getAddressSuggestions(query);

    if (suggestions.isEmpty) return;

    if (mounted) close(context, suggestions.first);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: MotisHandler.getAddressSuggestions(query),
      builder: (context, snapshot) {
        if (query.length < MotisHandler.searchLengthRequirement) {
          return const Center(
            child: Text('Please enter more information to get results'),
          );
        }

        if (snapshot.hasData) {
          List<AddressSuggestion> suggestions = snapshot.data!;

          if (suggestions.isNotEmpty) {
            return ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(suggestions[index].toString()),
                  onTap: () => close(context, suggestions[index]),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider();
              },
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
