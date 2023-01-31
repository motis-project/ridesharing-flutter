import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/model.dart';
import '../../util/own_theme_fields.dart';
import 'profile.dart';

class ProfileFeature extends Model {
  int profileId;
  Profile? profile;

  Feature feature;
  int rank;

  ProfileFeature({
    super.id,
    super.createdAt,
    required this.profileId,
    this.profile,
    required this.feature,
    required this.rank,
  });

  @override
  factory ProfileFeature.fromJson(Map<String, dynamic> json) {
    return ProfileFeature(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      profileId: json['profile_id'] as int,
      profile: json['profile'] != null ? Profile.fromJson(json['profile'] as Map<String, dynamic>) : null,
      feature: Feature.values.elementAt(json['feature'] as int),
      rank: json['rank'] as int,
    );
  }

  static List<ProfileFeature> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => ProfileFeature.fromJson(json)).toList()
      ..sort((ProfileFeature a, ProfileFeature b) => a.rank - b.rank);
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'profile_id': profileId,
      'feature': feature.index,
      'rank': rank,
    };
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        'profile': profile?.toJsonForApi(),
      });
  }
}

// Stored in the database as an integer
// The order of the enum values is important
enum Feature {
  noSmoking,
  smoking,
  noVaping,
  vaping,
  noPetsAllowed,
  petsAllowed,
  noChildrenAllowed,
  childrenAllowed,
  talkative,
  music,
  quiet,
  speedyDrivingStyle,
  relaxedDrivingStyle,
  accessible,
  requires3G,
}

extension FeatureExtension on Feature {
  Icon getIcon(BuildContext context) {
    switch (this) {
      case Feature.noSmoking:
        return Icon(Icons.smoke_free, color: Theme.of(context).colorScheme.error);
      case Feature.smoking:
        return Icon(Icons.smoking_rooms, color: Theme.of(context).own().success);
      case Feature.noVaping:
        return Icon(Icons.vape_free, color: Theme.of(context).colorScheme.error);
      case Feature.vaping:
        return Icon(Icons.vaping_rooms, color: Theme.of(context).own().success);
      case Feature.noPetsAllowed:
        return Icon(Icons.pets, color: Theme.of(context).colorScheme.error);
      case Feature.petsAllowed:
        return Icon(Icons.pets, color: Theme.of(context).own().success);
      case Feature.noChildrenAllowed:
        return Icon(Icons.child_care, color: Theme.of(context).colorScheme.error);
      case Feature.childrenAllowed:
        return Icon(Icons.child_care, color: Theme.of(context).own().success);
      case Feature.talkative:
        return Icon(Icons.forum, color: Theme.of(context).colorScheme.primary);
      case Feature.music:
        return Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary);
      case Feature.quiet:
        return Icon(Icons.volume_off, color: Theme.of(context).colorScheme.primary);
      case Feature.speedyDrivingStyle:
        return Icon(Icons.speed, color: Theme.of(context).colorScheme.primary);
      case Feature.relaxedDrivingStyle:
        return Icon(Icons.self_improvement, color: Theme.of(context).colorScheme.primary);
      case Feature.accessible:
        return Icon(Icons.accessibility, color: Theme.of(context).colorScheme.primary);
      case Feature.requires3G:
        return Icon(Icons.vaccines, color: Theme.of(context).colorScheme.primary);
    }
  }

  String getDescription(BuildContext context) {
    switch (this) {
      case Feature.noSmoking:
        return S.of(context).modelProfileFeatureNoSmoking;
      case Feature.smoking:
        return S.of(context).modelProfileFeatureSmoking;
      case Feature.noVaping:
        return S.of(context).modelProfileFeatureNoVaping;
      case Feature.vaping:
        return S.of(context).modelProfileFeatureVaping;
      case Feature.noPetsAllowed:
        return S.of(context).modelProfileFeatureNoPetsAllowed;
      case Feature.petsAllowed:
        return S.of(context).modelProfileFeaturePetsAllowed;
      case Feature.noChildrenAllowed:
        return S.of(context).modelProfileFeatureNoChildrenAllowed;
      case Feature.childrenAllowed:
        return S.of(context).modelProfileFeatureChildrenAllowed;
      case Feature.talkative:
        return S.of(context).modelProfileFeatureTalkative;
      case Feature.music:
        return S.of(context).modelProfileFeatureMusic;
      case Feature.quiet:
        return S.of(context).modelProfileFeatureQuiet;
      case Feature.speedyDrivingStyle:
        return S.of(context).modelProfileFeatureSpeedyDrivingStyle;
      case Feature.relaxedDrivingStyle:
        return S.of(context).modelProfileFeatureRelaxedDrivingStyle;
      case Feature.accessible:
        return S.of(context).modelProfileFeatureAccessible;
      case Feature.requires3G:
        return S.of(context).modelProfileFeatureRequires3G;
    }
  }

  bool isMutuallyExclusive(Feature other) {
    switch (this) {
      case Feature.noSmoking:
        return other == Feature.smoking;
      case Feature.smoking:
        return other == Feature.noSmoking;
      case Feature.noVaping:
        return other == Feature.vaping;
      case Feature.vaping:
        return other == Feature.noVaping;
      case Feature.noPetsAllowed:
        return other == Feature.petsAllowed;
      case Feature.petsAllowed:
        return other == Feature.noPetsAllowed;
      case Feature.noChildrenAllowed:
        return other == Feature.childrenAllowed;
      case Feature.childrenAllowed:
        return other == Feature.noChildrenAllowed;
      case Feature.relaxedDrivingStyle:
        return other == Feature.speedyDrivingStyle;
      case Feature.speedyDrivingStyle:
        return other == Feature.relaxedDrivingStyle;
      default:
        return false;
    }
  }
}
