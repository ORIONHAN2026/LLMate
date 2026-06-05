import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
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

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/chathub_isar';

    // 确保目录存在
    await Directory(dbPath).create(recursive: true);

    try {
      _isar = await Isar.open(
        [
          IsarChatModelSchema,
          IsarChatSessionSchema,
          IsarMcpServiceSchema,
          IsarSettingsSchema,
          IsarVendorKeySchema,
        ],
        directory: dbPath,
        inspector: kDebugMode,
      );

      debugPrint('✅ Isar 数据库初始化完成: $dbPath');
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
        final dbDir = Directory(dbPath);
        if (dbDir.existsSync()) {
          // 备份到同目录下带时间戳的备份文件夹
          backupPath = '${dir.path}/chathub_isar_backup_${DateTime.now().millisecondsSinceEpoch}';
          await dbDir.rename(backupPath);
          debugPrint('📦 旧数据库已备份到: $backupPath');
          await Directory(dbPath).create(recursive: true);
        }
        _isar = await Isar.open(
          [
            IsarChatModelSchema,
            IsarChatSessionSchema,
            IsarMcpServiceSchema,
            IsarSettingsSchema,
            IsarVendorKeySchema,
          ],
          directory: dbPath,
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

    // 迁移旧的 SharedPreferences 数据
    await _migrateFromSharedPreferences();
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

  // ── SharedPreferences 迁移 ──

  /// 从 SharedPreferences 迁移数据到 Isar
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migratedKey = 'isar_migration_done';

      if (prefs.getBool(migratedKey) == true) {
        debugPrint('📦 数据迁移已完成，跳过');
        return;
      }

      debugPrint('🔄 开始从 SharedPreferences 迁移数据到 Isar...');
      int migratedCount = 0;

      // 迁移模型
      final modelsJson = prefs.getString('ai_models');
      if (modelsJson != null && modelsJson.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(modelsJson);
          final isarModels = list.map((m) {
            final map = m as Map<String, dynamic>;
            return IsarChatModel()
              ..modelId = (map['modelId'] as String?) ?? ''
              ..name = (map['name'] as String?) ?? ''
              ..model = (map['model'] as String?) ?? (map['fullName'] as String?) ?? ''
              ..status = (map['status'] as String?) ?? 'inactive'
              ..type = map['type'] as String?
              ..provider = map['provider'] as String?
              ..apiKey = map['apiKey'] as String?
              ..apiUrl = map['apiUrl'] as String?
              ..createdAt = map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null
              ..updatedAt = map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null
              ..description = map['description'] as String?
              ..chatSettingsJson = map['chatSettings'] != null ? jsonEncode(map['chatSettings']) : null
              ..mcpServicesJson = map['mcpServices'] != null ? jsonEncode(map['mcpServices']) : null
              ..chatCommandsJson = map['chatCommands'] != null ? jsonEncode(map['chatCommands']) : null
              ..skillsJson = map['skills'] != null ? jsonEncode(map['skills']) : null;
          }).toList();

          await isar.writeTxn(() async {
            await isar.isarChatModels.putAll(isarModels);
          });
          migratedCount += isarModels.length;
          debugPrint('   ✅ 迁移模型: ${isarModels.length} 条');
        } catch (e) {
          debugPrint('   ⚠️ 迁移模型失败: $e');
        }
      }

      // 迁移会话
      final sessionsJson = prefs.getString('chat_sessions');
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(sessionsJson);
          final isarSessions = list.map((s) {
            final map = s as Map<String, dynamic>;
            final sessionId = (map['id'] as String?) ?? '';

            return IsarChatSession()
              ..sessionId = sessionId
              ..name = (map['name'] as String?) ?? '新会话'
              ..createdAt = map['createdAt'] != null
                  ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
                  : DateTime.now()
              ..isFavorite = (map['isFavorite'] as bool?) ?? false
              ..isSending = false
              ..shouldStopResponse = false
              ..scrollPosition = (map['scrollPosition'] as num?)?.toDouble() ?? 0.0
              ..inputContent = (map['inputContent'] as String?) ?? ''
              ..lastSelectedDirectory = map['lastSelectedDirectory'] as String?
              ..messagesJson = map['messages'] != null ? jsonEncode(map['messages']) : '[]'
              ..chatModelJson = map['chatModel'] != null ? jsonEncode(map['chatModel']) : null
              ..modelId = map['modelId'] as String? ??
                  (map['chatModel'] is Map
                      ? (map['chatModel'] as Map)['modelId'] as String?
                      : null)
              ..mcpServerJson = map['mcpServer'] != null ? jsonEncode(map['mcpServer']) : null
              ..skillJson = map['skill'] != null ? jsonEncode(map['skill']) : null
              ..attachmentsJson = map['attachments'] != null ? jsonEncode(map['attachments']) : null
              ..sessionQuickCommandsJson = map['sessionQuickCommands'] != null
                  ? jsonEncode(map['sessionQuickCommands'])
                  : null
              ..isCurrent = false;
          }).toList();

          await isar.writeTxn(() async {
            await isar.isarChatSessions.putAll(isarSessions);
          });
          migratedCount += isarSessions.length;
          debugPrint('   ✅ 迁移会话: ${isarSessions.length} 条');
        } catch (e) {
          debugPrint('   ⚠️ 迁移会话失败: $e');
        }
      }

      // 迁移当前会话标记
      final currentJson = prefs.getString('chat_current_session');
      if (currentJson != null && currentJson.isNotEmpty) {
        try {
          final map = jsonDecode(currentJson) as Map<String, dynamic>;
          final currentId = map['id'] as String?;
          if (currentId != null) {
            await isar.writeTxn(() async {
              final session = await isar.isarChatSessions
                  .getBySessionId(currentId);
              if (session != null) {
                session.isCurrent = true;
                await isar.isarChatSessions.put(session);
              }
            });
            debugPrint('   ✅ 迁移当前会话标记: $currentId');
          }
        } catch (e) {
          debugPrint('   ⚠️ 迁移当前会话标记失败: $e');
        }
      }

      // 迁移 MCP 服务
      final mcpJson = prefs.getString('mcp_services');
      if (mcpJson != null && mcpJson.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(mcpJson);
          final isarMcps = list.map((m) {
            final map = m as Map<String, dynamic>;
            final name = (map['name'] as String?) ?? '';
            final mcpId = (map['mcpId'] as String?) ?? name;
            return IsarMcpService()
              ..mcpId = mcpId
              ..content = jsonEncode(map);
          }).toList();

          await isar.writeTxn(() async {
            await isar.isarMcpServices.putAll(isarMcps);
          });
          migratedCount += isarMcps.length;
          debugPrint('   ✅ 迁移 MCP 服务: ${isarMcps.length} 条');
        } catch (e) {
          debugPrint('   ⚠️ 迁移 MCP 服务失败: $e');
        }
      }

      // 迁移主题设置
      final isDark = prefs.getBool('isDarkMode');
      if (isDark != null) {
        await isar.writeTxn(() async {
          await isar.isarSettings.put(IsarSettings()
            ..key = 'isDarkMode'
            ..value = isDark.toString());
        });
        migratedCount++;
        debugPrint('   ✅ 迁移主题设置: isDarkMode=$isDark');
      }

      // 迁移供应商 API 密钥（从 SharedPreferences 到 Isar）
      const vendorIds = ['aliyun', 'modelscope', 'tencent'];
      for (final vid in vendorIds) {
        final key = prefs.getString('mcp_vendor_key_$vid');
        if (key != null && key.isNotEmpty) {
          final existing = await isar.isarVendorKeys.getByVendorId(vid);
          if (existing == null) {
            await isar.writeTxn(() async {
              await isar.isarVendorKeys.put(IsarVendorKey()
                ..vendorId = vid
                ..apiKey = key
                ..updatedAt = DateTime.now());
            });
            migratedCount++;
            debugPrint('   ✅ 迁移供应商密钥: $vid');
          }
        }
      }

      // 标记迁移完成
      if (migratedCount > 0) {
        await prefs.setBool(migratedKey, true);
        debugPrint('🎉 数据迁移完成，共迁移 $migratedCount 条记录');
      } else {
        await prefs.setBool(migratedKey, true);
        debugPrint('📦 无数据需要迁移（首次安装）');
      }
    } catch (e) {
      debugPrint('❌ 数据迁移失败: $e');
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
