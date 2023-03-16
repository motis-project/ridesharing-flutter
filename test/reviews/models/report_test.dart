import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/reviews/models/report.dart';

import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/report_factory.dart';

void main() {
  group('Report.isRecent', () {
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
  });
  group('Report.fromJson', () {
    test('parses a report from json', () async {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-05-01T00:00:00.000',
        'reporter_id': 2,
        'offender_id': 3,
        'reason': ReportReason.didNotPay.index,
      };
      final report = Report.fromJson(json);
      expect(report.id, 1);
      expect(report.reporterId, 2);
      expect(report.offenderId, 3);
      expect(report.reason, ReportReason.didNotPay);
      expect(report.createdAt, DateTime.parse('2021-05-01T00:00:00.000'));
    });

    test('parses a report from json with optional field text', () async {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-05-01T00:00:00.000',
        'reporter_id': 2,
        'offender_id': 3,
        'reason': ReportReason.didNotFollowRules.index,
        'text': 'text',
      };
      final report = Report.fromJson(json);
      expect(report.id, 1);
      expect(report.reporterId, 2);
      expect(report.offenderId, 3);
      expect(report.reason, ReportReason.didNotFollowRules);
      expect(report.text, 'text');
      expect(report.createdAt, DateTime.parse('2021-05-01T00:00:00.000'));
    });

    test('throws error if reason is not in enum', () async {
      final Map<String, dynamic> json1 = {
        'id': 1,
        'created_at': '2021-05-01T00:00:00.000',
        'reporter_id': 2,
        'offender_id': 3,
        'reason': 100,
      };
      final Map<String, dynamic> json2 = {
        'id': 1,
        'created_at': '2021-05-01T00:00:00.000',
        'reporter_id': 2,
        'offender_id': 3,
        'reason': -1,
      };
      expect(() => Report.fromJson(json1), throwsA(isA<RangeError>()));
      expect(() => Report.fromJson(json2), throwsA(isA<RangeError>()));
    });

    test('can handle Profiles', () {
      final Profile reporter = ProfileFactory().generateFake();
      final Profile offender = ProfileFactory().generateFake();

      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-05-01T00:00:00.000',
        'reporter_id': 2,
        'offender_id': 3,
        'reason': ReportReason.didNotFollowRules.index,
        'text': 'text',
        'reporter': reporter.toJsonForApi(),
        'offender': offender.toJsonForApi(),
      };
      final report = Report.fromJson(json);
      expect(report.reporter!.toString(), reporter.toString());
      expect(report.offender!.toString(), offender.toString());
    });
  });

  group('Report.fromJsonList', () {
    test('parses a list of reports from json', () async {
      final List<Map<String, dynamic>> jsonList = [
        {
          'id': 1,
          'created_at': '2021-05-01T00:00:00.000',
          'reporter_id': 2,
          'offender_id': 3,
          'reason': ReportReason.didNotPay.index,
        },
        {
          'id': 2,
          'created_at': '2021-05-01T00:00:00.000',
          'reporter_id': 2,
          'offender_id': 3,
          'reason': ReportReason.didNotFollowRules.index,
          'text': 'text',
        },
      ];
      final reports = Report.fromJsonList(jsonList);
      expect(reports.length, 2);
      expect(reports[0].id, 1);
      expect(reports[0].reporterId, 2);
      expect(reports[0].offenderId, 3);
      expect(reports[0].reason, ReportReason.didNotPay);
      expect(reports[0].createdAt, DateTime.parse('2021-05-01T00:00:00.000'));
      expect(reports[1].id, 2);
      expect(reports[1].reporterId, 2);
      expect(reports[1].offenderId, 3);
      expect(reports[1].reason, ReportReason.didNotFollowRules);
      expect(reports[1].text, 'text');
      expect(reports[1].createdAt, DateTime.parse('2021-05-01T00:00:00.000'));
    });
  });

  group('Report.toJson', () {
    test('returns a json representation of the Report', () async {
      final Report report = ReportFactory().generateFake();
      final Map<String, dynamic> json = report.toJson();
      expect(json['reporter_id'], report.reporterId);
      expect(json['offender_id'], report.offenderId);
      expect(json['reason'], report.reason.index);
      expect(json['text'], report.text);
      expect(json.keys.length, 4);
    });

    test('returns a json representation of the Report without text', () async {
      final Report report = ReportFactory().generateFake(
        text: NullableParameter(null),
      );
      final Map<String, dynamic> json = report.toJson();
      expect(json['reporter_id'], report.reporterId);
      expect(json['offender_id'], report.offenderId);
      expect(json['reason'], report.reason.index);
      expect(json['text'], null);
      expect(json.keys.length, 4);
    });
  });
}
