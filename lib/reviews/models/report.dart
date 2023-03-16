import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/models/profile.dart';
import '../../model.dart';

class Report extends Model {
  int offenderId;
  Profile? offender;

  int reporterId;
  Profile? reporter;

  ReportReason reason;
  String? text;

  Report({
    super.id,
    super.createdAt,
    required this.offenderId,
    this.offender,
    required this.reporterId,
    this.reporter,
    required this.reason,
    this.text,
  });

  /// Returns whether the report has been created in the last 3 days.
  bool get isRecent => DateTime.now().difference(createdAt!).inDays < 3;

  @override
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      offenderId: json['offender_id'] as int,
      offender: json['offender'] != null ? Profile.fromJson(json['offender'] as Map<String, dynamic>) : null,
      reporterId: json['reporter_id'] as int,
      reporter: json['reporter'] != null ? Profile.fromJson(json['reporter'] as Map<String, dynamic>) : null,
      reason: ReportReason.values.elementAt(json['reason'] as int),
      text: json['text'] as String?,
    );
  }

  static List<Report> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Report.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'offender_id': offenderId,
      'reporter_id': reporterId,
      'reason': reason.index,
      'text': text,
    };
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        'offender': offender?.toJsonForApi(),
        'reporter': reporter?.toJsonForApi(),
      });
  }
}

// Stored in the database as an integer
// The order of the enum values is important
enum ReportReason {
  didNotShowUp,
  didNotPay,
  didNotFollowRules,
  wasAggressive,
  usedBadLanguage,
  other,
}

extension ReportReasonExtension on ReportReason {
  Icon getIcon(BuildContext context) {
    switch (this) {
      case ReportReason.didNotShowUp:
        return Icon(Icons.hourglass_disabled, color: Theme.of(context).colorScheme.error);
      case ReportReason.didNotPay:
        return Icon(Icons.money_off, color: Theme.of(context).colorScheme.error);
      case ReportReason.didNotFollowRules:
        return Icon(Icons.warning, color: Theme.of(context).colorScheme.error);
      case ReportReason.wasAggressive:
        return Icon(Icons.sentiment_dissatisfied, color: Theme.of(context).colorScheme.error);
      case ReportReason.usedBadLanguage:
        return Icon(Icons.explicit, color: Theme.of(context).colorScheme.error);
      case ReportReason.other:
        return Icon(Icons.help, color: Theme.of(context).colorScheme.error);
    }
  }

  String getDescription(BuildContext context) {
    switch (this) {
      case ReportReason.didNotShowUp:
        return S.of(context).modelReportReasonDidNotShowUp;
      case ReportReason.didNotPay:
        return S.of(context).modelReportReasonDidNotPay;
      case ReportReason.didNotFollowRules:
        return S.of(context).modelReportReasonDidNotFollowRules;
      case ReportReason.wasAggressive:
        return S.of(context).modelReportReasonWasAggressive;
      case ReportReason.usedBadLanguage:
        return S.of(context).modelReportReasonUsedBadLanguage;
      case ReportReason.other:
        return S.of(context).modelReportReasonOther;
    }
  }
}
