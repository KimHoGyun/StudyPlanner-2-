import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);

      // null 안전성 체크
      bool success = response['success'] == true; // 명시적 비교

      if (success && response['user'] != null) {
        _user = User.fromJson(response['user']);
        _isAuthenticated = true;

        // Save token to shared preferences
        if (response['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', response['token']);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.signup(email, password, name);

      // null 안전성 체크
      bool success = response['success'] == true; // 명시적 비교

      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Signup error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }
}
