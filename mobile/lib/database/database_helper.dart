import 'dart:convert';
import 'dart:io' show Platform, Directory;
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('traforeport_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && Platform.isWindows) {
      try {
        final Directory appSupportDir = await getApplicationSupportDirectory();
        dbPath = appSupportDir.path;
      } catch (e) {
        dbPath = await getDatabasesPath();
      }
    } else {
      dbPath = await getDatabasesPath();
    }

    // Ensure parent directory exists before SQLite tries to open the database file
    final Directory dbDir = Directory(dbPath);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final String path = join(dbPath, filePath);

    try {
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } catch (e, stackTrace) {
      debugPrint('[DatabaseHelper] SQLite veritabanı açılamadı ($path): $e\n$stackTrace');
      throw Exception(
        'Veritabanı dosyası açılamadı ($path).\n'
        'Lütfen uygulamanın yazma izinlerini ve disk alanını kontrol edin.\n'
        'Hata: $e',
      );
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const String userTable = '''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        email TEXT,
        sicil_no TEXT,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'employee',
        signature_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''';

    const String reportTable = '''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        report_type TEXT NOT NULL,
        sub_type TEXT NOT NULL,
        transformer_type TEXT NOT NULL,
        customer_name TEXT,
        trafo_label TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        creator_display_name TEXT,
        created_by TEXT,
        data_json TEXT NOT NULL,
        current_step INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        finalized_at TEXT
      )
    ''';

    const String photoTable = '''
      CREATE TABLE report_photos (
        id TEXT PRIMARY KEY,
        report_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (report_id) REFERENCES reports (id) ON DELETE CASCADE
      )
    ''';

    await db.execute(userTable);
    await db.execute(reportTable);
    await db.execute(photoTable);
  }

  // ---------------- PASSWORD HASHING (BCRYPT + SHA-256 LEGACY MIGRATION) ----------------

  /// Hash password using bcrypt
  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Legacy SHA-256 hash calculation (for Phase 1 transparent migration)
  static String _hashLegacySha256(String password) {
    const String salt = 'TrafoReport_Local_Salt_2026';
    final List<int> bytes = utf8.encode(password + salt);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password: try bcrypt first; if legacy SHA-256 matches, transparently re-hash with bcrypt
  Future<bool> verifyAndUpdatePassword(String userId, String password, String storedHash) async {
    try {
      // 1. Check if storedHash is bcrypt ($2a$, $2b$, $2y$)
      if (storedHash.startsWith('\$2')) {
        return BCrypt.checkpw(password, storedHash);
      }
    } catch (_) {}

    // 2. Legacy SHA-256 fallback
    final String legacyHash = _hashLegacySha256(password);
    if (legacyHash == storedHash) {
      // Transparent migration: update user's hash in SQLite to bcrypt
      final String newBcryptHash = hashPassword(password);
      await updateUserPasswordHash(userId, newBcryptHash);
      debugPrint('[TrafoReport] Kullanici (ID: $userId) şifre hash\'i SHA-256 -> bcrypt olarak şeffaf güncellendi.');
      return true;
    }

    return false;
  }

  // ---------------- USER OPERATIONS ----------------

  Future<int> getUserCount() async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<User?> getUserByPhoneOrEmail(String identifier) async {
    final Database db = await instance.database;
    final String cleanIdentifier = identifier.trim().toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'LOWER(phone) = ? OR LOWER(email) = ?',
      whereArgs: <dynamic>[cleanIdentifier, cleanIdentifier],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(String id) async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  /// Parameterized SQL query for authentication with bcrypt + legacy transparent migration
  Future<User?> authenticateUser(String identifier, String password) async {
    final Database db = await instance.database;
    final String cleanIdentifier = identifier.trim().toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: '(LOWER(phone) = ? OR LOWER(email) = ?) AND is_active = 1',
      whereArgs: <dynamic>[cleanIdentifier, cleanIdentifier],
    );

    if (maps.isEmpty) return null;

    for (final Map<String, dynamic> map in maps) {
      final String storedHash = map['password_hash'] as String;
      final String userId = map['id'] as String;

      final bool isValid = await verifyAndUpdatePassword(userId, password, storedHash);
      if (isValid) {
        return User.fromJson(map);
      }
    }

    return null;
  }

  Future<User> createUser({
    required String fullName,
    required String phone,
    String? email,
    String? sicilNo,
    required String password,
    required String role,
  }) async {
    final Database db = await instance.database;
    final String userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final String passwordHash = hashPassword(password);
    final String createdAt = DateTime.now().toIso8601String();

    final Map<String, dynamic> row = <String, dynamic>{
      'id': userId,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'sicil_no': sicilNo?.trim().isEmpty == true ? null : sicilNo?.trim(),
      'password_hash': passwordHash,
      'role': role,
      'signature_path': null,
      'is_active': 1,
      'created_at': createdAt,
    };

    await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.fail);

    return User(
      id: userId,
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      sicilNo: sicilNo?.trim().isEmpty == true ? null : sicilNo?.trim(),
      role: role,
      isActive: true,
      hasSignature: false,
    );
  }

  /// Update user details by Admin (parameterized SQL)
  Future<bool> updateUser({
    required String id,
    required String fullName,
    required String phone,
    String? email,
    String? sicilNo,
    required String role,
    String? newPassword,
  }) async {
    final Database db = await instance.database;

    // Check phone uniqueness against other users
    final List<Map<String, dynamic>> phoneConflict = await db.query(
      'users',
      where: 'phone = ? AND id != ?',
      whereArgs: <dynamic>[phone.trim(), id],
    );
    if (phoneConflict.isNotEmpty) {
      throw Exception('Bu telefon numarası başka bir kullanıcı tarafından kullanılıyor.');
    }

    final Map<String, dynamic> row = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'sicil_no': sicilNo?.trim().isEmpty == true ? null : sicilNo?.trim(),
      'role': role,
    };

    if (newPassword != null && newPassword.isNotEmpty) {
      row['password_hash'] = hashPassword(newPassword);
    }

    final int count = await db.update(
      'users',
      row,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
    return count > 0;
  }

  /// Delete user by ID (parameterized SQL).
  /// Note: Past reports remain intact as creator_display_name is stored in reports table.
  Future<bool> deleteUser(String userId) async {
    final Database db = await instance.database;
    final int count = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: <dynamic>[userId],
    );
    return count > 0;
  }

  /// Get active admin count in system
  Future<int> getAdminCount() async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE role = ? AND is_active = 1',
      <dynamic>['admin'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> updateUserPasswordHash(String userId, String newBcryptHash) async {
    final Database db = await instance.database;
    final int count = await db.update(
      'users',
      <String, dynamic>{'password_hash': newBcryptHash},
      where: 'id = ?',
      whereArgs: <dynamic>[userId],
    );
    return count > 0;
  }

  Future<bool> updateUserPassword(String userId, String newPassword) async {
    final String newBcryptHash = hashPassword(newPassword);
    return await updateUserPasswordHash(userId, newBcryptHash);
  }

  Future<bool> updateUserSignature(String userId, String signaturePath) async {
    final Database db = await instance.database;
    final int count = await db.update(
      'users',
      <String, dynamic>{'signature_path': signaturePath},
      where: 'id = ?',
      whereArgs: <dynamic>[userId],
    );
    return count > 0;
  }

  Future<String?> getUserSignaturePath(String userId) async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      columns: <String>['signature_path'],
      where: 'id = ?',
      whereArgs: <dynamic>[userId],
    );

    if (maps.isNotEmpty) {
      return maps.first['signature_path'] as String?;
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((Map<String, dynamic> m) => User.fromJson(m)).toList();
  }

  // ---------------- REPORT OPERATIONS (PARAMETERIZED SQL) ----------------

  Future<List<Report>> getReports({String? statusFilter}) async {
    final Database db = await instance.database;
    final String? where = statusFilter != null ? 'status = ?' : null;
    final List<dynamic>? whereArgs = statusFilter != null ? <dynamic>[statusFilter] : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'reports',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );

    return maps.map((Map<String, dynamic> map) {
      final Map<String, dynamic> mutableMap = Map<String, dynamic>.from(map);
      if (mutableMap['data_json'] is String) {
        try {
          mutableMap['data_json'] = jsonDecode(mutableMap['data_json'] as String);
        } catch (_) {
          mutableMap['data_json'] = <String, dynamic>{};
        }
      }
      return Report.fromJson(mutableMap);
    }).toList();
  }

  Future<Report?> getReportById(String id) async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reports',
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );

    if (maps.isEmpty) return null;

    final Map<String, dynamic> mutableMap = Map<String, dynamic>.from(maps.first);
    if (mutableMap['data_json'] is String) {
      try {
        mutableMap['data_json'] = jsonDecode(mutableMap['data_json'] as String);
      } catch (_) {
        mutableMap['data_json'] = <String, dynamic>{};
      }
    }
    return Report.fromJson(mutableMap);
  }

  Future<Report> saveOrUpdateReport(Report report, {String? createdByUserId}) async {
    final Database db = await instance.database;
    final String nowStr = DateTime.now().toIso8601String();

    final Map<String, dynamic> row = <String, dynamic>{
      'id': report.id,
      'title': report.title,
      'report_type': report.reportType,
      'sub_type': report.subType,
      'transformer_type': report.transformerType,
      'customer_name': report.customerName,
      'trafo_label': report.trafoLabel,
      'status': report.status,
      'creator_display_name': report.creatorDisplayName,
      'created_by': createdByUserId,
      'data_json': jsonEncode(report.dataJson),
      'current_step': report.currentStep,
      'created_at': report.createdAt.toIso8601String(),
      'updated_at': nowStr,
      'finalized_at': report.status == 'finalized' ? nowStr : null,
    };

    await db.insert(
      'reports',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return report.copyWith(updatedAt: DateTime.parse(nowStr));
  }

  Future<bool> deleteReport(String id) async {
    final Database db = await instance.database;
    final int count = await db.delete(
      'reports',
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
    return count > 0;
  }

  // ---------------- PHOTO OPERATIONS (PARAMETERIZED SQL) ----------------

  Future<void> addReportPhoto(String reportId, String kind, String filePath) async {
    final Database db = await instance.database;
    final String id = 'pho_${DateTime.now().millisecondsSinceEpoch}_${kind}';

    await db.insert(
      'report_photos',
      <String, dynamic>{
        'id': id,
        'report_id': reportId,
        'kind': kind,
        'file_path': filePath,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, String>>> getReportPhotos(String reportId) async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'report_photos',
      where: 'report_id = ?',
      whereArgs: <dynamic>[reportId],
      orderBy: 'created_at ASC',
    );

    return maps.map((Map<String, dynamic> m) => <String, String>{
      'id': m['id'] as String,
      'kind': m['kind'] as String,
      'file_path': m['file_path'] as String,
    }).toList();
  }

  Future<void> deleteReportPhoto(String photoId) async {
    final Database db = await instance.database;
    await db.delete('report_photos', where: 'id = ?', whereArgs: <dynamic>[photoId]);
  }
}
