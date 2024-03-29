import 'package:flutter/material.dart';

import '../models/profile_feature.dart';

class FeaturesColumn extends StatelessWidget {
  final List<ProfileFeature> features;

  const FeaturesColumn(this.features, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        final Feature feature = features[index].feature;
        return ListTile(
          leading: feature.getIcon(context),
          title: Text(feature.getDescription(context)),
          key: Key('feature_${feature.name}'),
        );
      },
      itemCount: features.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}
