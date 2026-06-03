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
        ],
        directory: dbPath,
        inspector: kDebugMode,
      );

      debugPrint('✅ Isar 数据库初始化完成: $dbPath');
    } catch (e) {
      // Schema 不匹配（字段新增/删除） → 删除旧库重建
      debugPrint('⚠️ Isar 数据库 schema 不匹配，正在重建: $e');
      try {
        final dbDir = Directory(dbPath);
        if (dbDir.existsSync()) {
          await dbDir.delete(recursive: true);
          await dbDir.create(recursive: true);
        }
        _isar = await Isar.open(
          [
            IsarChatModelSchema,
            IsarChatSessionSchema,
            IsarMcpServiceSchema,
            IsarSettingsSchema,
          ],
          directory: dbPath,
          inspector: kDebugMode,
        );
        debugPrint('✅ Isar 数据库重建完成');
      } catch (e2) {
        debugPrint('❌ Isar 数据库重建失败: $e2');
        rethrow;
      }
    }

    // 迁移旧的 SharedPreferences 数据
    await _migrateFromSharedPreferences();
  }

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
              ..name = name
              ..command = (map['command'] as String?) ?? ''
              ..argsJson = map['args'] != null ? jsonEncode(map['args']) : '[]'
              ..envJson = map['env'] != null ? jsonEncode(map['env']) : null
              ..workingDirectory = map['workingDirectory'] as String?
              ..timeout = map['timeout'] as int?
              ..url = map['url'] as String?
              ..headersJson = map['headers'] != null ? jsonEncode(map['headers']) : null
              ..toolsJson = map['tools'] != null ? jsonEncode(map['tools']) : null
              ..lastUpdated = map['lastUpdated'] != null ? DateTime.tryParse(map['lastUpdated'].toString()) : null;
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

  /// 关闭数据库
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }
}
