import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/reviews/models/report.dart';

import 'model_factory.dart';
import 'profile_factory.dart';

class ReportFactory extends ModelFactory<Report> {
  @override
  Report generateFake({
    int? id,
    DateTime? createdAt,
    ReportReason? reason,
    NullableParameter<String>? text,
    int? reporterId,
    NullableParameter<Profile>? reporter,
    int? offenderId,
    NullableParameter<Profile>? offender,
    bool createDependencies = true,
  }) {
    assert(reporterId == null || reporter?.value == null || reporter!.value?.id == reporterId);
    assert(offenderId == null || offender?.value == null || offender!.value?.id == offenderId);

    final Profile? generatedReporter =
        getNullableParameterOr(reporter, ProfileFactory().generateFake(id: reporterId, createDependencies: false));
    final Profile? generatedOffender =
        getNullableParameterOr(offender, ProfileFactory().generateFake(id: offenderId, createDependencies: false));

    return Report(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      reason: reason ?? ReportReason.values[random.nextInt(ReportReason.values.length)],
      text: getNullableParameterOr(text, faker.lorem.sentences(random.nextInt(2) + 1).join(' ')),
      offenderId: generatedOffender?.id ?? offenderId ?? randomId,
      offender: generatedOffender,
      reporterId: generatedReporter?.id ?? reporterId ?? randomId,
      reporter: generatedReporter,
    );
  }
}
