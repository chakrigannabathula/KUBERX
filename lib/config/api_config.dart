class ApiConfig {
  // Use the same ngrok URL as auth service (without /auth suffix)
  static const String baseUrl = 'https://01e0d7b922ed.ngrok-free.app/api';
  static const String authEndpoint = '/auth';
  static const String userEndpoint = '/user';
  static const String cryptoEndpoint = '/crypto';
  static const String portfolioEndpoint = '/portfolio';

  // API endpoints
  static const String googleSignIn = '$authEndpoint/google-signin';
  static const String refreshToken = '$authEndpoint/refresh-token';
  static const String verifyToken = '$authEndpoint/verify';
  static const String logout = '$authEndpoint/logout';

  static const String userProfile = '$userEndpoint/profile';
  static const String userDashboard = '$userEndpoint/dashboard';
  static const String userTransactions = '$userEndpoint/transactions';

  static const String cryptoPopular = '$cryptoEndpoint/popular';
  static const String cryptoSearch = '$cryptoEndpoint/search';

  static const String portfolioGet = '$portfolioEndpoint';
  static const String portfolioBuy = '$portfolioEndpoint/buy';
  static const String portfolioSell = '$portfolioEndpoint/sell';
  static const String portfolioUpdate = '$portfolioEndpoint/update-prices';
}
