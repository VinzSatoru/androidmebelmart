import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mebelmart_furniture/constants/api_constants.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      print('Attempting login for email: $email');

      final response = await http
          .post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again.');
        },
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return userData;
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Error logging in: $e');
    }
  }

  static Future<bool> register(Map<String, dynamic> userData) async {
    try {
      print('Attempting registration with data: $userData');

      if (userData['email'] == null ||
          userData['password'] == null ||
          userData['fullName'] == null) {
        throw Exception('Data registrasi tidak lengkap');
      }

      final response = await http
          .post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': userData['email'].split('@')[0].toLowerCase(),
          'email': userData['email'].toLowerCase(),
          'password': userData['password'],
          'fullName': userData['fullName'],
          'phoneNumber': userData['phoneNumber'] ?? '',
          'address': userData['address'] ?? '',
          'role': 'customer',
        }),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout, silakan coba lagi');
        },
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      switch (response.statusCode) {
        case 201:
          return true;
        case 400:
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Data tidak valid');
        case 409:
          throw Exception('Email sudah terdaftar');
        case 500:
          throw Exception('Terjadi kesalahan pada server');
        default:
          throw Exception('Terjadi kesalahan (${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout, silakan coba lagi');
    } on FormatException {
      throw Exception('Format data tidak valid');
    } catch (e) {
      print('Registration error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
