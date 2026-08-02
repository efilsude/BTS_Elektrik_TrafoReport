import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'storage_service.dart';

class BackupService {
  /// Create a compressed .zip backup of SQLite DB, photos, and signatures, then trigger native Share sheet
  Future<File?> createBackupAndShare() async {
    try {
      final Archive archive = Archive();

      // 1. Add SQLite Database file
      final String dbDir = await getDatabasesPath();
      final String dbPath = p.join(dbDir, 'traforeport_local.db');
      final File dbFile = File(dbPath);

      if (await dbFile.exists()) {
        final List<int> dbBytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile('traforeport_local.db', dbBytes.length, dbBytes));
      }

      // 2. Add App Documents directory (photos, signatures)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      if (await appDocDir.exists()) {
        final List<FileSystemEntity> entities = appDocDir.listSync(recursive: true);
        for (final FileSystemEntity entity in entities) {
          if (entity is File) {
            final String relativePath = p.relative(entity.path, from: appDocDir.path);
            // Skip existing backup zip files to avoid recursion
            if (relativePath.startsWith('backups') || relativePath.endsWith('.zip')) continue;

            final List<int> fileBytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile('documents/$relativePath', fileBytes.length, fileBytes));
          }
        }
      }

      // 3. Encode to Zip format
      final ZipEncoder encoder = ZipEncoder();
      final List<int>? zipData = encoder.encode(archive);
      if (zipData == null || zipData.isEmpty) {
        throw Exception('Zip dosyası oluşturulamadı.');
      }

      // 4. Save Zip to app's backup directory
      final Directory backupDir = Directory(p.join(appDocDir.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String zipPath = p.join(backupDir.path, 'traforeport_backup_$timestamp.zip');
      final File zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);

      // 5. Trigger Android Native Share Sheet
      await Share.shareXFiles(
        <XFile>[XFile(zipFile.path)],
        text: 'BTS Elektrik TrafoReport Yerel Veri Yedeği ($timestamp)',
      );

      return zipFile;
    } catch (e) {
      debugPrint('[TrafoReport] Yedek alma hatası: $e');
      rethrow;
    }
  }

  /// Restore local database and files from a user-selected .zip file
  Future<bool> restoreBackup(File zipFile) async {
    try {
      if (!await zipFile.exists()) {
        throw Exception('Yedek dosyası bulunamadı.');
      }

      final List<int> bytes = await zipFile.readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      // Check if archive contains database
      final bool hasDb = archive.any((ArchiveFile f) => f.name == 'traforeport_local.db');
      if (!hasDb) {
        throw Exception('Geçersiz yedek dosyası: Veritabanı (traforeport_local.db) bulunamadı.');
      }

      // 1. Safely close database connection
      await DatabaseHelper.instance.closeDatabase();

      // 2. Restore SQLite database file
      final String dbDir = await getDatabasesPath();
      final String targetDbPath = p.join(dbDir, 'traforeport_local.db');

      for (final ArchiveFile file in archive) {
        if (file.name == 'traforeport_local.db') {
          final List<int> content = file.content as List<int>;
          await File(targetDbPath).writeAsBytes(content);
        }
      }

      // 3. Restore document files (photos/signatures)
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      for (final ArchiveFile file in archive) {
        if (file.name.startsWith('documents/')) {
          final String relativePath = file.name.substring('documents/'.length);
          if (relativePath.isEmpty) continue;

          final String targetPath = p.join(appDocDir.path, relativePath);
          final File targetFile = File(targetPath);

          if (file.isFile) {
            await targetFile.parent.create(recursive: true);
            await targetFile.writeAsBytes(file.content as List<int>);
          }
        }
      }

      // 4. Re-open SQLite connection
      await DatabaseHelper.instance.database;

      // 5. Clear active session so user re-logs in with restored database
      await StorageService().clearAll();

      return true;
    } catch (e) {
      debugPrint('[TrafoReport] Yedek geri yükleme hatası: $e');
      rethrow;
    }
  }
}
