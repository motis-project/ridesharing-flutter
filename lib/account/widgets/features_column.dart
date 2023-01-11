import 'package:flutter/material.dart';

import '../models/profile_feature.dart';

class FeaturesColumn extends StatelessWidget {
  final List<ProfileFeature> features;

  const FeaturesColumn(this.features, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: ((context, index) {
        Feature feature = features[index].feature;
        return ListTile(
          leading: feature.getIcon(context),
          title: Text(feature.getDescription(context)),
        );
      }),
      itemCount: features.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}
