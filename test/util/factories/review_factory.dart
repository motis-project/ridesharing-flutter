import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';

import 'model_factory.dart';
import 'profile_factory.dart';

class ReviewFactory extends ModelFactory<Review> {
  @override
  Review generateFake({
    int? id,
    DateTime? createdAt,
    int? rating,
    NullableParameter<int>? comfortRating,
    NullableParameter<int>? safetyRating,
    NullableParameter<int>? reliabilityRating,
    NullableParameter<int>? hospitalityRating,
    NullableParameter<String>? text,
    int? offenderId,
    NullableParameter<Profile>? offender,
    int? receiverId,
    NullableParameter<Profile>? receiver,
    bool createDependencies = true,
  }) {
    assert(offenderId == null || offender?.value == null || offender!.value?.id == offenderId);
    assert(receiverId == null || receiver?.value == null || receiver!.value?.id == receiverId);

    Profile? generatedWriter =
        offender == null ? ProfileFactory().generateFake(id: offenderId, createDependencies: false) : offender.value;
    Profile? generatedReceiver =
        receiver == null ? ProfileFactory().generateFake(id: receiverId, createDependencies: false) : receiver.value;

    return Review(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      rating: rating ?? random.nextInt(Review.maxRating),
      comfortRating: getNullableParameterOr(comfortRating, random.nextInt(Review.maxRating)),
      safetyRating: getNullableParameterOr(safetyRating, random.nextInt(Review.maxRating)),
      reliabilityRating: getNullableParameterOr(reliabilityRating, random.nextInt(Review.maxRating)),
      hospitalityRating: getNullableParameterOr(comfortRating, random.nextInt(Review.maxRating)),
      text: getNullableParameterOr(text, faker.lorem.sentences(random.nextInt(2) + 1).join(" ")),
      writerId: generatedWriter?.id ?? randomId,
      writer: generatedWriter,
      receiverId: generatedReceiver?.id ?? randomId,
      receiver: generatedReceiver,
    );
  }
}
