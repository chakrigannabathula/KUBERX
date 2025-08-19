import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AuthService {
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Secure storage for JWT tokens
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Dynamic base URL based on platform
  static String get baseUrl {
    // TODO: Replace this ngrok URL with your actual ngrok URL after running 'ngrok http 3000'
    const String ngrokUrl = 'https://01e0d7b922ed.ngrok-free.app/api/auth';

    // For development, you can switch between localhost and ngrok
    const bool useNgrok = true; // Set to true when sharing with others

    if (useNgrok) {
      return ngrokUrl;
    }

    // Local development URLs
    if (kIsWeb) {
      return 'http://localhost:3000/api/auth';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/auth'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api/auth'; // iOS simulator
    } else {
      return 'http://localhost:3000/api/auth'; // Desktop
    }
  }

  late final Dio _dio;

  AuthService() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add headers for ngrok compatibility
    _dio.options.headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add interceptors for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // Initialize the service
  Future<void> initialize() async {
    print('AuthService initialized with base URL: $baseUrl');
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Complete Google Sign-In with backend authentication
  /// This is the MAIN method that should be called for Google login
  Future<AuthResponse> authenticateWithGoogle() async {
    try {
      // Step 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 2: Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      // Step 3: Get Firebase token
      final String? firebaseToken = await firebaseUser.getIdToken();

      if (firebaseToken == null) {
        throw Exception('Failed to get Firebase token');
      }

      // Step 4: Authenticate with your backend using the correct endpoint
      final response = await _dio.post('/google-signin', data: {
        'firebaseToken': firebaseToken,
        'userData': {
          'name': firebaseUser.displayName,
          'email': firebaseUser.email,
          'photoURL': firebaseUser.photoURL,
        }
      });

      // Step 5: Parse backend response and store JWT token
      final authResponse = AuthResponse.fromJson(response.data);

      // Store JWT token securely
      await _storeJWTToken(authResponse.token);

      // Store user data for offline access
      await _storeUserData(authResponse.user);

      return authResponse;

    } catch (e) {
      print('Authentication error: $e');
      // Clean up on error
      await _auth.signOut();
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  /// Check if user is already logged in (has valid JWT token)
  Future<bool> isLoggedIn() async {
    try {
      final jwtToken = await getJWTToken();
      if (jwtToken == null) return false;

      // Verify token with backend
      final response = await _dio.get('/verify',
        options: Options(headers: {'Authorization': 'Bearer $jwtToken'})
      );

      return response.data['valid'] == true;
    } catch (e) {
      print('Token verification failed: $e');
      // Clear invalid token
      await _clearAllTokens();
      return false;
    }
  }

  /// Get current user data from backend
  Future<UserData?> getCurrentUserData() async {
    try {
      final jwtToken = await getJWTToken();
      if (jwtToken == null) return null;

      final response = await _dio.get('/verify',
        options: Options(headers: {'Authorization': 'Bearer $jwtToken'})
      );

      if (response.data['valid'] == true) {
        return UserData.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Store JWT token securely
  Future<void> _storeJWTToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  /// Get stored JWT token
  Future<String?> getJWTToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  /// Store user data for offline access
  Future<void> _storeUserData(UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setBool('profile_complete', user.isProfileCompleted);
    await prefs.setString('custom_user_name', user.name);
  }

  /// Get stored user data
  Future<UserData?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return UserData.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      print('Error getting stored user data: $e');
      return null;
    }
  }

  /// Clear all stored tokens and data
  Future<void> _clearAllTokens() async {
    await _secureStorage.delete(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('profile_complete');
    await prefs.remove('custom_user_name');
    await prefs.remove('firebase_token');
    await prefs.remove('pending_user_email');
    await prefs.remove('pending_user_name');
  }

  /// Complete logout
  Future<void> signOut() async {
    try {
      // Sign out from Firebase and Google
      await _auth.signOut();
      await _googleSignIn.signOut();

      // Clear all stored data
      await _clearAllTokens();

      print('Successfully logged out');
    } catch (e) {
      print('Sign out error: $e');
      // Even if there's an error, clear local data
      await _clearAllTokens();
    }
  }

  /// Legacy methods for backward compatibility (but updated to use JWT)

  /// Check if user exists and profile is complete (using JWT token)
  Future<UserCheckResponse> checkUser(String firebaseToken) async {
    try {
      final response = await _dio.post('/check-user', data: {
        'firebaseToken': firebaseToken,
      });

      return UserCheckResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Complete user onboarding
  Future<OnboardingResponse> completeOnboarding({
    required String firebaseToken,
    required String username,
    required DateTime dateOfBirth,
    String? name,
  }) async {
    try {
      final response = await _dio.post('/complete-onboarding', data: {
        'firebaseToken': firebaseToken,
        'username': username,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'name': name,
      });

      final onboardingResponse = OnboardingResponse.fromJson(response.data);

      // Store the JWT token from onboarding completion
      await _storeJWTToken(onboardingResponse.token);
      await _storeUserData(onboardingResponse.user);

      return onboardingResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get current Firebase token
  Future<String?> getFirebaseToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        return data['error'];
      }
      return 'Server error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout. Please try again.';
    } else {
      return 'Network error. Please try again.';
    }
  }
}

/// Response model for user check
class UserCheckResponse {
  final bool exists;
  final bool needsOnboarding;
  final bool profileComplete;
  final UserData? user;
  final String? message;

  UserCheckResponse({
    required this.exists,
    required this.needsOnboarding,
    required this.profileComplete,
    this.user,
    this.message,
  });

  factory UserCheckResponse.fromJson(Map<String, dynamic> json) {
    // Handle profileComplete which can be either boolean or string
    bool profileComplete = false;
    if (json['profileComplete'] is bool) {
      profileComplete = json['profileComplete'];
    } else if (json['profileComplete'] is String) {
      profileComplete = json['profileComplete'].toString().isNotEmpty;
    }

    return UserCheckResponse(
      exists: json['exists'] ?? false,
      needsOnboarding: json['needsOnboarding'] ?? true,
      profileComplete: profileComplete,
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      message: json['message'],
    );
  }
}

/// Response model for onboarding completion
class OnboardingResponse {
  final String message;
  final String token;
  final UserData user;

  OnboardingResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory OnboardingResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingResponse(
      message: json['message'],
      token: json['token'],
      user: UserData.fromJson(json['user']),
    );
  }
}

/// User data model
class UserData {
  final String id;
  final String email;
  final String name;
  final String? username;
  final String? profilePicture;
  final String language;
  final bool isVerified;
  final String kycStatus;
  final double totalPortfolioValue;
  final bool isProfileCompleted;

  UserData({
    required this.id,
    required this.email,
    required this.name,
    this.username,
    this.profilePicture,
    required this.language,
    required this.isVerified,
    required this.kycStatus,
    required this.totalPortfolioValue,
    required this.isProfileCompleted,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      username: json['username'],
      profilePicture: json['profilePicture'],
      language: json['language'] ?? 'English',
      isVerified: json['isVerified'] ?? false,
      kycStatus: json['kycStatus'] ?? 'pending',
      totalPortfolioValue: (json['totalPortfolioValue'] ?? 0).toDouble(),
      isProfileCompleted: json['isProfileCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'username': username,
      'profilePicture': profilePicture,
      'language': language,
      'isVerified': isVerified,
      'kycStatus': kycStatus,
      'totalPortfolioValue': totalPortfolioValue,
      'isProfileCompleted': isProfileCompleted,
    };
  }
}

/// Authentication response model
class AuthResponse {
  final String token;
  final UserData user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: UserData.fromJson(json['user']),
    );
  }
}
