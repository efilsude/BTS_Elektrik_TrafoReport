import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class VerificationResult {
  final bool success;
  final String? debugCode;
  final int? expiresInSeconds;
  final String? errorMessage;

  VerificationResult({
    required this.success,
    this.debugCode,
    this.expiresInSeconds,
    this.errorMessage,
  });
}

class AuthService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  User? _currentUser;
  bool _isLoading = false;
  // kReleaseMode: always false regardless of setMockMode calls
  bool _isMockMode = kReleaseMode ? false : false; // init value; enforced again in initAuth
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isMockMode => _isMockMode;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void setMockMode(bool value) {
    if (kReleaseMode) return; // Prevent mock mode in production release builds
    _isMockMode = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize and check persistent login status
  Future<void> initAuth() async {
    // Release builds must never run in mock mode
    if (kReleaseMode) {
      _isMockMode = false;
    }
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

  // Check if system has 0 users and needs initial admin bootstrap — GET /auth/bootstrap-status
  // Throws BootstrapCheckException on network/timeout error so callers can show an error UI.
  Future<bool> checkBootstrapStatus() async {
    if (_isMockMode) return false;
    try {
      final http.Response response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/bootstrap-status'),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['needs_bootstrap'] == true;
      }
      // Non-200 from server → assume server reachable, login screen
      return false;
    } on Exception {
      // Network/timeout: rethrow so SplashScreen can show a proper error
      rethrow;
    }
  }

  // Request Email Verification Code for Initial Admin Bootstrap — POST /auth/request-verification-bootstrap
  Future<VerificationResult> requestVerificationBootstrap({
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isMockMode) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      notifyListeners();
      return VerificationResult(
        success: true,
        debugCode: '123456',
        expiresInSeconds: 600,
      );
    }

    try {
      final Map<String, String> body = <String, String>{
        'email': email.trim(),
      };

      final http.Response response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/request-verification-bootstrap'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String? debugCode = data['debug_code']?.toString();
        final int? expiresInSeconds = data['expires_in_seconds'] as int?;

        _isLoading = false;
        notifyListeners();
        return VerificationResult(
          success: true,
          debugCode: debugCode,
          expiresInSeconds: expiresInSeconds ?? 600,
        );
      } else {
        _errorMessage = _parseErrorMessage(
          response,
          'İlk yönetici doğrulama kodu gönderilemedi.',
        );
        _isLoading = false;
        notifyListeners();
        return VerificationResult(
          success: false,
          errorMessage: _errorMessage,
        );
      }
    } catch (e) {
      _errorMessage = 'Sunucuyla bağlantı kurulamadı (${AppConfig.apiBaseUrl}). İnternet bağlantınızı kontrol edin.';
      _isLoading = false;
      notifyListeners();
      return VerificationResult(
        success: false,
        errorMessage: _errorMessage,
      );
    }
  }

  // Register Initial Admin — POST /auth/bootstrap
  Future<bool> bootstrapAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String? sicilNo,
    required String password,
    required String verificationCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isMockMode) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _currentUser = User(
        id: '1',
        fullName: fullName,
        email: email,
        phone: phone,
        sicilNo: sicilNo,
        role: 'admin',
        isActive: true,
        hasSignature: false,
      );
      await _storageService.saveTokens(
        accessToken: 'mock_access_token_admin',
        refreshToken: 'mock_refresh_token_admin',
      );
      await _storageService.saveUser(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
        'verification_code': verificationCode.trim(),
      };

      if (sicilNo != null && sicilNo.trim().isNotEmpty) {
        body['sicil_no'] = sicilNo.trim();
      }

      final http.Response response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/bootstrap'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> userJson = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);

        // Automatically attempt login after bootstrap to obtain tokens
        return await login(
          identifier: phone,
          password: password,
          isAdminMode: true,
        );
      } else {
        _errorMessage = _parseErrorMessage(response, 'İlk yönetici kaydı başarısız oldu.');
      }
    } catch (e) {
      _errorMessage = 'Sunucuyla bağlantı kurulamadı (${AppConfig.apiBaseUrl}).';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Helper method to parse Turkish error message from API response
  String _parseErrorMessage(http.Response response, String defaultMsg) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error') && data['error'] is Map) {
        final Map errMap = data['error'] as Map;
        final String? code = errMap['code']?.toString();
        final String? msg = errMap['message']?.toString();

        if (code != null) {
          switch (code) {
            case 'BOOTSTRAP_NOT_ALLOWED':
              return 'Sistemde zaten kayıtlı kullanıcı var. İlk yönetici kaydı gerçekleştirilemez.';
            case 'VERIFICATION_CODE_INVALID':
              return 'E-posta doğrulama kodu geçersiz veya kullanılmış.';
            case 'VERIFICATION_CODE_EXPIRED':
              return 'E-posta doğrulama kodunun süresi dolmuş. Lütfen yeni kod isteyin.';
            case 'EMAIL_SEND_FAILED':
              return msg != null && msg.isNotEmpty ? msg : 'Doğrulama e-postası gönderilemedi. Sunucu e-posta ayarlarını kontrol edin.';
            case 'INVITE_CODE_INVALID':
              return 'Davet kodu geçersiz veya süresi dolmuş.';
            case 'USER_ALREADY_EXISTS':
              return 'Bu telefon, e-posta veya sicil no ile kayıtlı kullanıcı zaten var.';
            case 'RATE_LIMIT_EXCEEDED':
              return 'Lütfen yeni doğrulama kodu istemeden önce 60 saniye bekleyin.';
          }
        }
        if (msg != null && msg.isNotEmpty) return msg;
      } else if (data.containsKey('detail')) {
        if (data['detail'] is String) return data['detail'].toString();
        if (data['detail'] is List && (data['detail'] as List).isNotEmpty) {
          final firstErr = (data['detail'] as List).first;
          if (firstErr is Map && firstErr['msg'] != null) return firstErr['msg'].toString();
        }
      }
    } catch (_) {}
    return defaultMsg;
  }


  // Request Email Verification Code — POST /auth/request-verification
  Future<VerificationResult> requestVerificationCode({
    required String email,
    required String inviteCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isMockMode) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (inviteCode == 'INVALID' || inviteCode == 'EXPIRED') {
        _errorMessage = 'Davet kodu geçersiz veya süresi dolmuş.';
        _isLoading = false;
        notifyListeners();
        return VerificationResult(
          success: false,
          errorMessage: _errorMessage,
        );
      }
      _isLoading = false;
      notifyListeners();
      return VerificationResult(
        success: true,
        debugCode: '123456',
        expiresInSeconds: 600,
      );
    }

    try {
      final Map<String, String> body = <String, String>{
        'email': email.trim(),
        'invite_code': inviteCode.trim(),
      };

      final http.Response response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/request-verification'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String? debugCode = data['debug_code']?.toString();
        final int? expiresInSeconds = data['expires_in_seconds'] as int?;

        _isLoading = false;
        notifyListeners();
        return VerificationResult(
          success: true,
          debugCode: debugCode,
          expiresInSeconds: expiresInSeconds ?? 600,
        );
      } else {
        _errorMessage = _parseErrorMessage(
          response,
          'Doğrulama kodu gönderilemedi. Lütfen bilgilerinizi kontrol edin.',
        );
        _isLoading = false;
        notifyListeners();
        return VerificationResult(
          success: false,
          errorMessage: _errorMessage,
        );
      }
    } catch (e) {
      _errorMessage = 'Sunucuyla bağlantı kurulamadı (${AppConfig.apiBaseUrl}). İnternet bağlantınızı kontrol edin.';
      _isLoading = false;
      notifyListeners();
      return VerificationResult(
        success: false,
        errorMessage: _errorMessage,
      );
    }
  }


  // Attempt to refresh access token using saved refresh token
  Future<bool> refreshAccessToken() async {
    final String? refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      return false;
    }

    try {
      final http.Response response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'refresh_token': refreshToken}),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String newAccessToken = data['access_token'] as String;
        await _storageService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
        );
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (_) {
      await logout();
      return false;
    }
  }

  // Authenticated HTTP request wrapper with automatic 401 Token Refresh retry
  Future<http.Response> authenticatedRequest(
    Future<http.Response> Function(String token) requestFn,
  ) async {
    String? token = await _storageService.getAccessToken();
    if (token == null) {
      throw Exception('Oturum açılmamış.');
    }

    http.Response response = await requestFn(token);
    
    // If 401 Unauthorized, try refreshing token
    if (response.statusCode == 401) {
      final bool refreshed = await refreshAccessToken();
      if (refreshed) {
        token = await _storageService.getAccessToken();
        if (token != null) {
          response = await requestFn(token);
        }
      }
    }
    return response;
  }

  // Login — aligned with API_CONTRACT.md §2.2
  Future<bool> login({
    required String identifier, // phone, email, or sicil_no
    required String password,
    required bool isAdminMode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isMockMode) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      
      if (password.length < 4) {
        _errorMessage = 'Şifre en az 4 karakter olmalıdır.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (isAdminMode) {
        if (identifier == 'admin' || identifier.contains('admin') || identifier == '05000000000' || identifier == '99999') {
          _currentUser = User(
            id: '1',
            fullName: 'Yönetici Admin',
            email: 'admin@btselektrik.com',
            phone: '05000000000',
            sicilNo: '99999',
            role: 'admin',
            isActive: true,
            hasSignature: true,
          );
        } else {
          _errorMessage = 'Hatalı admin kimlik bilgileri. (Mock için: 05000000000 / Admin123!)';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _currentUser = User(
          id: '2',
          fullName: 'Ahmet Teknisyen',
          email: identifier.contains('@') ? identifier : 'ahmet@btselektrik.com',
          phone: '05551112233',
          sicilNo: '12345',
          role: 'employee',
          isActive: true,
          hasSignature: false,
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

    // Real API integration: POST /auth/login
    try {
      final Map<String, String> body = <String, String>{
        'identifier': identifier.trim(),
        'password': password,
      };

      final http.Response response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String accessToken = data['access_token'] ?? '';
        final String refreshToken = data['refresh_token'] ?? '';
        final Map<String, dynamic> userJson = data['user'] as Map<String, dynamic>;
        
        _currentUser = User.fromJson(userJson);
        
        // Role check
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
        _errorMessage = _parseErrorMessage(response, 'Giriş başarısız oldu. Lütfen bilgilerinizi kontrol edin.');
      }
    } catch (e) {
      _errorMessage = 'Sunucuyla bağlantı kurulamadı (${AppConfig.apiBaseUrl}). İnternet bağlantınızı veya sunucu durumunu kontrol edin.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Register — POST /auth/register
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String? sicilNo,
    required String inviteCode,
    required String verificationCode,
    required String password,
    bool isAdminMode = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isMockMode) {
      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (verificationCode == '000000' || verificationCode == 'WRONG') {
        _errorMessage = 'E-posta doğrulama kodu geçersiz veya kullanılmış.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (verificationCode == 'EXPIRED') {
        _errorMessage = 'E-posta doğrulama kodunun süresi dolmuş.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
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

      _currentUser = User(
        id: 'mock_registered_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        email: email,
        phone: phone,
        sicilNo: sicilNo,
        role: isAdminMode ? 'admin' : 'employee',
        isActive: true,
        hasSignature: false,
      );

      await _storageService.saveTokens(
        accessToken: 'mock_access_token_${_currentUser!.role}',
        refreshToken: 'mock_refresh_token_${_currentUser!.role}',
      );
      await _storageService.saveUser(_currentUser!);

      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Real API call: POST /auth/register
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'invite_code': inviteCode.trim(),
        'verification_code': verificationCode.trim(),
        'password': password,
      };

      if (sicilNo != null && sicilNo.trim().isNotEmpty) {
        body['sicil_no'] = sicilNo.trim();
      }

      final http.Response response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> userJson = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
        
        // Automatically attempt login right after registration to acquire tokens
        return await login(
          identifier: phone,
          password: password,
          isAdminMode: isAdminMode,
        );
      } else {
        _errorMessage = _parseErrorMessage(
          response,
          'Kayıt başarısız oldu. Lütfen davet kodunu ve bilgilerinizi kontrol edin.',
        );
      }
    } catch (e) {
      _errorMessage = 'Sunucuyla bağlantı kurulamadı. Lütfen sunucu adresini ve internet bağlantınızı kontrol edin.';
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
