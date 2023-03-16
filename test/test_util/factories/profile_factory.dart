import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/reviews/models/report.dart';
import 'package:motis_mitfahr_app/reviews/models/review.dart';

import 'model_factory.dart';
import 'profile_feature_factory.dart';
import 'report_factory.dart';
import 'review_factory.dart';

class ProfileFactory extends ModelFactory<Profile> {
  @override
  Profile generateFake({
    int? id,
    DateTime? createdAt,
    String? username,
    String? email,
    NullableParameter<String>? description,
    NullableParameter<DateTime>? birthDate,
    NullableParameter<String>? firstName,
    NullableParameter<String>? lastName,
    NullableParameter<Gender>? gender,
    NullableParameter<String>? avatarUrl,
    List<Review>? reviewsReceived,
    List<ProfileFeature>? profileFeatures,
    List<Report>? reportsReceived,
    bool createDependencies = true,
  }) {
    return Profile(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      username: username ?? faker.internet.userName(),
      email: email ?? faker.internet.email(),
      description: getNullableParameterOr(description, faker.lorem.sentences(random.nextInt(2) + 1).join(' ')),
      birthDate: getNullableParameterOr(
          birthDate,
          faker.date.dateTimeBetween(
            DateTime.now().subtract(Profile.maxAge),
            DateTime.now().subtract(Profile.minAge),
          )),
      firstName: getNullableParameterOr(firstName, faker.person.firstName()),
      lastName: getNullableParameterOr(lastName, faker.person.lastName()),
      gender: getNullableParameterOr(gender, Gender.values[random.nextInt(Gender.values.length)]),
      avatarUrl: getNullableParameterOr(avatarUrl, null),
      reviewsReceived:
          reviewsReceived ?? (createDependencies ? ReviewFactory().generateFakeList(createDependencies: false) : []),
      profileFeatures: profileFeatures ??
          (createDependencies ? ProfileFeatureFactory().generateFakeList(createDependencies: false) : []),
      reportsReceived:
          reportsReceived ?? (createDependencies ? ReportFactory().generateFakeList(createDependencies: false) : []),
    );
  }
}
