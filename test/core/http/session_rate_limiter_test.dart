import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/core/http/session_rate_limiter.dart';

void main() {
  final limiter = SessionRateLimiter.instance;

  setUp(limiter.clear);

  test('allows requests when rate limiting is disabled', () {
    for (var i = 0; i < 10; i++) {
      expect(
        limiter.checkAndRecord(sessionId: 'a', requestsPerMinute: null).allowed,
        isTrue,
      );
    }
  });

  test('rejects requests beyond the per-minute limit', () {
    final now = DateTime(2026, 1, 1, 12);
    expect(
      limiter
          .checkAndRecord(sessionId: 'a', requestsPerMinute: 2, now: now)
          .allowed,
      isTrue,
    );
    expect(
      limiter
          .checkAndRecord(
            sessionId: 'a',
            requestsPerMinute: 2,
            now: now.add(const Duration(seconds: 1)),
          )
          .allowed,
      isTrue,
    );
    final rejected = limiter.checkAndRecord(
      sessionId: 'a',
      requestsPerMinute: 2,
      now: now.add(const Duration(seconds: 2)),
    );
    expect(rejected.allowed, isFalse);
    expect(rejected.retryAfter, const Duration(seconds: 58));
  });

  test('uses independent windows for different sessions', () {
    final now = DateTime(2026, 1, 1, 12);
    limiter.checkAndRecord(sessionId: 'a', requestsPerMinute: 1, now: now);
    expect(
      limiter
          .checkAndRecord(sessionId: 'b', requestsPerMinute: 1, now: now)
          .allowed,
      isTrue,
    );
  });

  test('allows requests after the sliding window expires', () {
    final now = DateTime(2026, 1, 1, 12);
    limiter.checkAndRecord(sessionId: 'a', requestsPerMinute: 1, now: now);
    expect(
      limiter
          .checkAndRecord(
            sessionId: 'a',
            requestsPerMinute: 1,
            now: now.add(const Duration(minutes: 1)),
          )
          .allowed,
      isTrue,
    );
  });
}
