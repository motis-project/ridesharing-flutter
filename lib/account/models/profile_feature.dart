import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/util/own_theme_fields.dart';

import '../../util/model.dart';

class ProfileFeature extends Model {
  int profileId;
  Profile? profile;

  Feature feature;

  ProfileFeature({
    super.id,
    super.createdAt,
    required this.profileId,
    this.profile,
    required this.feature,
  });

  @override
  factory ProfileFeature.fromJson(Map<String, dynamic> json) {
    return ProfileFeature(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      profileId: json['profile_id'],
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
      feature: Feature.values.elementAt(json['feature'] as int),
    );
  }

  static List<ProfileFeature> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => ProfileFeature.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'feature': feature.index,
    };
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
  luxury,
  speedyDrivingStyle,
  relaxedDrivingStyle,
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
      case Feature.luxury:
        return Icon(Icons.minor_crash, color: Theme.of(context).colorScheme.primary);
      case Feature.speedyDrivingStyle:
        return Icon(Icons.speed, color: Theme.of(context).colorScheme.primary);
      case Feature.relaxedDrivingStyle:
        return Icon(Icons.self_improvement, color: Theme.of(context).colorScheme.primary);
      case Feature.requires3G:
        return Icon(Icons.vaccines, color: Theme.of(context).colorScheme.primary);
    }
  }

  String getDescription(BuildContext context) {
    switch (this) {
      case Feature.noSmoking:
        return 'No smoking';
      case Feature.smoking:
        return 'Smoking';
      case Feature.noVaping:
        return 'No vaping';
      case Feature.vaping:
        return 'Vaping';
      case Feature.noPetsAllowed:
        return 'No pets allowed';
      case Feature.petsAllowed:
        return 'Pets allowed';
      case Feature.noChildrenAllowed:
        return 'No children allowed';
      case Feature.childrenAllowed:
        return 'Children allowed';
      case Feature.talkative:
        return 'Talkative';
      case Feature.music:
        return 'Music';
      case Feature.quiet:
        return 'Quiet';
      case Feature.luxury:
        return 'Luxury';
      case Feature.speedyDrivingStyle:
        return 'Speedy driving style';
      case Feature.relaxedDrivingStyle:
        return 'Relaxed driving style';
      case Feature.requires3G:
        return 'Requires 3G certification';
    }
  }
}
