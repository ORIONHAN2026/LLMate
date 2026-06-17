import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'isar_models.dart';

/// Isar 数据库服务（单例）
///
/// 使用方式：
/// ```dart
/// final isarService = IsarService.instance;
/// await isarService.initialize();
/// ```
class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  static IsarService get instance => _instance;
  IsarService._internal();

  Isar? _isar;
  Isar get isar {
    if (_isar == null) {
      throw StateError('IsarService 未初始化，请先调用 initialize()');
    }
    return _isar!;
  }

  bool get isInitialized => _isar != null;

  /// 初始化 Isar 数据库
  Future<void> initialize() async {
    if (_isar != null) return;

    // Isar 数据库存储到 ~/.llmwork/isar
    final home = Platform.environment['HOME'] ?? 
                 Platform.environment['USERPROFILE'] ?? 
                 '.';
    final rootDir = path.join(home, '.llmwork', 'isar');
    await Directory(rootDir).create(recursive: true);

    try {
      _isar = await Isar.open(
        [
          IsarChatModelSchema,
          IsarChatSessionSchema,
          IsarChatMessageSchema,
          IsarMcpServiceSchema,
          IsarSettingsSchema,
          IsarVendorKeySchema,
        ],
        directory: rootDir,
        inspector: kDebugMode,
      );

      debugPrint('✅ Isar 数据库初始化完成: $rootDir');
    } catch (e) {
      final errMsg = e.toString();
      debugPrint('⚠️ Isar 数据库打开失败: $errMsg');

      // 仅在明确的 schema 版本不匹配时才重建
      final isSchemaMismatch =
          errMsg.contains('version') ||
          errMsg.contains('schema') ||
          errMsg.contains('IsarError') ||
          errMsg.contains('mismatch');

      if (!isSchemaMismatch) {
        debugPrint('❌ Isar 数据库错误（非 schema 问题），无法自动恢复: $errMsg');
        rethrow;
      }

      // Schema 不匹配：备份旧库再重建
      debugPrint('⚠️ Isar 数据库 schema 不匹配，备份旧库并重建...');
      String? backupPath;
      try {
        final dbDir = Directory(rootDir);
        if (await dbDir.exists()) {
          // 备份到带时间戳的备份文件夹
          backupPath = '${rootDir}_backup_${DateTime.now().millisecondsSinceEpoch}';
          await dbDir.rename(backupPath);
          debugPrint('📦 旧数据库已备份到: $backupPath');
          // 确保目录存在（重建时需要）
          await Directory(rootDir).create(recursive: true);
        }

        // 重新打开数据库（Isar 会自动创建新库）
        _isar = await Isar.open(
          [
            IsarChatModelSchema,
            IsarChatSessionSchema,
            IsarChatMessageSchema,
            IsarMcpServiceSchema,
            IsarSettingsSchema,
            IsarVendorKeySchema,
          ],
          directory: rootDir,
          inspector: kDebugMode,
        );
        debugPrint('✅ Isar 数据库重建完成');

        // 尝试从备份恢复数据
        if (backupPath != null) {
          final recovered = await _tryRecoverFromBackup(backupPath);
          if (recovered) {
            debugPrint('🎉 已从备份自动恢复数据');
          } else {
            // 备份 schema 不兼容，记录路径供手动恢复
            await _storeBackupInfo(backupPath);
            debugPrint('💡 备份数据保留在 $backupPath，可手动恢复');
          }
        }
      } catch (e2) {
        debugPrint('❌ Isar 数据库重建失败: $e2');
        rethrow;
      }
    }

  }

  // ── 数据库备份与恢复 ──

  /// 查找最新的备份目录
  static Future<String?> findLatestBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final parent = Directory(dir.path);
    if (!parent.existsSync()) return null;
    final backups = parent
        .listSync()
        .whereType<Directory>()
        .where((d) {
          final name = d.path.split('/').last;
          return name.startsWith('chathub_isar_backup_');
        })
        .map((d) => d.path)
        .toList();
    if (backups.isEmpty) return null;
    backups.sort((a, b) => b.compareTo(a)); // 最新优先
    return backups.first;
  }

  /// 列出所有备份（返回路径列表，最新在前）
  static Future<List<String>> listBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final parent = Directory(dir.path);
    if (!parent.existsSync()) return [];
    final backups = parent
        .listSync()
        .whereType<Directory>()
        .where((d) {
          final name = d.path.split('/').last;
          return name.startsWith('chathub_isar_backup_');
        })
        .map((d) => d.path)
        .toList();
    backups.sort((a, b) => b.compareTo(a));
    return backups;
  }

  /// 检查当前数据库是否为空
  Future<bool> _isDatabaseEmpty() async {
    final modelCount = await isar.isarChatModels.count();
    final sessionCount = await isar.isarChatSessions.count();
    final mcpCount = await isar.isarMcpServices.count();
    return modelCount == 0 && sessionCount == 0 && mcpCount == 0;
  }

  /// 尝试从备份 Isar 数据库恢复数据到当前数据库
  Future<bool> _tryRecoverFromBackup(String backupPath) async {
    // 只有当前数据库为空时才恢复，避免重复数据
    if (!await _isDatabaseEmpty()) {
      debugPrint('📦 当前数据库非空，跳过备份恢复');
      return false;
    }

    try {
      // 尝试用当前 schema 打开备份库
      final backupIsar = await Isar.open(
        [
          IsarChatModelSchema,
          IsarChatSessionSchema,
          IsarChatMessageSchema,
          IsarMcpServiceSchema,
          IsarSettingsSchema,
          IsarVendorKeySchema,
        ],
        directory: backupPath,
        inspector: false,
      );

      debugPrint('🔍 备份数据库可打开，开始迁移数据...');

      await isar.writeTxn(() async {
        // 迁移模型
        final models = await backupIsar.isarChatModels.where().findAll();
        if (models.isNotEmpty) {
          await isar.isarChatModels.putAll(models);
          debugPrint('   ✅ 恢复模型: ${models.length} 条');
        }

        // 迁移会话（清除运行时状态）
        final sessions = await backupIsar.isarChatSessions.where().findAll();
        if (sessions.isNotEmpty) {
          for (final s in sessions) {
            s.isSending = false;
            s.shouldStopResponse = false;
            s.isCurrent = false;
          }
          await isar.isarChatSessions.putAll(sessions);
          debugPrint('   ✅ 恢复会话: ${sessions.length} 条');
        }

        // 迁移 MCP 服务
        final mcps = await backupIsar.isarMcpServices.where().findAll();
        if (mcps.isNotEmpty) {
          await isar.isarMcpServices.putAll(mcps);
          debugPrint('   ✅ 恢复 MCP 服务: ${mcps.length} 条');
        }

        // 迁移设置
        final settings = await backupIsar.isarSettings.where().findAll();
        if (settings.isNotEmpty) {
          await isar.isarSettings.putAll(settings);
          debugPrint('   ✅ 恢复设置: ${settings.length} 条');
        }

        // 迁移供应商 API 密钥
        final vendorKeys = await backupIsar.isarVendorKeys.where().findAll();
        if (vendorKeys.isNotEmpty) {
          await isar.isarVendorKeys.putAll(vendorKeys);
          debugPrint('   ✅ 恢复供应商密钥: ${vendorKeys.length} 条');
        }
      });

      await backupIsar.close();
      return true;
    } catch (e) {
      debugPrint('⚠️ 无法打开备份数据库（schema 不兼容，需手动恢复）: $e');
      return false;
    }
  }

  /// 记录备份信息到 SharedPreferences，供 UI 层展示
  static Future<void> _storeBackupInfo(String backupPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('isar_backups') ?? [];
      if (!existing.contains(backupPath)) {
        existing.add(backupPath);
      }
      await prefs.setStringList('isar_backups', existing);
    } catch (e) {
      debugPrint('⚠️ 保存备份信息失败: $e');
    }
  }

  /// 获取所有备份路径（供 UI 层调用）
  static Future<List<String>> getBackupPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('isar_backups') ?? [];
    } catch (e) {
      return [];
    }
  }

  /// 清除备份记录（备份目录删除后调用）
  static Future<void> clearBackupRecord(String backupPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('isar_backups') ?? [];
      existing.remove(backupPath);
      await prefs.setStringList('isar_backups', existing);
    } catch (e) {
      debugPrint('⚠️ 清除备份记录失败: $e');
    }
  }

  // ── 供应商 API 密钥 CRUD ──

  /// 获取供应商 API 密钥
  static Future<String?> getVendorKey(String vendorId) async {
    final isar = instance.isar;
    final record = await isar.isarVendorKeys.getByVendorId(vendorId);
    return record?.apiKey;
  }

  /// 保存供应商 API 密钥（插入或更新）
  static Future<void> saveVendorKey(String vendorId, String apiKey) async {
    final isar = instance.isar;
    await isar.writeTxn(() async {
      final existing = await isar.isarVendorKeys.getByVendorId(vendorId);
      if (existing != null) {
        existing.apiKey = apiKey;
        existing.updatedAt = DateTime.now();
        await isar.isarVendorKeys.put(existing);
      } else {
        await isar.isarVendorKeys.put(IsarVendorKey()
          ..vendorId = vendorId
          ..apiKey = apiKey
          ..updatedAt = DateTime.now());
      }
    });
  }

  /// 删除供应商 API 密钥
  static Future<void> deleteVendorKey(String vendorId) async {
    final isar = instance.isar;
    await isar.writeTxn(() async {
      final existing = await isar.isarVendorKeys.getByVendorId(vendorId);
      if (existing != null) {
        await isar.isarVendorKeys.delete(existing.id);
      }
    });
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }
}
