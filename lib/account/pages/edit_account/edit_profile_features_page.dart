import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:motis_mitfahr_app/util/buttons/button.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/profile.dart';
import '../../models/profile_feature.dart';

class EditProfileFeaturesPage extends StatefulWidget {
  final Profile profile;

  const EditProfileFeaturesPage(this.profile, {super.key});

  @override
  State<EditProfileFeaturesPage> createState() => _EditProfileFeaturesPageState();
}

class _EditProfileFeaturesPageState extends State<EditProfileFeaturesPage> {
  late List<ProfileFeature> _profileFeatures;
  late List<Feature> _features;
  late List<Feature> _otherFeatures;

  @override
  void initState() {
    super.initState();
    _profileFeatures = widget.profile.profileFeatures!;
    _features = _profileFeatures.map((e) => e.feature).toList();
    _otherFeatures = Feature.values.where((e) => !_features.contains(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageProfileEditProfileFeaturesTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            Flexible(
              child: ReorderableListView.builder(
                header: _features.isEmpty
                    ? Semantics(
                        label: S.of(context).pageProfileEditProfileFeaturesHint,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      )
                    : null,
                shrinkWrap: true,
                onReorder: onReorder,
                itemCount: Feature.values.length + 1,
                itemBuilder: (context, index) {
                  if (index < _features.length) {
                    Feature feature = _features[index];
                    return ListTile(
                      key: ValueKey(index),
                      leading: feature.getIcon(context),
                      title: Semantics(
                        label: S.of(context).pageProfileEditProfileFeaturesSelected,
                        child: Text(feature.getDescription(context)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            onPressed: () => _removeFeature(index),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    );
                  } else if (index == _features.length) {
                    return const IgnorePointer(
                      key: ValueKey('divider'),
                      child: Divider(
                        thickness: 5,
                      ),
                    );
                  } else {
                    Feature feature = _otherFeatures[index - _features.length - 1];
                    return ListTile(
                      textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      key: ValueKey(index),
                      leading: feature.getIcon(context),
                      title: Semantics(
                        label: S.of(context).pageProfileEditProfileFeaturesNotSelected,
                        child: Text(feature.getDescription(context)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            onPressed: () => _addFeature(index),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Button(
              S.of(context).save,
              onPressed: () => onPressed(context),
            ),
          ],
        ),
      ),
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    int dividerIndex = _features.length;

    setState(() {
      if (newIndex <= dividerIndex && oldIndex > dividerIndex) {
        return _addFeature(oldIndex, newIndex: newIndex);
      }

      if (newIndex > dividerIndex && oldIndex < dividerIndex) {
        return _removeFeature(oldIndex, newIndex: newIndex);
      }

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      // Moving a feature in the list
      if (newIndex < dividerIndex && oldIndex < dividerIndex) {
        final feature = _features.removeAt(oldIndex);
        _features.insert(newIndex, feature);
        return;
      }

      if (newIndex > dividerIndex && oldIndex > dividerIndex) {
        final feature = _otherFeatures.removeAt(oldIndex - dividerIndex - 1);
        _otherFeatures.insert(newIndex - dividerIndex - 1, feature);
        return;
      }
    });
  }

  void _removeFeature(int index, {int? newIndex}) {
    int dividerIndex = _features.length;

    setState(() {
      Feature oldFeature = _features.removeAt(index);

      if (newIndex != null) {
        int indexInOtherFeatures = newIndex - dividerIndex - 1;
        _otherFeatures.insert(indexInOtherFeatures, oldFeature);
      } else {
        _otherFeatures.add(oldFeature);
      }
    });
  }

  void _addFeature(int index, {int? newIndex}) {
    int dividerIndex = _features.length;
    int indexInOtherFeatures = index - dividerIndex - 1;

    setState(() {
      Feature newFeature = _otherFeatures[indexInOtherFeatures];
      Feature? mutuallyExclusiveFeature =
          _features.firstWhereOrNull((feature) => feature.isMutuallyExclusive(newFeature));
      if (mutuallyExclusiveFeature != null) {
        String description = mutuallyExclusiveFeature.getDescription(context);
        String text = S.of(context).pageProfileEditProfileFeaturesMutuallyExclusive(description);
        SemanticsService.announce(text, TextDirection.ltr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text)),
        );
        return;
      }

      _otherFeatures.removeAt(indexInOtherFeatures);

      if (newIndex != null) {
        _features.insert(newIndex, newFeature);
      } else {
        _features.add(newFeature);
      }
    });
  }

  void onPressed(context) async {
    final previousFeatures = _profileFeatures.map((e) => e.feature).toList();

    for (int index = 0; index < _features.length; index++) {
      final feature = _features[index];

      if (!previousFeatures.contains(feature)) {
        await SupabaseManager.supabaseClient.from('profile_features').insert({
          'profile_id': widget.profile.id,
          'feature': feature.index,
          'rank': index,
        });
      } else {
        await SupabaseManager.supabaseClient
            .from('profile_features')
            .update({'rank': index})
            .eq('profile_id', widget.profile.id)
            .eq('feature', feature.index);
      }
    }
    final removedFeatures = previousFeatures.where((e) => !_features.contains(e)).toList();
    for (Feature feature in removedFeatures) {
      await SupabaseManager.supabaseClient
          .from('profile_features')
          .delete()
          .eq('profile_id', widget.profile.id)
          .eq('feature', feature.index);
    }

    Navigator.of(context).pop();
  }
}
