import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _authToken;
  String _baseUrl = 'http://BelleN-NodeS-htzjq6lxvVlw-908287247.ap-south-1.elb.amazonaws.com/api';

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get authToken => _authToken;

  // Initialize authentication state
  Future<void> initialize() async {
    await _loadAuthState();
  }

  // Load authentication state from shared preferences
  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');

      if (token != null && userData != null) {
        _authToken = token;
        _currentUser = json.decode(userData);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading auth state: $e');
      }
    }
  }

  // Save authentication state to shared preferences
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_authToken != null && _currentUser != null) {
        await prefs.setString('auth_token', _authToken!);
        await prefs.setString('user_data', json.encode(_currentUser));
      } else {
        await prefs.remove('auth_token');
        await prefs.remove('user_data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving auth state: $e');
      }
    }
  }

  // Send OTP for phone number verification
  Future<Map<String, dynamic>> sendOTP(String phoneNumber, {String? email, String preferredMethod = 'email'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/phone-auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          if (email != null) 'email': email,
          'preferredMethod': preferredMethod,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Send OTP error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Verify OTP and login/register user
  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otp, {String? name, String? email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/phone-auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'otp': otp,
          if (name != null) 'name': name,
          if (email != null) 'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Set authentication state
        _currentUser = data['user'];
        _authToken = data['token'];
        _isAuthenticated = true;
        
        await _saveAuthState();
        notifyListeners();
        
        return {
          'success': true, 
          'data': data,
          'isNewUser': data['isNewUser'] ?? false
        };
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to verify OTP'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Verify OTP error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String phoneNumber, {String? email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/phone-auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          if (email != null) 'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to resend OTP'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Resend OTP error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Check if user exists by phone number
  Future<Map<String, dynamic>> checkUserExists(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/phone-auth/user/$phoneNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to check user'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Check user error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(String userId, {String? name, String? email, String? address}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/phone-auth/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Update current user data
        if (_currentUser != null) {
          _currentUser!.addAll(data['user']);
          await _saveAuthState();
          notifyListeners();
        }
        
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update profile error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Legacy methods for backward compatibility
  Future<bool> login(String email, String password) async {
    // This method is kept for backward compatibility but should not be used
    if (kDebugMode) {
      print('Warning: Using legacy login method. Use phone-based authentication instead.');
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    // This method is kept for backward compatibility but should not be used
    if (kDebugMode) {
      print('Warning: Using legacy register method. Use phone-based authentication instead.');
    }
    return false;
  }

  // Logout user
  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    _isAuthenticated = false;
    
    await _saveAuthState();
    notifyListeners();
  }

  // Check if user is authenticated
  bool get isLoggedIn => _isAuthenticated;
} 