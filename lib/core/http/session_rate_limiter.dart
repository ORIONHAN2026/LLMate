/// 会话级滑动窗口限速器。
///
/// 每个会话只保留最近一分钟内已放行请求的时间戳；配置为空或小于 1 时不限速。
class SessionRateLimiter {
  SessionRateLimiter._();

  static final SessionRateLimiter instance = SessionRateLimiter._();

  final Map<String, List<DateTime>> _acceptedRequests = {};

  RateLimitResult checkAndRecord({
    required String sessionId,
    required int? requestsPerMinute,
    DateTime? now,
  }) {
    if (requestsPerMinute == null || requestsPerMinute < 1) {
      _acceptedRequests.remove(sessionId);
      return const RateLimitResult(allowed: true);
    }

    final current = now ?? DateTime.now();
    final windowStart = current.subtract(const Duration(minutes: 1));
    final timestamps = _acceptedRequests.putIfAbsent(sessionId, () => []);
    timestamps.removeWhere((timestamp) => !timestamp.isAfter(windowStart));

    if (timestamps.length >= requestsPerMinute) {
      final retryAfter = timestamps.first
          .add(const Duration(minutes: 1))
          .difference(current);
      return RateLimitResult(
        allowed: false,
        retryAfter: retryAfter.isNegative ? Duration.zero : retryAfter,
        limit: requestsPerMinute,
      );
    }

    timestamps.add(current);
    return RateLimitResult(allowed: true, limit: requestsPerMinute);
  }

  void clear([String? sessionId]) {
    if (sessionId == null) {
      _acceptedRequests.clear();
    } else {
      _acceptedRequests.remove(sessionId);
    }
  }
}

class RateLimitResult {
  final bool allowed;
  final Duration? retryAfter;
  final int? limit;

  const RateLimitResult({required this.allowed, this.retryAfter, this.limit});
}
