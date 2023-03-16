import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../managers/supabase_manager.dart';
import '../../../util/buttons/button.dart';
import '../../../util/snackbar.dart';
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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileFeatures = widget.profile.profileFeatures!;
    _features = _profileFeatures.map((ProfileFeature e) => e.feature).toList();
    _otherFeatures = Feature.values.where((Feature e) => !_features.contains(e)).toList();
  }

  ReorderableDragStartListener buildDragStartListener(int index) {
    return ReorderableDragStartListener(
      index: index,
      key: const Key('dragHandle'),
      child: const Icon(Icons.drag_handle),
    );
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
          children: <Widget>[
            Flexible(
              child: ReorderableListView.builder(
                header: _features.isEmpty
                    ? Semantics(
                        label: S.of(context).pageProfileEditProfileFeaturesHint,
                        key: const Key('emptyList'),
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
                itemBuilder: (BuildContext context, int index) {
                  if (index < _features.length) {
                    final Feature feature = _features[index];
                    return ListTile(
                      key: ValueKey<int>(index),
                      leading: feature.getIcon(context),
                      title: Semantics(
                        label: S.of(context).pageProfileEditProfileFeaturesSelected,
                        key: Key('$feature Tile'),
                        child: Text(feature.getDescription(context)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            onPressed: () => _removeFeature(index),
                            icon: const Icon(Icons.remove_circle_outline),
                            key: const Key('removeButton'),
                          ),
                          buildDragStartListener(index),
                        ],
                      ),
                    );
                  } else if (index == _features.length) {
                    return const IgnorePointer(
                      key: ValueKey<String>('divider'),
                      child: Divider(
                        thickness: 5,
                      ),
                    );
                  } else {
                    final Feature feature = _otherFeatures[index - _features.length - 1];
                    return ListTile(
                      textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      key: ValueKey<int>(index),
                      leading: feature.getIcon(context),
                      title: Semantics(
                        label: S.of(context).pageProfileEditProfileFeaturesNotSelected,
                        key: Key('$feature Tile'),
                        child: Text(feature.getDescription(context)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            onPressed: () => _addFeature(index),
                            icon: const Icon(Icons.add_circle_outline),
                            key: const Key('addButton'),
                          ),
                          buildDragStartListener(index),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Button(
              S.of(context).save,
              onPressed: _isSaving ? null : onPressed,
              key: const Key('saveButton'),
            ),
          ],
        ),
      ),
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    final int dividerIndex = _features.length;

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
        final Feature feature = _features.removeAt(oldIndex);
        _features.insert(newIndex, feature);
        return;
      }

      if (newIndex > dividerIndex && oldIndex > dividerIndex) {
        final Feature feature = _otherFeatures.removeAt(oldIndex - dividerIndex - 1);
        _otherFeatures.insert(newIndex - dividerIndex - 1, feature);
        return;
      }
    });
  }

  void _removeFeature(int index, {int? newIndex}) {
    final int dividerIndex = _features.length;

    setState(() {
      final Feature oldFeature = _features.removeAt(index);

      if (newIndex != null) {
        final int indexInOtherFeatures = newIndex - dividerIndex - 1;
        _otherFeatures.insert(indexInOtherFeatures, oldFeature);
      } else {
        _otherFeatures.add(oldFeature);
      }
    });
  }

  void _addFeature(int index, {int? newIndex}) {
    final int dividerIndex = _features.length;
    final int indexInOtherFeatures = index - dividerIndex - 1;

    setState(() {
      final Feature newFeature = _otherFeatures[indexInOtherFeatures];
      final Feature? mutuallyExclusiveFeature =
          _features.firstWhereOrNull((Feature feature) => feature.isMutuallyExclusive(newFeature));
      if (mutuallyExclusiveFeature != null) {
        final String description = mutuallyExclusiveFeature.getDescription(context);
        return showSnackBar(
          context,
          S.of(context).pageProfileEditProfileFeaturesMutuallyExclusive(description),
          durationType: SnackBarDurationType.medium,
          replace: true,
          key: Key('$newFeature mutuallyExclusiveSnackBar'),
        );
      }

      _otherFeatures.removeAt(indexInOtherFeatures);

      if (newIndex != null) {
        _features.insert(newIndex, newFeature);
      } else {
        _features.add(newFeature);
      }
    });
  }

  Future<void> onPressed() async {
    setState(() => _isSaving = true);

    final List<Feature> previousFeatures = _profileFeatures.map((ProfileFeature e) => e.feature).toList();

    for (int index = 0; index < _features.length; index++) {
      final Feature feature = _features[index];

      if (!previousFeatures.contains(feature)) {
        await supabaseManager.supabaseClient.from('profile_features').insert(<String, dynamic>{
          'profile_id': widget.profile.id,
          'feature': feature.index,
          'rank': index,
        });
      } else {
        await supabaseManager.supabaseClient
            .from('profile_features')
            .update(<String, dynamic>{'rank': index})
            .eq('profile_id', widget.profile.id)
            .eq('feature', feature.index);
      }
    }
    final List<Feature> removedFeatures = previousFeatures.where((Feature e) => !_features.contains(e)).toList();
    for (final Feature feature in removedFeatures) {
      await supabaseManager.supabaseClient
          .from('profile_features')
          .delete()
          .eq('profile_id', widget.profile.id)
          .eq('feature', feature.index);
    }

    setState(() => _isSaving = false);

    if (mounted) Navigator.of(context).pop();
  }
}
