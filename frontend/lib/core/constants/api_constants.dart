class ApiConstants {
  // Use 10.0.2.2 for Android Emulator, localhost or 127.0.0.1 for Desktop/Web, or your LAN IP for real devices.
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';

  // Category endpoints
  static const String categories = '$baseUrl/categories';

  // Book endpoints
  static const String books = '$baseUrl/books';
  static const String myListings = '$baseUrl/books/my/listings';

  // Order endpoints
  static const String orders = '$baseUrl/orders';
  static const String myOrders = '$baseUrl/orders/my-orders';
  static const String mySales = '$baseUrl/orders/my-sales';

  // Wallet endpoints
  static const String wallet = '$baseUrl/wallet';
  static const String topUp = '$baseUrl/wallet/topup';

  // Upload endpoint
  static const String upload = '$baseUrl/upload';
}
