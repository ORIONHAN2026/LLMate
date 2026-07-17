import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../models/chat/chat_message.dart';
import '../data/file_storage.dart';
import '../data/storage_paths.dart';

/// 消息操作的独立控制器
///
/// 将原本散落在 [SessionController] 中的消息读写逻辑抽离出来，
/// 负责单个会话消息的持久化、加载、批量替换与删除，
/// 不涉及会话元数据的管理（会话元数据仍由 [SessionController] 负责）。
///
/// 存储采用「双写文件 + 读 DB」策略：
///   - 写入时：同时写入文件（[StorageService] 的 message 文件）与
///     sembast 数据库 `~/.llmate/messages.db`（store 名 `messages`）。
///   - 读取时：从 `messages.db` 读取（新项目，无文件迁移逻辑）。
class MessageController extends GetxController {
  static MessageController get instance => Get.find<MessageController>();

  /// 消息数据库路径：~/.llmate/messages.db
  static String get _dbPath => p.join(StoragePaths.root, 'messages.db');

  /// sembast store 名称（每个 record 的 key 为 sessionId）
  static const String _storeName = 'messages';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;
  static bool _migrated = false;

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    await _maybeMigrate(_db!);
    return _db!;
  }

  /// 一次性将旧版 chats/{sid}/message.json 迁移进 messages.db
  ///
  /// 仅当数据库中尚不存在同名记录时写入，避免覆盖；旧文件保留作备份。
  Future<void> _maybeMigrate(Database db) async {
    if (_migrated) return;
    _migrated = true;
    try {
      final ids = await StoragePaths.listSessionIds();
      if (ids.isEmpty) return;
      int migrated = 0;
      for (final sid in ids) {
        final list = await FileStorage.readJsonList(StoragePaths.messageFile(sid));
        if (list == null || list.isEmpty) continue;
        final existing = await _store.record(sid).get(db) as Map<String, dynamic>?;
        final hasDbData = existing != null &&
            existing['messages'] is List &&
            (existing['messages'] as List).isNotEmpty;
        if (!hasDbData) {
          await _store.record(sid).put(db, {
            'sessionId': sid,
            'messages': list,
          });
          migrated++;
        }
      }
      if (migrated > 0) {
        debugPrint('📦 [Message] 已迁移 $migrated 个会话的消息至 messages.db');
      }
    } catch (e) {
      debugPrint('⚠️ [Message] 迁移旧消息失败: $e');
    }
  }

  /// 将消息 Map 解析为 [ChatMessage]，解析失败返回 null
  static ChatMessage? _parseMessage(Map<String, dynamic> m) {
    try {
      return ChatMessage.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  // ==================== 消息持久化 ====================

  /// 持久化指定会话的全部消息（仅写入 messages.db）
  ///
  /// 若 [messages] 为空且数据库中已有数据，则跳过写入以避免空列表覆盖已有消息。
  Future<void> persistMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    final messagesJson = messages.map((m) => m.toJson()).toList();

    try {
      final db = await _database;
      if (messagesJson.isEmpty) {
        final existing =
            await _store.record(sessionId).get(db) as Map<String, dynamic>?;
        final hasDbData =
            existing != null && existing['messages'] is List &&
            (existing['messages'] as List).isNotEmpty;
        if (hasDbData) {
          debugPrint(
            '⚠️ 安全防护：跳过空消息持久化，保留 DB 已有数据 (session: $sessionId)',
          );
          return;
        }
      }
      await _store.record(sessionId).put(db, {
        'sessionId': sessionId,
        'messages': messagesJson,
      });
    } catch (e) {
      debugPrint('持久化消息到 messages.db 失败: $e');
    }
  }

  /// 加载指定会话的消息列表（从 messages.db 读取）
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    try {
      final db = await _database;
      final record = await _store.record(sessionId).get(db);

      if (record != null && record['messages'] is List) {
        final list = (record['messages'] as List).cast<Map<String, dynamic>>();
        return list
            .map(_parseMessage)
            .whereType<ChatMessage>()
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('加载会话消息失败: $e');
      return [];
    }
  }

  /// 批量替换指定会话的消息并持久化
  Future<void> updateSessionMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    await persistMessages(sessionId, messages);
  }

  /// 删除指定会话的全部消息（并清理会话目录下的其余文件：memory/mcp/business 等）
  Future<void> deleteMessagesBySession(String sessionId) async {
    try {
      final db = await _database;
      await _store.record(sessionId).delete(db);
    } catch (e) {
      debugPrint('删除会话消息 DB 失败: $e');
    }
    try {
      // 清理会话目录下的其余文件（memory.md / mcp.json / business.md）
      await FileStorage.deleteDir(StoragePaths.sessionDir(sessionId));
    } catch (e) {
      debugPrint('删除会话目录失败: $e');
    }
  }

  // ==================== 单条消息持久化 ====================

  /// 持久化单条消息（更新内存列表由调用方负责，仅写入 messages.db）
  Future<void> persistMessage(ChatMessage message) async {
    final sessionId = message.sessionId;
    if (sessionId == null) return;

    try {
      final db = await _database;
      final record = await _store.record(sessionId).get(db)
          as Map<String, dynamic>?;
      final List<Map<String, dynamic>> list;
      if (record != null && record['messages'] is List) {
        list = (record['messages'] as List).cast<Map<String, dynamic>>().toList();
      } else {
        list = [];
      }
      final idx = list.indexWhere((m) => m['id'] == message.msgId);
      final json = message.toJson();
      if (idx != -1) {
        list[idx] = json;
      } else {
        list.add(json);
      }
      await _store.record(sessionId).put(db, {
        'sessionId': sessionId,
        'messages': list,
      });
    } catch (e) {
      debugPrint('持久化单条消息到 messages.db 失败: $e');
    }
  }

  /// 从 messages.db 删除单条消息
  Future<void> deleteMessage(ChatMessage message) async {
    final sessionId = message.sessionId;
    if (sessionId == null) return;

    try {
      final db = await _database;
      final record = await _store.record(sessionId).get(db)
          as Map<String, dynamic>?;
      final List<Map<String, dynamic>> list;
      if (record != null && record['messages'] is List) {
        list = (record['messages'] as List).cast<Map<String, dynamic>>().toList();
      } else {
        list = [];
      }
      final newList = list.where((m) => m['id'] != message.msgId).toList();
      await _store.record(sessionId).put(db, {
        'sessionId': sessionId,
        'messages': newList,
      });
    } catch (e) {
      debugPrint('删除单条消息 DB 失败: $e');
    }
  }
}
