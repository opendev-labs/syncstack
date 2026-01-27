import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gh_service.dart';

class AuthProvider extends ChangeNotifier {
  final GHService _ghService = GHService();
  
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _username;
  String? _token;
  String? _vercelToken;
  String? _hfToken;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get username => _username;
  String? get token => _token;
  String? get vercelToken => _vercelToken;
  String? get hfToken => _hfToken;
  Map<String, dynamic>? get userProfile => _userProfile;

  AuthProvider() {
    _initFirebaseAuth();
    _loadAuth();
  }

  void _initFirebaseAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _isLoggedIn = true;
        _username = user.displayName ?? user.email?.split('@').first;
        _userProfile = {
          'name': user.displayName,
          'email': user.email,
          'avatar_url': user.photoURL,
        };
        notifyListeners();
      } else {
        // Only set to false if we weren't logged in via token previously
        // Actually, let's stick to Firebase as the primary auth state if it's active
      }
    });
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _username = prefs.getString('auth_username');
    _vercelToken = prefs.getString('vercel_token');
    _hfToken = prefs.getString('hf_token');

    if (_token != null && _username != null) {
      _isLoggedIn = true;
    }
    
    _isInitialized = true;
    notifyListeners();
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

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGitHub() async {
    _isLoading = true;
    notifyListeners();
    try {
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(githubProvider);
      // Note: On desktop/Linux, signInWithPopup might not work directly.
      // We might need to handle the token manually if this is a desktop app.
    } catch (e) {
      debugPrint('GitHub Sign-In Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithVercel(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      await setVercelToken(token);
      _isLoggedIn = true;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithHF(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      await setHFToken(token);
      _isLoggedIn = true;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setVercelToken(String? token) async {
    _vercelToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('vercel_token', token);
    } else {
      await prefs.remove('vercel_token');
    }
    notifyListeners();
  }

  Future<void> setHFToken(String? token) async {
    _hfToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('hf_token', token);
    } else {
      await prefs.remove('hf_token');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_username');
    await prefs.remove('vercel_token');
    await prefs.remove('hf_token');
    
    await FirebaseAuth.instance.signOut();
    
    _isLoggedIn = false;
    _username = null;
    _token = null;
    _vercelToken = null;
    _hfToken = null;
    _userProfile = null;
    notifyListeners();
  }
}
