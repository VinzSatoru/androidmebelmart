class ApiConstants {
  // Gunakan IP address komputer Anda untuk device fisik
  static const String baseUrl =
      'http://192.168.180.94:44800'; // Perhatikan ada '//' setelah 'http:'

  static const String apiUrl = '$baseUrl/api';

  // Auth endpoints
  static const String login = '$apiUrl/users/login';
  static const String register = '$apiUrl/users/register';
  static const String users = '$apiUrl/users';

  // Product endpoints
  static const String products = '$apiUrl/products';

  // Cart endpoints
  static String carts(String userId) => '$apiUrl/carts/$userId';

  // Order endpoints
  static String orders(String userId) => '$apiUrl/orders/$userId';
}
