import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/report.dart';

import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/report_factory.dart';

void main() {
  group('Report.isRecent', (() {
    test('returns true if report is less than 3 days old', () async {
      final report = ReportFactory().generateFake(
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(report.isRecent, true);
    });

    test('returns false if report is more than 3 days old', () async {
      final report = ReportFactory().generateFake(
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      );
      expect(report.isRecent, false);
    });

    test('returns false if report is exactly 3 days old', () async {
      final report = ReportFactory().generateFake(
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(report.isRecent, false);
    });
  }));
  group('Report.fromJson', (() {
    test('parses a report from json', () async {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-05-01T00:00:00.000Z",
        "reporter_id": 2,
        "offender_id": 3,
        "category": ReportCategory.didNotPay.index,
      };
      final report = Report.fromJson(json);
      expect(report.id, 1);
      expect(report.reporterId, 2);
      expect(report.offenderId, 3);
      expect(report.category, ReportCategory.didNotPay);
      expect(report.createdAt, DateTime.parse('2021-05-01T00:00:00.000Z'));
    });

    test('parses a report from json with optional field text', () async {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-05-01T00:00:00.000Z",
        "reporter_id": 2,
        "offender_id": 3,
        "category": ReportCategory.didNotFollowRules.index,
        "text": "text",
      };
      final report = Report.fromJson(json);
      expect(report.id, 1);
      expect(report.reporterId, 2);
      expect(report.offenderId, 3);
      expect(report.category, ReportCategory.didNotFollowRules);
      expect(report.text, 'text');
      expect(report.createdAt, DateTime.parse('2021-05-01T00:00:00.000Z'));
    });

    test('throws error if category is not in enum', () async {
      Map<String, dynamic> json1 = {
        "id": 1,
        "created_at": "2021-05-01T00:00:00.000Z",
        "reporter_id": 2,
        "offender_id": 3,
        "category": 100,
      };
      Map<String, dynamic> json2 = {
        "id": 1,
        "created_at": "2021-05-01T00:00:00.000Z",
        "reporter_id": 2,
        "offender_id": 3,
        "category": -1,
      };
      expect(() => Report.fromJson(json1), throwsA(isA<RangeError>()));
      expect(() => Report.fromJson(json2), throwsA(isA<RangeError>()));
    });

    test('can handle Profiles', (() {
      Profile reporter = ProfileFactory().generateFake();
      Profile offender = ProfileFactory().generateFake();

      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-05-01T00:00:00.000Z",
        "reporter_id": 2,
        "offender_id": 3,
        "category": ReportCategory.didNotFollowRules.index,
        "text": "text",
        "reporter": reporter.toJsonForApi(),
        "offender": offender.toJsonForApi(),
      };
      final report = Report.fromJson(json);
      expect(report.reporter!.toString(), reporter.toString());
      expect(report.offender!.toString(), offender.toString());
    }));
  }));

  group('Report.fromJsonList', (() {
    test('parses a list of reports from json', () async {
      List<Map<String, dynamic>> jsonList = [
        {
          "id": 1,
          "created_at": "2021-05-01T00:00:00.000Z",
          "reporter_id": 2,
          "offender_id": 3,
          "category": ReportCategory.didNotPay.index,
        },
        {
          "id": 2,
          "created_at": "2021-05-01T00:00:00.000Z",
          "reporter_id": 2,
          "offender_id": 3,
          "category": ReportCategory.didNotFollowRules.index,
          "text": "text",
        },
      ];
      final reports = Report.fromJsonList(jsonList);
      expect(reports.length, 2);
      expect(reports[0].id, 1);
      expect(reports[0].reporterId, 2);
      expect(reports[0].offenderId, 3);
      expect(reports[0].category, ReportCategory.didNotPay);
      expect(reports[0].createdAt, DateTime.parse('2021-05-01T00:00:00.000Z'));
      expect(reports[1].id, 2);
      expect(reports[1].reporterId, 2);
      expect(reports[1].offenderId, 3);
      expect(reports[1].category, ReportCategory.didNotFollowRules);
      expect(reports[1].text, 'text');
      expect(reports[1].createdAt, DateTime.parse('2021-05-01T00:00:00.000Z'));
    });
  }));

  group('Report.toJson', () {
    test('returns a json representation of the Report', (() async {
      Report report = ReportFactory().generateFake();
      Map<String, dynamic> json = report.toJson();
      expect(json['reporter_id'], report.reporterId);
      expect(json['offender_id'], report.offenderId);
      expect(json['category'], report.category.index);
      expect(json['text'], report.text);
      expect(json.keys.length, 4);
    }));

    test('returns a json representation of the Report without text', (() async {
      Report report = ReportFactory().generateFake(
        text: NullableParameter(null),
      );
      Map<String, dynamic> json = report.toJson();
      expect(json['reporter_id'], report.reporterId);
      expect(json['offender_id'], report.offenderId);
      expect(json['category'], report.category.index);
      expect(json['text'], null);
      expect(json.keys.length, 4);
    }));
  });
}
