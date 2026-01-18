import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gh_service.dart';

class AuthProvider extends ChangeNotifier {
  final GHService _ghService = GHService();
  
  bool _isLoggedIn = false;
  String? _username;
  String? _token;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get username => _username;
  String? get token => _token;
  Map<String, dynamic>? get userProfile => _userProfile;

  AuthProvider() {
    _loadAuth();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final username = prefs.getString('auth_username');

    if (token != null && username != null) {
      _token = token;
      _username = username;
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String username, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _ghService.validateToken(username, token);
      
      if (result['success'] == true) {
        _isLoggedIn = true;
        _username = username;
        _token = token;
        _userProfile = result['user'];

        // Persist
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('auth_username', username);
      }
      
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_username');
    
    _isLoggedIn = false;
    _username = null;
    _token = null;
    _userProfile = null;
    notifyListeners();
  }
}
