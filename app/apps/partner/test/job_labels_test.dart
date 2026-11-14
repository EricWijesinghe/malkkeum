import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/job_labels.dart';
import 'package:test_support/test_support.dart';

void main() {
  group('jobCountsLabel', () {
    test('lists each non-zero option in catalogue order', () {
      final job = {
        'service_code': 'aircon',
        'unit_counts': [1, 0, 2, 0],
      };
      expect(jobCountsLabel(koT, job), '벽걸이 1 · 2in1 2');
    });

    test('returns null when the job has no counts or the service has none', () {
      expect(
        jobCountsLabel(koT, {'service_code': 'aircon', 'unit_counts': null}),
        isNull,
      );
      expect(
        jobCountsLabel(koT, {'service_code': 'aircon', 'unit_counts': <int>[]}),
        isNull,
      );
      expect(
        jobCountsLabel(koT, {
          'service_code': 'aircon',
          'unit_counts': [0, 0, 0, 0],
        }),
        isNull,
      );
      expect(
        jobCountsLabel(koT, {
          'service_code': 'studio',
          'unit_counts': [1],
        }),
        isNull,
      );
    });

    test('ignores counts beyond the known options', () {
      final job = {
        'service_code': 'mattress',
        'unit_counts': [2, 5],
      };
      expect(jobCountsLabel(koT, job), '매트리스 2');
    });
  });

  group('homeTypeLabel', () {
    test('maps each home type to its Korean label', () {
      expect(homeTypeLabel(koT, {'home_type': 'one_two_room'}), '원룸·투룸');
      expect(homeTypeLabel(koT, {'home_type': 'apartment'}), '아파트');
      expect(homeTypeLabel(koT, {'home_type': 'villa_house'}), '빌라·주택');
    });

    test('is null for older quotes without a home type', () {
      expect(homeTypeLabel(koT, {'building': 'apartment'}), isNull);
      expect(homeTypeLabel(koT, null), isNull);
    });
  });
}
