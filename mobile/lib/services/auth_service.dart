import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

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
        // Refresh full user data & signature status from local DB
        final User? freshDbUser = await _dbHelper.getUserById(storedUser.id);
        final String? sigPath = await _dbHelper.getUserSignaturePath(storedUser.id);
        final User effectiveUser = freshDbUser ?? storedUser;
        _currentUser = User(
          id: effectiveUser.id,
          fullName: effectiveUser.fullName,
          phone: effectiveUser.phone,
          email: effectiveUser.email,
          sicilNo: effectiveUser.sicilNo,
          operatorTitle: effectiveUser.operatorTitle,
          ekipnetNo: effectiveUser.ekipnetNo,
          diplomaNo: effectiveUser.diplomaNo,
          signaturePath: sigPath ?? effectiveUser.signaturePath,
          role: effectiveUser.role,
          isActive: effectiveUser.isActive,
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
    required String operatorTitle,
    String? email,
    required String password,
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
        operatorTitle: operatorTitle,
        sicilNo: null,
        ekipnetNo: null,
        diplomaNo: null,
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
        operatorTitle: user.operatorTitle,
        ekipnetNo: user.ekipnetNo,
        diplomaNo: user.diplomaNo,
        signaturePath: sigPath ?? user.signaturePath,
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

  /// Create a new local user (Employee or Admin) from Admin Panel or Registration
  Future<bool> createLocalUser({
    required String fullName,
    required String phone,
    String? email,
    String? operatorTitle,
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

      final User newUser = await _dbHelper.createUser(
        fullName: fullName,
        phone: phone,
        email: email,
        operatorTitle: operatorTitle,
        sicilNo: null,
        ekipnetNo: null,
        diplomaNo: null,
        password: password,
        role: role,
      );

      // Auto login newly registered user if no active session
      if (_currentUser == null) {
        _currentUser = newUser;
        await _storageService.saveUser(_currentUser!);
        await _storageService.saveTokens(
          accessToken: 'local_session_${newUser.id}',
          refreshToken: 'local_refresh_${newUser.id}',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Kullanıcı oluşturulurken hata oluştu: ${e.toString()}';
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
    String? operatorTitle,
    required String role,
    String? newPassword,
  }) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      _errorMessage = 'Yalnızca yönetici (admin) kullanıcı bilgilerini güncelleyebilir.';
      notifyListeners();
      return false;
    }
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
        operatorTitle: operatorTitle,
        sicilNo: null,
        ekipnetNo: null,
        diplomaNo: null,
        role: role,
        newPassword: newPassword,
      );

      // If updating currently logged-in user, refresh _currentUser state
      if (success && _currentUser?.id == id) {
        final User? updated = await _dbHelper.getUserById(id);
        if (updated != null) {
          _currentUser = updated;
          await _storageService.saveUser(_currentUser!);
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
        operatorTitle: _currentUser!.operatorTitle,
        ekipnetNo: _currentUser!.ekipnetNo,
        diplomaNo: _currentUser!.diplomaNo,
        signaturePath: signaturePath,
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

  /// Update currently logged in user profile fields (Admin Only)
  Future<bool> updateUserProfile({
    required String fullName,
    required String operatorTitle,
    String? phone,
    String? email,
  }) async {
    if (_currentUser == null) return false;

    if (!_currentUser!.isAdmin) {
      _errorMessage = 'Operatör profil bilgileri yalnızca sistem yöneticisi (admin) tarafından değiştirilebilir.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool success = await _dbHelper.updateUser(
        id: _currentUser!.id,
        fullName: fullName,
        phone: phone ?? _currentUser!.phone,
        email: email ?? _currentUser!.email,
        sicilNo: null,
        operatorTitle: operatorTitle,
        ekipnetNo: null,
        diplomaNo: null,
        role: _currentUser!.role,
      );

      if (success) {
        final User? updated = await _dbHelper.getUserById(_currentUser!.id);
        if (updated != null) {
          final String? sigPath = await _dbHelper.getUserSignaturePath(_currentUser!.id);
          _currentUser = User(
            id: updated.id,
            fullName: updated.fullName,
            phone: updated.phone,
            email: updated.email,
            operatorTitle: updated.operatorTitle,
            signaturePath: sigPath ?? updated.signaturePath,
            role: updated.role,
            isActive: updated.isActive,
            hasSignature: sigPath != null && sigPath.isNotEmpty,
          );
          await _storageService.saveUser(_currentUser!);
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
