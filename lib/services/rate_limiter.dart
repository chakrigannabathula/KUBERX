import 'dart:async';
import 'dart:collection';

/// Advanced rate limiter for API requests
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Queue<DateTime> _requestHistory = Queue<DateTime>();
  final Map<String, Queue<DateTime>> _endpointHistory = {};

  // Exponential backoff configuration
  static const Duration baseBackoffDelay = Duration(milliseconds: 500);
  static const Duration maxBackoffDelay = Duration(seconds: 30);
  static const int maxRetries = 3;

  RateLimiter({
    required this.maxRequests,
    required this.window,
  });

  /// Check if a request can be made without hitting rate limits
  Future<bool> canMakeRequest({String? endpoint}) async {
    final now = DateTime.now();

    // Clean old requests from global history
    _cleanOldRequests(_requestHistory, now);

    // Clean old requests from endpoint-specific history
    if (endpoint != null) {
      _endpointHistory[endpoint] ??= Queue<DateTime>();
      _cleanOldRequests(_endpointHistory[endpoint]!, now);
    }

    // Check global rate limit
    if (_requestHistory.length >= maxRequests) {
      return false;
    }

    // Check endpoint-specific limits (if applicable)
    if (endpoint != null && _endpointHistory[endpoint]!.length >= maxRequests) {
      return false;
    }

    return true;
  }

  /// Wait until a request can be made
  Future<void> waitForSlot({String? endpoint}) async {
    while (!await canMakeRequest(endpoint: endpoint)) {
      final waitTime = _calculateWaitTime(endpoint);
      print('🚦 Rate limit active, waiting ${waitTime.inMilliseconds}ms...');
      await Future.delayed(waitTime);
    }
  }

  /// Record a successful request
  void recordRequest({String? endpoint}) {
    final now = DateTime.now();
    _requestHistory.add(now);

    if (endpoint != null) {
      _endpointHistory[endpoint] ??= Queue<DateTime>();
      _endpointHistory[endpoint]!.add(now);
    }
  }

  /// Calculate how long to wait before next request
  Duration _calculateWaitTime(String? endpoint) {
    final now = DateTime.now();

    if (_requestHistory.isNotEmpty) {
      final oldestRequest = _requestHistory.first;
      final timeSinceOldest = now.difference(oldestRequest);

      if (timeSinceOldest < window) {
        return window - timeSinceOldest;
      }
    }

    return Duration.zero;
  }

  /// Clean requests older than the window
  void _cleanOldRequests(Queue<DateTime> history, DateTime now) {
    while (history.isNotEmpty && now.difference(history.first) > window) {
      history.removeFirst();
    }
  }

  /// Exponential backoff for retry scenarios
  static Future<void> exponentialBackoff(int attempt) async {
    if (attempt <= 0) return;

    final delay = Duration(
      milliseconds: (baseBackoffDelay.inMilliseconds *
                    (1 << (attempt - 1))).clamp(
        baseBackoffDelay.inMilliseconds,
        maxBackoffDelay.inMilliseconds,
      ),
    );

    print('⏳ Exponential backoff: waiting ${delay.inMilliseconds}ms (attempt $attempt)');
    await Future.delayed(delay);
  }

  /// Execute a function with rate limiting and retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RateLimiter? rateLimiter,
    String? endpoint,
    int maxRetries = maxRetries,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        // Wait for rate limit if provided
        if (rateLimiter != null) {
          await rateLimiter.waitForSlot(endpoint: endpoint);
          rateLimiter.recordRequest(endpoint: endpoint);
        }

        // Execute the operation
        final result = await operation();
        return result;

      } catch (error) {
        attempt++;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // If we've exhausted retries, throw the error
        if (attempt >= maxRetries) {
          print('❌ Max retries ($maxRetries) exceeded for operation');
          rethrow;
        }

        print('🔄 Operation failed (attempt $attempt/$maxRetries): $error');
        await exponentialBackoff(attempt);
      }
    }

    throw Exception('Operation failed after $maxRetries attempts');
  }

  /// Get current request count
  int get currentRequestCount => _requestHistory.length;

  /// Get requests remaining in current window
  int get requestsRemaining => maxRequests - _requestHistory.length;

  /// Check if rate limiter is currently throttling
  bool get isThrottling => _requestHistory.length >= maxRequests;

  /// Reset all rate limiting state
  void reset() {
    _requestHistory.clear();
    _endpointHistory.clear();
  }
}

/// Specialized rate limiter for CoinGecko API
class CoinGeckoRateLimiter extends RateLimiter {
  // CoinGecko free tier: 30 requests per minute
  static const int coinGeckoMaxRequests = 30;
  static const Duration coinGeckoWindow = Duration(minutes: 1);

  CoinGeckoRateLimiter() : super(
    maxRequests: coinGeckoMaxRequests,
    window: coinGeckoWindow,
  );

  /// Specialized method for CoinGecko API calls
  Future<T> executeCoinGeckoRequest<T>(
    Future<T> Function() operation, {
    String? endpoint,
  }) async {
    return RateLimiter.executeWithRetry<T>(
      operation,
      rateLimiter: this,
      endpoint: endpoint,
      shouldRetry: (error) {
        // Retry on rate limit errors (429) and network errors
        if (error.toString().contains('429')) return true;
        if (error.toString().toLowerCase().contains('timeout')) return true;
        if (error.toString().toLowerCase().contains('connection')) return true;
        return false;
      },
    );
  }
}
