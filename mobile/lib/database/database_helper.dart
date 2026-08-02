import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('traforeport_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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

  // Password hashing utility
  static String hashPassword(String password) {
    const String salt = 'TrafoReport_Local_Salt_2026';
    final List<int> bytes = utf8.encode(password + salt);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
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

  Future<User?> authenticateUser(String identifier, String password) async {
    final Database db = await instance.database;
    final String cleanIdentifier = identifier.trim().toLowerCase();
    final String passwordHash = hashPassword(password);

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: '(LOWER(phone) = ? OR LOWER(email) = ?) AND password_hash = ? AND is_active = 1',
      whereArgs: <dynamic>[cleanIdentifier, cleanIdentifier, passwordHash],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
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

  Future<bool> updateUserPassword(String userId, String newPassword) async {
    final Database db = await instance.database;
    final String newHash = hashPassword(newPassword);

    final int count = await db.update(
      'users',
      <String, dynamic>{'password_hash': newHash},
      where: 'id = ?',
      whereArgs: <dynamic>[userId],
    );

    return count > 0;
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

  // ---------------- REPORT OPERATIONS ----------------

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
      // parse data_json
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

  // ---------------- PHOTO OPERATIONS ----------------

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
