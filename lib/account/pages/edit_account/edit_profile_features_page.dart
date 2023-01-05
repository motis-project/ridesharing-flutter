import 'package:flutter/material.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:collection/collection.dart';

import '../../../util/big_button.dart';
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
    int index = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order your profile features'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            Flexible(
              child: ReorderableListView(
                header: _features.isEmpty
                    ? Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                        ),
                      )
                    : null,
                shrinkWrap: true,
                onReorder: onReorder,
                children: [
                  for (Feature feature in _features)
                    ListTile(
                      key: ValueKey(feature),
                      leading: feature.getIcon(context),
                      title: Text(feature.getDescription(context)),
                      trailing: ReorderableDragStartListener(
                        index: index++,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ),
                  const IgnorePointer(
                    key: ValueKey('divider'),
                    child: Divider(
                      thickness: 5,
                    ),
                  ),
                  for (Feature feature in _otherFeatures)
                    ListTile(
                      textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      key: ValueKey(feature),
                      leading: feature.getIcon(context),
                      title: Text(feature.getDescription(context)),
                      trailing: ReorderableDragStartListener(
                        index: index++,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            BigButton(
              onPressed: () => onPressed(context),
              text: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    int dividerIndex = _features.length;

    setState(() {
      // Adding a new feature
      if (newIndex <= dividerIndex && oldIndex > dividerIndex) {
        int indexInOtherFeatures = oldIndex - dividerIndex - 1;
        Feature newFeature = _otherFeatures[indexInOtherFeatures];
        Feature? mutuallyExclusiveFeature =
            _features.firstWhereOrNull((feature) => feature.isMutuallyExclusive(newFeature));
        if (mutuallyExclusiveFeature != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Mutually exclusive feature already selected: ${mutuallyExclusiveFeature.getDescription(context)}"),
            ),
          );
          return;
        }

        _features.insert(newIndex, _otherFeatures.removeAt(oldIndex - dividerIndex - 1));
        return;
      }

      // Removing a feature
      if (newIndex > dividerIndex && oldIndex < dividerIndex) {
        _otherFeatures.insert(newIndex - dividerIndex - 1, _features.removeAt(oldIndex));
        return;
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

  void onPressed(context) async {
    final previousFeatures = _profileFeatures.map((e) => e.feature).toList();

    for (int index = 0; index < _features.length; index++) {
      final feature = _features[index];

      if (!previousFeatures.contains(feature)) {
        await supabaseClient.from('profile_features').insert({
          'profile_id': widget.profile.id,
          'feature': feature.index,
          'rank': index,
        });
      } else {
        await supabaseClient
            .from('profile_features')
            .update({'rank': index})
            .eq('profile_id', widget.profile.id)
            .eq('feature', feature.index);
      }
    }
    final removedFeatures = previousFeatures.where((e) => !_features.contains(e)).toList();
    for (Feature feature in removedFeatures) {
      await supabaseClient
          .from('profile_features')
          .delete()
          .eq('profile_id', widget.profile.id)
          .eq('feature', feature.index);
    }

    Navigator.of(context).pop();
  }
}
