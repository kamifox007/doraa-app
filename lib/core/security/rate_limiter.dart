class RateLimiter {
  final Map<String, DateTime> _lastRequest = {};

  bool canProceed(String action, {Duration cooldown = const Duration(seconds: 3)}) {
    final last = _lastRequest[action];
    if (last == null || DateTime.now().difference(last) > cooldown) {
      _lastRequest[action] = DateTime.now();
      return true;
    }
    return false;
  }
}

// Global instance
final rateLimiter = RateLimiter();
