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
    int? writerId,
    NullableParameter<Profile>? writer,
    int? receiverId,
    NullableParameter<Profile>? receiver,
    bool createDependencies = true,
  }) {
    assert(writerId == null || writer?.value == null || writer!.value?.id == writerId);
    assert(receiverId == null || receiver?.value == null || receiver!.value?.id == receiverId);

    final Profile? generatedWriter =
        getNullableParameterOr(writer, ProfileFactory().generateFake(id: writerId, createDependencies: false));
    final Profile? generatedReceiver =
        getNullableParameterOr(receiver, ProfileFactory().generateFake(id: receiverId, createDependencies: false));

    return Review(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      rating: rating ?? random.nextInt(Review.maxRating),
      comfortRating: getNullableParameterOr(comfortRating, random.nextInt(Review.maxRating)),
      safetyRating: getNullableParameterOr(safetyRating, random.nextInt(Review.maxRating)),
      reliabilityRating: getNullableParameterOr(reliabilityRating, random.nextInt(Review.maxRating)),
      hospitalityRating: getNullableParameterOr(hospitalityRating, random.nextInt(Review.maxRating)),
      text: getNullableParameterOr(text, faker.lorem.sentences(random.nextInt(2) + 1).join(' ')),
      writerId: generatedWriter?.id ?? randomId,
      writer: generatedWriter,
      receiverId: generatedReceiver?.id ?? randomId,
      receiver: generatedReceiver,
    );
  }
}
