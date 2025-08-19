import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  ApiService() {
    _dio.options.baseUrl = ApiConfig.baseUrl; // Fixed: baseUrl instead of baseURL
    _dio.options.connectTimeout = Duration(seconds: 30);
    _dio.options.receiveTimeout = Duration(seconds: 30);

    // Add headers for ngrok compatibility
    _dio.options.headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getJWTToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // User Profile APIs
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get(ApiConfig.userProfile);
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConfig.userProfile, data: data);
      return response.data;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get(ApiConfig.userDashboard);
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch dashboard: $e');
    }
  }

  // Cryptocurrency APIs
  Future<Map<String, dynamic>> getPopularCryptos() async {
    try {
      final response = await _dio.get(ApiConfig.cryptoPopular);
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch cryptocurrencies: $e');
    }
  }

  Future<Map<String, dynamic>> getCryptoDetails(String symbol) async {
    try {
      final response = await _dio.get('${ApiConfig.cryptoEndpoint}/$symbol');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch crypto details: $e');
    }
  }

  Future<List<dynamic>> searchCryptos(String query) async {
    try {
      final response = await _dio.get('${ApiConfig.cryptoSearch}/$query');
      return response.data['results'] ?? [];
    } catch (e) {
      throw Exception('Failed to search cryptocurrencies: $e');
    }
  }

  // Portfolio APIs
  Future<Map<String, dynamic>> getPortfolio() async {
    try {
      final response = await _dio.get(ApiConfig.portfolioGet);
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch portfolio: $e');
    }
  }

  Future<Map<String, dynamic>> buyCrypto({
    required String symbol,
    required String name,
    required double amount,
    required double price,
    String paymentMethod = 'wallet',
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.portfolioBuy,
        data: {
          'symbol': symbol,
          'name': name,
          'amount': amount,
          'price': price,
          'paymentMethod': paymentMethod,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to buy cryptocurrency: $e');
    }
  }

  Future<Map<String, dynamic>> sellCrypto({
    required String symbol,
    required double amount,
    required double price,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.portfolioSell,
        data: {
          'symbol': symbol,
          'amount': amount,
          'price': price,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to sell cryptocurrency: $e');
    }
  }

  Future<Map<String, dynamic>> updatePortfolioPrices(Map<String, double> prices) async {
    try {
      final response = await _dio.put(
        ApiConfig.portfolioUpdate,
        data: {'prices': prices},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update portfolio prices: $e');
    }
  }

  // Transaction APIs
  Future<Map<String, dynamic>> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.userTransactions,
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }
}
