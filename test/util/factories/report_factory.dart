import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/report.dart';

import 'model_factory.dart';
import 'profile_factory.dart';

class ReportFactory extends ModelFactory<Report> {
  @override
  Report generateFake({
    int? id,
    DateTime? createdAt,
    ReportCategory? category,
    NullableParameter<String>? text,
    int? reporterId,
    NullableParameter<Profile>? reporter,
    int? offenderId,
    NullableParameter<Profile>? offender,
    bool createDependencies = true,
  }) {
    assert(reporterId == null || reporter?.value == null || reporter!.value?.id == reporterId);
    assert(offenderId == null || offender?.value == null || offender!.value?.id == offenderId);

    Profile? generatedReporter =
        reporter == null ? ProfileFactory().generateFake(id: reporterId, createDependencies: false) : reporter.value;
    Profile? generatedOffender =
        offender == null ? ProfileFactory().generateFake(id: offenderId, createDependencies: false) : offender.value;

    return Report(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      category: category ?? ReportCategory.values[random.nextInt(ReportCategory.values.length)],
      text: getNullableParameterOr(text, faker.lorem.sentences(random.nextInt(2) + 1).join(' ')),
      offenderId: generatedReporter?.id ?? randomId,
      offender: generatedReporter,
      reporterId: generatedOffender?.id ?? randomId,
      reporter: generatedOffender,
    );
  }
}
