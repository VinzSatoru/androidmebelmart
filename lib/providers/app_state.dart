import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void login(Map<String, dynamic> data) {
    _userData = data;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userData = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
