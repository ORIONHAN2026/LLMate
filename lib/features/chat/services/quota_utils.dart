class QuotaUtils {
  QuotaUtils._();

  static DateTime periodStartFor(String? resetPeriod, DateTime now) {
    switch (resetPeriod) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      default:
        return now;
    }
  }

  static double usageProgress({required num used, required num limit}) {
    if (limit <= 0) return 0.0;
    return (used.toDouble() / limit.toDouble()).clamp(0.0, 1.0);
  }
}
