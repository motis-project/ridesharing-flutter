import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
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

  get isRecent => DateTime.now().difference(createdAt!).inDays < 3;

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
    return "TODO";

    // switch (this) {
    //   case ReportCategory.didNotShowUp:
    //     return AppLocalizations.of(context)!.didNotShowUp;
    //   case ReportCategory.didNotPay:
    //     return AppLocalizations.of(context)!.didNotPay;
    //   case ReportCategory.didNotFollowRules:
    //     return AppLocalizations.of(context)!.didNotFollowRules;
    //   case ReportCategory.wasAggressive:
    //     return AppLocalizations.of(context)!.wasAggressive;
    //   case ReportCategory.usedBadLanguage:
    //     return AppLocalizations.of(context)!.usedBadLanguage;
    //   case ReportCategory.other:
    //     return AppLocalizations.of(context)!.other;
    // }
  }
}
