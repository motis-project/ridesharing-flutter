import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';

import 'model_factory.dart';
import 'profile_factory.dart';

class ProfileFeatureFactory extends ModelFactory<ProfileFeature> {
  @override
  ProfileFeature generateFake({
    int? id,
    DateTime? createdAt,
    Feature? feature,
    int? rank,
    int? profileId,
    NullableParameter<Profile>? profile,
    bool createDependencies = true,
  }) {
    assert(profileId == null || profile?.value == null || profile!.value?.id == profileId);

    final Profile? generatedProfile =
        profile == null ? ProfileFactory().generateFake(id: profileId, createDependencies: false) : profile.value;

    return ProfileFeature(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      feature: feature ?? Feature.values[random.nextInt(Feature.values.length)],
      rank: rank ?? random.nextInt(5),
      profileId: generatedProfile?.id ?? randomId,
      profile: generatedProfile,
    );
  }
}
