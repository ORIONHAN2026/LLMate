import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/features/chat/services/quota_utils.dart';

void main() {
  group('QuotaUtils', () {
    final now = DateTime(2026, 8, 19, 15, 30, 45);

    test('returns start of day for daily reset', () {
      expect(QuotaUtils.periodStartFor('daily', now), DateTime(2026, 8, 19));
    });

    test('returns start of month for monthly reset', () {
      expect(QuotaUtils.periodStartFor('monthly', now), DateTime(2026, 8, 1));
    });

    test('returns current time when reset period is not configured', () {
      expect(QuotaUtils.periodStartFor(null, now), now);
    });

    test('clamps usage progress', () {
      expect(QuotaUtils.usageProgress(used: 50, limit: 100), 0.5);
      expect(QuotaUtils.usageProgress(used: 150, limit: 100), 1.0);
      expect(QuotaUtils.usageProgress(used: 50, limit: 0), 0.0);
    });
  });
}
