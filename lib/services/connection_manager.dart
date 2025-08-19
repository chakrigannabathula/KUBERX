import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Connection pool manager for optimized HTTP connections
class ConnectionPoolManager {
  static const int maxConnectionsPerHost = 6;
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration idleTimeout = Duration(seconds: 30);
  static const Duration keepAliveTimeout = Duration(seconds: 60);
  
  late final Dio _dio;
  late final HttpClient _httpClient;
  
  ConnectionPoolManager() {
    _initializeHttpClient();
    _initializeDio();
  }
  
  void _initializeHttpClient() {
    _httpClient = HttpClient();
    
    // Configure connection pool
    _httpClient.maxConnectionsPerHost = maxConnectionsPerHost;
    _httpClient.connectionTimeout = connectionTimeout;
    _httpClient.idleTimeout = idleTimeout;
    
    // Enable keep-alive
    _httpClient.autoUncompress = true;
    
    // Configure SSL/TLS
    _httpClient.badCertificateCallback = (cert, host, port) => false;
    
    // Set user agent
    _httpClient.userAgent = 'KuberX-CryptoApp/1.0';
  }
  
  void _initializeDio() {
    _dio = Dio();
    
    // Use our custom HTTP client
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return _httpClient;
    };
    
    // Configure Dio options
    _dio.options.connectTimeout = connectionTimeout;
    _dio.options.receiveTimeout = connectionTimeout;
    _dio.options.sendTimeout = Duration(seconds: 10);
    
    // Add response compression
    _dio.options.headers['Accept-Encoding'] = 'gzip, deflate';
    
    // Add connection keep-alive
    _dio.options.headers['Connection'] = 'keep-alive';
    
    // Add performance interceptors
    _dio.interceptors.add(_createPerformanceInterceptor());
    _dio.interceptors.add(_createCompressionInterceptor());
  }
  
  /// Create performance monitoring interceptor
  Interceptor _createPerformanceInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['start_time'] = DateTime.now().millisecondsSinceEpoch;
        handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime = response.requestOptions.extra['start_time'] as int?;
        if (startTime != null) {
          final duration = DateTime.now().millisecondsSinceEpoch - startTime;
          print('🚀 API Request completed in ${duration}ms: ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        final startTime = error.requestOptions.extra['start_time'] as int?;
        if (startTime != null) {
          final duration = DateTime.now().millisecondsSinceEpoch - startTime;
          print('⚠️ API Request failed after ${duration}ms: ${error.requestOptions.path}');
        }
        handler.next(error);
      },
    );
  }
  
  /// Create compression interceptor
  Interceptor _createCompressionInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Ensure we request compressed responses
        options.headers['Accept-Encoding'] = 'gzip, deflate, br';
        handler.next(options);
      },
    );
  }
  
  /// Get the optimized Dio instance
  Dio get dio => _dio;
  
  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'max_connections_per_host': maxConnectionsPerHost,
      'connection_timeout_ms': connectionTimeout.inMilliseconds,
      'idle_timeout_ms': idleTimeout.inMilliseconds,
      'keep_alive_timeout_ms': keepAliveTimeout.inMilliseconds,
      'user_agent': _httpClient.userAgent,
    };
  }
  
  /// Close all connections and cleanup
  void dispose() {
    _httpClient.close(force: true);
    _dio.close();
  }
}

/// Optimized request queue for managing concurrent API calls
class RequestQueue {
  final int maxConcurrentRequests;
  final Duration requestDelay;
  
  final List<_QueuedRequest> _queue = [];
  int _activeRequests = 0;
  bool _isProcessing = false;
  
  RequestQueue({
    this.maxConcurrentRequests = 3,
    this.requestDelay = const Duration(milliseconds: 100),
  });
  
  /// Add a request to the queue
  Future<T> enqueue<T>(Future<T> Function() request, {String? tag}) async {
    final completer = Completer<T>();
    final queuedRequest = _QueuedRequest<T>(
      request: request,
      completer: completer,
      tag: tag,
      timestamp: DateTime.now(),
    );
    
    _queue.add(queuedRequest);
    _processQueue();
    
    return completer.future;
  }
  
  /// Process the request queue
  void _processQueue() {
    if (_isProcessing || _queue.isEmpty) return;
    if (_activeRequests >= maxConcurrentRequests) return;
    
    _isProcessing = true;
    
    while (_queue.isNotEmpty && _activeRequests < maxConcurrentRequests) {
      final queuedRequest = _queue.removeAt(0);
      _executeRequest(queuedRequest);
    }
    
    _isProcessing = false;
  }
  
  /// Execute a queued request
  void _executeRequest(_QueuedRequest queuedRequest) {
    _activeRequests++;
    
    final stopwatch = Stopwatch()..start();
    
    queuedRequest.request().then((result) {
      stopwatch.stop();
      print('✅ Request completed in ${stopwatch.elapsedMilliseconds}ms${queuedRequest.tag != null ? ' (${queuedRequest.tag})' : ''}');
      
      queuedRequest.completer.complete(result);
      _activeRequests--;
      
      // Add delay between requests to avoid overwhelming the API
      Future.delayed(requestDelay, () {
        _processQueue();
      });
      
    }).catchError((error) {
      stopwatch.stop();
      print('❌ Request failed after ${stopwatch.elapsedMilliseconds}ms${queuedRequest.tag != null ? ' (${queuedRequest.tag})' : ''}: $error');
      
      queuedRequest.completer.completeError(error);
      _activeRequests--;
      
      // Process next request after delay
      Future.delayed(requestDelay, () {
        _processQueue();
      });
    });
  }
  
  /// Get queue statistics
  Map<String, dynamic> getStats() {
    return {
      'queue_length': _queue.length,
      'active_requests': _activeRequests,
      'max_concurrent': maxConcurrentRequests,
      'is_processing': _isProcessing,
      'oldest_request_age_ms': _queue.isNotEmpty 
        ? DateTime.now().difference(_queue.first.timestamp).inMilliseconds 
        : 0,
    };
  }
  
  /// Clear the queue
  void clear() {
    for (final request in _queue) {
      request.completer.completeError('Request queue cleared');
    }
    _queue.clear();
  }
  
  /// Get the number of pending requests
  int get pendingCount => _queue.length;
  
  /// Check if the queue is busy
  bool get isBusy => _activeRequests > 0 || _queue.isNotEmpty;
}

/// Internal class for queued requests
class _QueuedRequest<T> {
  final Future<T> Function() request;
  final Completer<T> completer;
  final String? tag;
  final DateTime timestamp;
  
  _QueuedRequest({
    required this.request,
    required this.completer,
    this.tag,
    required this.timestamp,
  });
}

/// Circuit breaker pattern for API fault tolerance
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration retryDelay;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;
  
  CircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(minutes: 1),
    this.retryDelay = const Duration(seconds: 30),
  });
  
  /// Execute an operation through the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptRetry()) {
        _state = CircuitBreakerState.halfOpen;
        print('🔄 Circuit breaker: attempting retry (half-open state)');
      } else {
        throw CircuitBreakerOpenException('Circuit breaker is open');
      }
    }
    
    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }
  
  /// Handle successful operation
  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    print('✅ Circuit breaker: reset to closed state');
  }
  
  /// Handle failed operation
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      print('🚨 Circuit breaker: opened due to ${_failureCount} failures');
    }
  }
  
  /// Check if we should attempt a retry
  bool _shouldAttemptRetry() {
    if (_lastFailureTime == null) return true;
    return DateTime.now().difference(_lastFailureTime!) > retryDelay;
  }
  
  /// Get current circuit breaker state
  CircuitBreakerState get state => _state;
  
  /// Get current failure count
  int get failureCount => _failureCount;
  
  /// Reset the circuit breaker
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
    print('🔄 Circuit breaker: manually reset');
  }
}

/// Circuit breaker states
enum CircuitBreakerState {
  closed,   // Normal operation
  open,     // Failing fast
  halfOpen, // Testing recovery
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
