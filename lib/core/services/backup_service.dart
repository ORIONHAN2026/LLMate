import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../controllers/audit_controller.dart';
import '../../data/database.dart';
import '../http/local_http_service.dart';
import 'storage_paths.dart';

class BackupService {
  BackupService._();

  static const String extension = 'llmate-backup';
  static const int backupVersion = 1;

  static String defaultFileName() {
    return 'llmate-backup-${_timestamp()}.$extension';
  }

  static String automaticFileName() {
    return 'llmate-auto-backup-${_timestamp()}.$extension';
  }

  static String _timestamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  static String defaultBackupDirectory() =>
      p.join(StoragePaths.home, '.llmate_backups');

  static Future<File> createFullBackup({
    required String outputPath,
    bool includeLogs = true,
    bool includeSsl = true,
  }) async {
    await StoragePaths.ensureRoot();
    final root = Directory(StoragePaths.root);
    if (!await root.exists()) {
      throw StateError('LLMate 数据目录不存在: ${StoragePaths.root}');
    }

    final tempDir = await Directory.systemTemp.createTemp('llmate-backup-');
    try {
      await _writeManifest(
        Directory(tempDir.path),
        includeLogs: includeLogs,
        includeSsl: includeSsl,
      );
      final dataDir = Directory(p.join(tempDir.path, 'data'));
      await dataDir.create(recursive: true);

      await _copyDirectory(
        root,
        dataDir,
        includeLogs: includeLogs,
        includeSsl: includeSsl,
      );

      final outFile = File(outputPath);
      await outFile.parent.create(recursive: true);
      if (await outFile.exists()) {
        await outFile.delete();
      }

      final encoder = ZipFileEncoder();
      encoder.create(outFile.path);
      encoder.addDirectory(tempDir, includeDirName: false);
      encoder.close();
      return outFile;
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  static Future<File> createAutomaticBackup({
    required String outputDirectory,
    int keepLatest = 7,
  }) async {
    final dir = Directory(outputDirectory);
    await dir.create(recursive: true);
    final file = await createFullBackup(
      outputPath: p.join(dir.path, automaticFileName()),
    );
    await pruneAutomaticBackups(
      outputDirectory: dir.path,
      keepLatest: keepLatest,
    );
    return file;
  }

  static Future<void> pruneAutomaticBackups({
    required String outputDirectory,
    int keepLatest = 7,
  }) async {
    if (keepLatest <= 0) return;

    final dir = Directory(outputDirectory);
    if (!await dir.exists()) return;

    final files = <File>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('llmate-auto-backup-') &&
          name.endsWith('.$extension')) {
        files.add(entity);
      }
    }

    files.sort((a, b) {
      final bTime = b.lastModifiedSync();
      final aTime = a.lastModifiedSync();
      return bTime.compareTo(aTime);
    });

    for (final file in files.skip(keepLatest)) {
      try {
        await file.delete();
      } catch (_) {
        // 旧备份清理失败不影响本次自动备份结果。
      }
    }
  }

  static Future<BackupManifest> readManifest(String backupPath) async {
    final archive = ZipDecoder().decodeBytes(
      await File(backupPath).readAsBytes(),
    );
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null || !manifestFile.isFile) {
      throw const FormatException('备份文件缺少 manifest.json');
    }
    final raw = utf8.decode(manifestFile.content as List<int>);
    return BackupManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<RestoreResult> restoreFullBackup(
    String backupPath, {
    String? safetyBackupDirectory,
  }) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw StateError('备份文件不存在: $backupPath');
    }

    final manifest = await readManifest(backupPath);
    if (manifest.app != 'LLMate' || manifest.backupVersion > backupVersion) {
      throw FormatException('不支持的备份文件版本: ${manifest.backupVersion}');
    }

    final safetyBackupDir = Directory(
      safetyBackupDirectory ?? defaultBackupDirectory(),
    );
    await safetyBackupDir.create(recursive: true);
    final safetyBackupPath = p.join(safetyBackupDir.path, defaultFileName());
    final safetyBackup = await createFullBackup(outputPath: safetyBackupPath);

    final restoreTemp = await Directory.systemTemp.createTemp(
      'llmate-restore-',
    );
    try {
      await _extractBackup(backupFile, restoreTemp);
      final dataDir = Directory(p.join(restoreTemp.path, 'data'));
      if (!await dataDir.exists()) {
        throw const FormatException('备份文件缺少 data 目录');
      }

      await LocalHttpService.stop();
      await AuditController.instance.storage.close();
      await appDatabase.close();

      final root = Directory(StoragePaths.root);
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
      await root.create(recursive: true);
      await _copyDirectory(dataDir, root);

      return RestoreResult(
        manifest: manifest,
        safetyBackupPath: safetyBackup.path,
      );
    } finally {
      if (await restoreTemp.exists()) {
        await restoreTemp.delete(recursive: true);
      }
    }
  }

  static Future<void> _writeManifest(
    Directory dir, {
    required bool includeLogs,
    required bool includeSsl,
  }) async {
    final manifest = {
      'app': 'LLMate',
      'backupVersion': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'included': {
        'mainDatabase':
            await File(p.join(StoragePaths.root, 'llmate.sqlite')).exists(),
        'auditDatabase':
            await File(p.join(StoragePaths.root, 'audit.duckdb')).exists(),
        'ssl': includeSsl,
        'logs': includeLogs,
      },
    };
    await File(
      p.join(dir.path, 'manifest.json'),
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory target, {
    bool includeLogs = true,
    bool includeSsl = true,
  }) async {
    await target.create(recursive: true);
    await for (final entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final name = p.basename(entity.path);
      if (!includeLogs && name == 'log') continue;
      if (!includeSsl && name == 'ssl') continue;
      if (name == '.DS_Store') continue;

      final newPath = p.join(target.path, name);
      if (entity is Directory) {
        await _copyDirectory(
          entity,
          Directory(newPath),
          includeLogs: includeLogs,
          includeSsl: includeSsl,
        );
      } else if (entity is File) {
        await File(newPath).parent.create(recursive: true);
        await entity.copy(newPath);
      }
    }
  }

  static Future<void> _extractBackup(File backupFile, Directory target) async {
    final archive = ZipDecoder().decodeBytes(await backupFile.readAsBytes());
    final targetRoot = p.normalize(target.absolute.path);
    for (final file in archive.files) {
      final normalized = p.normalize(p.join(target.path, file.name));
      if (!p.isWithin(targetRoot, normalized) && normalized != targetRoot) {
        throw const FormatException('备份文件包含非法路径');
      }
      if (file.isFile) {
        final out = File(normalized);
        await out.parent.create(recursive: true);
        await out.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(normalized).create(recursive: true);
      }
    }
  }
}

class BackupManifest {
  final String app;
  final int backupVersion;
  final DateTime createdAt;
  final String platform;
  final Map<String, dynamic> included;

  const BackupManifest({
    required this.app,
    required this.backupVersion,
    required this.createdAt,
    required this.platform,
    required this.included,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      app: json['app'] as String? ?? '',
      backupVersion: (json['backupVersion'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      platform: json['platform'] as String? ?? '',
      included:
          json['included'] is Map<String, dynamic>
              ? json['included'] as Map<String, dynamic>
              : <String, dynamic>{},
    );
  }
}

class RestoreResult {
  final BackupManifest manifest;
  final String safetyBackupPath;

  const RestoreResult({required this.manifest, required this.safetyBackupPath});
}
