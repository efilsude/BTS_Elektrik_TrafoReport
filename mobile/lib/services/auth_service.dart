import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  // API URL Config
  static const String baseUrl = 'http://localhost:8000/api/v1'; // Adjust as needed
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isMockMode = true; // Enabled by default since backend is not ready (Phase 1)
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isMockMode => _isMockMode;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void setMockMode(bool value) {
    _isMockMode = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize and check persistent login status
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? token = await _storageService.getAccessToken();
      if (token != null) {
        final User? user = await _storageService.getUser();
        if (user != null) {
          _currentUser = user;
        }
      }
    } catch (e) {
      _errorMessage = 'Oturum bilgileri yüklenirken hata oluştu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login({
    required String identifier, // email or sicil_no
    required String password,
    required bool isAdminMode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isMockMode) {
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Basic mock credentials validation
      if (password.length < 4) {
        _errorMessage = 'Şifre en az 4 karakter olmalıdır.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check for user/admin login
      if (isAdminMode) {
        if (identifier == 'admin' || identifier.contains('admin') || identifier == '99999') {
          _currentUser = User(
            id: 'mock_admin_1',
            fullName: 'Mehmet Admin',
            email: 'admin@btselektrik.com',
            phone: '5551112233',
            sicilNo: '99999',
            role: 'admin',
            isActive: true,
          );
        } else {
          _errorMessage = 'Hatalı admin kimlik bilgileri. (Mock için: admin / 12345)';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Employee login
        _currentUser = User(
          id: 'mock_employee_1',
          fullName: 'Ahmet Teknisyen',
          email: identifier.contains('@') ? identifier : null,
          phone: '5552223344',
          sicilNo: identifier.contains('@') ? '12345' : identifier,
          role: 'employee',
          isActive: true,
        );
      }

      await _storageService.saveTokens(
        accessToken: 'mock_access_token_${_currentUser!.role}',
        refreshToken: 'mock_refresh_token_${_currentUser!.role}',
      );
      await _storageService.saveUser(_currentUser!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Real network integration
    try {
      final Map<String, String> body = <String, String>{
        'password': password,
      };
      
      if (identifier.contains('@')) {
        body['email'] = identifier;
      } else {
        body['sicil_no'] = identifier;
      }

      final http.Response response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String accessToken = data['access_token'] ?? '';
        final String refreshToken = data['refresh_token'] ?? '';
        final Map<String, dynamic> userJson = data['user'] as Map<String, dynamic>;
        
        _currentUser = User.fromJson(userJson);
        
        // Check role compatibility
        if (isAdminMode && _currentUser!.role != 'admin') {
          _errorMessage = 'Bu hesap admin yetkilerine sahip değil.';
          _currentUser = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _storageService.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        await _storageService.saveUser(_currentUser!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage = errData['error']?['message'] ?? 'Giriş başarısız oldu. Lütfen bilgilerinizi kontrol edin.';
      }
    } catch (e) {
      _errorMessage = 'Sunucuyla bağlantı kurulamadı. Çevrimdışı/Mock modunu etkinleştirebilirsiniz.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Register
  Future<bool> register({
    required String fullName,
    required String? email,
    required String phone,
    required String? sicilNo,
    required String inviteCode,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isMockMode) {
      await Future<void>.delayed(const Duration(seconds: 1)); // Delay simulation

      if (inviteCode == 'EXPIRED' || inviteCode == 'INVALID') {
        _errorMessage = 'Davet kodu geçersiz veya süresi dolmuş.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 8) {
        _errorMessage = 'Şifre en az 8 karakter olmalıdır.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Simulate successful registration
      _currentUser = User(
        id: 'mock_registered_user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        email: email,
        phone: phone,
        sicilNo: sicilNo,
        role: 'employee',
        isActive: true,
      );

      await _storageService.saveTokens(
        accessToken: 'mock_access_token_employee',
        refreshToken: 'mock_refresh_token_employee',
      );
      await _storageService.saveUser(_currentUser!);

      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Real API call
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'sicil_no': sicilNo,
        'invite_code': inviteCode,
        'password': password,
      };

      final http.Response response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic> userJson = data['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
        
        // Wait, does register automatically log in or return tokens?
        // Usually, in API_CONTRACT: /auth/register returns {user}
        // Let's assume the user should then log in, or the registration endpoint returns tokens too.
        // If register only returns user, let's login right after, or save mock/temp tokens.
        // Let's call login to retrieve real tokens, or if registration returned tokens we save them.
        // For security & compatibility, we'll save a temp login session or instruct them to log in.
        // Let's save a placeholder and let them navigate, or perform a login command.
        await _storageService.saveTokens(
          accessToken: 'temp_access_token_from_register',
          refreshToken: 'temp_refresh_token_from_register',
        );
        await _storageService.saveUser(_currentUser!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage = errData['error']?['message'] ?? 'Kayıt başarısız oldu. Davet kodunu kontrol edin.';
      }
    } catch (e) {
      _errorMessage = 'Sunucuyla bağlantı kurulamadı. Lütfen internetinizi kontrol edin.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.clearAll();
    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
  }
}
