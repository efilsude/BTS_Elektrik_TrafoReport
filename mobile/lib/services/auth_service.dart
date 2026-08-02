import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
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
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isMockMode => false; // Phase 1 is purely local SQLite DB
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void setMockMode(bool value) {
    // Phase 1 is standalone local database, mock mode toggle is disabled
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize and check persistent local login status
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final User? storedUser = await _storageService.getUser();
      if (storedUser != null) {
        // Refresh signature status from local DB
        final String? sigPath = await _dbHelper.getUserSignaturePath(storedUser.id);
        _currentUser = User(
          id: storedUser.id,
          fullName: storedUser.fullName,
          phone: storedUser.phone,
          email: storedUser.email,
          sicilNo: storedUser.sicilNo,
          role: storedUser.role,
          isActive: storedUser.isActive,
          hasSignature: sigPath != null && sigPath.isNotEmpty,
        );
      }
    } catch (e) {
      _errorMessage = 'Oturum bilgileri yüklenirken hata oluştu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if local SQLite database has 0 users and needs initial admin bootstrap
  Future<bool> checkBootstrapStatus() async {
    try {
      final int userCount = await _dbHelper.getUserCount();
      return userCount == 0;
    } catch (e) {
      return false;
    }
  }

  /// Initial Admin Setup — Serverless Local Bootstrap
  Future<bool> bootstrapAdmin({
    required String fullName,
    required String phone,
    String? email,
    String? sicilNo,
    required String password,
    String? verificationCode, // Kept for signature compatibility
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final int userCount = await _dbHelper.getUserCount();
      if (userCount > 0) {
        _errorMessage = 'Sistemde zaten kayıtlı kullanıcı var.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final User adminUser = await _dbHelper.createUser(
        fullName: fullName,
        phone: phone,
        email: email,
        sicilNo: sicilNo,
        password: password,
        role: 'admin',
      );

      _currentUser = adminUser;
      await _storageService.saveUser(adminUser);
      await _storageService.saveTokens(
        accessToken: 'local_session_${adminUser.id}',
        refreshToken: 'local_refresh_${adminUser.id}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'İlk yönetici kaydı oluşturulurken hata: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request Verification (Serverless mock for UI flow compatibility)
  Future<VerificationResult> requestVerificationBootstrap({required String email}) async {
    return VerificationResult(success: true, debugCode: '123456', expiresInSeconds: 600);
  }

  Future<VerificationResult> requestVerificationCode({
    required String email,
    required String inviteCode,
  }) async {
    return VerificationResult(success: true, debugCode: '123456', expiresInSeconds: 600);
  }

  /// Local Login via Phone/Email and Password
  Future<bool> login({
    required String identifier,
    required String password,
    bool isAdminMode = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final User? user = await _dbHelper.authenticateUser(identifier, password);
      if (user == null) {
        _errorMessage = 'Hatalı telefon, e-posta veya şifre.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (isAdminMode && !user.isAdmin) {
        _errorMessage = 'Bu hesap yönetici (admin) yetkilerine sahip değil.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final String? sigPath = await _dbHelper.getUserSignaturePath(user.id);
      _currentUser = User(
        id: user.id,
        fullName: user.fullName,
        phone: user.phone,
        email: user.email,
        sicilNo: user.sicilNo,
        role: user.role,
        isActive: user.isActive,
        hasSignature: sigPath != null && sigPath.isNotEmpty,
      );

      await _storageService.saveUser(_currentUser!);
      await _storageService.saveTokens(
        accessToken: 'local_session_${user.id}',
        refreshToken: 'local_refresh_${user.id}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Giriş yapılırken bir hata oluştu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a new local user (Employee or Admin) from Admin Panel
  Future<bool> createLocalUser({
    required String fullName,
    required String phone,
    String? email,
    String? sicilNo,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final User? existing = await _dbHelper.getUserByPhoneOrEmail(phone);
      if (existing != null) {
        _errorMessage = 'Bu telefon numarası ile kayıtlı kullanıcı zaten var.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _dbHelper.createUser(
        fullName: fullName,
        phone: phone,
        email: email,
        sicilNo: sicilNo,
        password: password,
        role: role,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Kullanıcı oluşturulurken hata oluştu.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing local user from Admin Panel
  Future<bool> updateLocalUser({
    required String id,
    required String fullName,
    required String phone,
    String? email,
    String? sicilNo,
    required String role,
    String? newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final User? currentUserToUpdate = await _dbHelper.getUserById(id);
      if (currentUserToUpdate == null) {
        _errorMessage = 'Düzenlenecek kullanıcı bulunamadı.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check last admin demotion rule: if current role is admin and new role is employee
      if (currentUserToUpdate.isAdmin && role == 'employee') {
        final int adminCount = await _dbHelper.getAdminCount();
        if (adminCount <= 1) {
          _errorMessage = 'Sistemde en az bir yönetici bulunmalıdır. Son yöneticinin rolü değiştirilemez.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final bool success = await _dbHelper.updateUser(
        id: id,
        fullName: fullName,
        phone: phone,
        email: email,
        sicilNo: sicilNo,
        role: role,
        newPassword: newPassword,
      );

      // If updating currently logged-in user, refresh _currentUser state
      if (success && _currentUser?.id == id) {
        final User? updated = await _dbHelper.getUserById(id);
        if (updated != null) {
          _currentUser = updated;
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      final String msg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a local user from Admin Panel
  Future<bool> deleteUser(String targetUserId) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Rule 1: Currently logged-in user cannot delete themselves
      if (_currentUser?.id == targetUserId) {
        _errorMessage = 'Kendi hesabınızı silemezsiniz.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check target user role
      final User? targetUser = await _dbHelper.getUserById(targetUserId);
      if (targetUser == null) {
        _errorMessage = 'Silinecek kullanıcı bulunamadı.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Rule 2: The last active admin cannot be deleted
      if (targetUser.isAdmin) {
        final int adminCount = await _dbHelper.getAdminCount();
        if (adminCount <= 1) {
          _errorMessage = 'Sistemde en az bir yönetici bulunmalıdır. Son yönetici silinemez.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final bool success = await _dbHelper.deleteUser(targetUserId);
      if (!success) {
        _errorMessage = 'Kullanıcı silinirken hata oluştu.';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Kullanıcı silme hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change Password locally
  Future<bool> changePasswordLocally({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    final User? authenticated = await _dbHelper.authenticateUser(
      _currentUser!.phone,
      currentPassword,
    );

    if (authenticated == null) {
      _errorMessage = 'Mevcut şifreniz hatalı.';
      notifyListeners();
      return false;
    }

    final bool success = await _dbHelper.updateUserPassword(_currentUser!.id, newPassword);
    if (success) {
      notifyListeners();
    } else {
      _errorMessage = 'Şifre güncellenemedi.';
      notifyListeners();
    }
    return success;
  }

  /// Save User Digital Signature locally
  Future<bool> saveUserSignatureLocally(String signaturePath) async {
    if (_currentUser == null) return false;

    final bool success = await _dbHelper.updateUserSignature(_currentUser!.id, signaturePath);
    if (success) {
      _currentUser = User(
        id: _currentUser!.id,
        fullName: _currentUser!.fullName,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        sicilNo: _currentUser!.sicilNo,
        role: _currentUser!.role,
        isActive: _currentUser!.isActive,
        hasSignature: true,
      );
      await _storageService.saveUser(_currentUser!);
      notifyListeners();
    }
    return success;
  }

  /// Fetch User Signature Path
  Future<String?> getSignaturePath() async {
    if (_currentUser == null) return null;
    return await _dbHelper.getUserSignaturePath(_currentUser!.id);
  }

  /// Register wrapper method for existing forms
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
    return await createLocalUser(
      fullName: fullName,
      phone: phone,
      email: email,
      sicilNo: sicilNo,
      password: password,
      role: isAdminMode ? 'admin' : 'employee',
    );
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.clearAll();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }
}
