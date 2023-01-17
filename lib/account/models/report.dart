import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/model.dart';

class Report extends Model {
  int offenderId;
  Profile? offender;

  int reporterId;
  Profile? reporter;

  ReportCategory category;
  String? text;

  Report({
    super.id,
    super.createdAt,
    required this.offenderId,
    this.offender,
    required this.reporterId,
    this.reporter,
    required this.category,
    this.text,
  });

  bool get isRecent => DateTime.now().difference(createdAt!).inDays < 3;

  @override
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      offenderId: json['offender_id'],
      offender: json['offender'] != null ? Profile.fromJson(json['offender']) : null,
      reporterId: json['reporter_id'],
      reporter: json['reporter'] != null ? Profile.fromJson(json['reporter']) : null,
      category: ReportCategory.values.elementAt(json['category'] as int),
      text: json['text'],
    );
  }

  static List<Report> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => Report.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'offender_id': offenderId,
      'reporter_id': reporterId,
      'category': category.index,
      'text': text,
    };
  }
}

// Stored in the database as an integer
// The order of the enum values is important
enum ReportCategory {
  didNotShowUp,
  didNotPay,
  didNotFollowRules,
  wasAggressive,
  usedBadLanguage,
  other,
}

extension ReportCategoryExtension on ReportCategory {
  Icon getIcon(BuildContext context) {
    switch (this) {
      case ReportCategory.didNotShowUp:
        return Icon(Icons.hourglass_disabled, color: Theme.of(context).colorScheme.error);
      case ReportCategory.didNotPay:
        return Icon(Icons.money_off, color: Theme.of(context).colorScheme.error);
      case ReportCategory.didNotFollowRules:
        return Icon(Icons.warning, color: Theme.of(context).colorScheme.error);
      case ReportCategory.wasAggressive:
        return Icon(Icons.sentiment_dissatisfied, color: Theme.of(context).colorScheme.error);
      case ReportCategory.usedBadLanguage:
        return Icon(Icons.explicit, color: Theme.of(context).colorScheme.error);
      case ReportCategory.other:
        return Icon(Icons.help, color: Theme.of(context).colorScheme.error);
    }
  }

  String getDescription(BuildContext context) {
    switch (this) {
      case ReportCategory.didNotShowUp:
        return S.of(context).modelReportCategoryDidNotShowUp;
      case ReportCategory.didNotPay:
        return S.of(context).modelReportCategoryDidNotPay;
      case ReportCategory.didNotFollowRules:
        return S.of(context).modelReportCategoryDidNotFollowRules;
      case ReportCategory.wasAggressive:
        return S.of(context).modelReportCategoryWasAggressive;
      case ReportCategory.usedBadLanguage:
        return S.of(context).modelReportCategoryUsedBadLanguage;
      case ReportCategory.other:
        return S.of(context).modelReportCategoryOther;
    }
  }
}
