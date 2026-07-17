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
/// 负责消息的持久化与读取，不涉及会话元数据的管理
/// （会话元数据仍由 [SessionController] 负责）。
///
/// 设计原则：
///   - 单条消息提供「增 / 删 / 改 / 查」能力（[addMessage] /
///     [deleteMessage] / [updateMessage] / [getMessage]）。
///   - 多个消息只提供「载入 / 查询」能力（[loadMessages]），
///     不再提供批量写入 / 批量替换。需要变更多条消息时，
///     由调用方逐条调用单条方法完成。
///
/// 数据存储在 sembast 数据库 `~/.llmate/messages.db`
/// （store 名 `messages`，每个 record 的 key 为 sessionId，
/// 其 `messages` 字段为该会话的消息列表）。
class MessageController extends GetxController {
  static MessageController get instance => Get.find<MessageController>();

  /// 消息数据库路径：~/.llmate/messages.db
  static String get _dbPath => p.join(StoragePaths.root, 'messages.db');

  /// sembast store 名称（每个 record 的 key 为 sessionId）
  static const String _storeName = 'messages';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    return _db!;
  }

  /// 将消息 Map 解析为 [ChatMessage]，解析失败返回 null
  static ChatMessage? _parseMessage(Map<String, dynamic> m) {
    try {
      return ChatMessage.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  /// 读取会话的消息列表（内部辅助）
  Future<List<Map<String, dynamic>>> _readList(
    Database db,
    String sessionId,
  ) async {
    final record = await _store.record(sessionId).get(db)
        as Map<String, dynamic>?;
    if (record != null && record['messages'] is List) {
      return (record['messages'] as List).cast<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// 将单条消息写入会话的消息列表（按 msgId upsert，内部辅助）
  Future<void> _upsertMessage(Database db, ChatMessage message) async {
    final sessionId = message.sessionId;
    if (sessionId == null || message.msgId.isEmpty) return;
    final list = await _readList(db, sessionId);
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
  }

  // ==================== 单条消息：增 / 删 / 改 / 查 ====================

  /// 新增单条消息（按 msgId upsert 到对应会话的消息列表）
  Future<void> addMessage(ChatMessage message) async {
    try {
      final db = await _database;
      await _upsertMessage(db, message);
    } catch (e) {
      debugPrint('新增单条消息失败: $e');
    }
  }

  /// 更新单条消息（按 msgId upsert 到对应会话的消息列表）
  Future<void> updateMessage(ChatMessage message) async {
    try {
      final db = await _database;
      await _upsertMessage(db, message);
    } catch (e) {
      debugPrint('更新单条消息失败: $e');
    }
  }

  /// 删除单条消息（按 msgId 从对应会话的消息列表移除）
  Future<void> deleteMessage(ChatMessage message) async {
    final sessionId = message.sessionId;
    if (sessionId == null || message.msgId.isEmpty) return;
    try {
      final db = await _database;
      final list = await _readList(db, sessionId);
      final newList = list.where((m) => m['id'] != message.msgId).toList();
      await _store.record(sessionId).put(db, {
        'sessionId': sessionId,
        'messages': newList,
      });
    } catch (e) {
      debugPrint('删除单条消息 DB 失败: $e');
    }
  }

  /// 查询单条消息（按 sessionId + msgId）
  Future<ChatMessage?> getMessage(String sessionId, String msgId) async {
    if (sessionId.isEmpty || msgId.isEmpty) return null;
    try {
      final db = await _database;
      final list = await _readList(db, sessionId);
      for (final m in list) {
        if (m['id'] == msgId) return _parseMessage(m);
      }
      return null;
    } catch (e) {
      debugPrint('查询单条消息失败: $e');
      return null;
    }
  }

  // ==================== 多个消息：仅载入 / 查询 ====================

  /// 加载指定会话的消息列表（从 messages.db 读取）
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    try {
      final db = await _database;
      final list = await _readList(db, sessionId);
      return list.map(_parseMessage).whereType<ChatMessage>().toList();
    } catch (e) {
      debugPrint('加载会话消息失败: $e');
      return [];
    }
  }

  /// 清空指定会话的全部消息（仅清空消息列表，保留会话与目录；用于"清除历史记录"）
  Future<void> clearMessages(String sessionId) async {
    if (sessionId.isEmpty) return;
    try {
      final db = await _database;
      await _store.record(sessionId).put(db, {
        'sessionId': sessionId,
        'messages': <Map<String, dynamic>>[],
      });
    } catch (e) {
      debugPrint('清空会话消息失败: $e');
    }
  }

  /// 删除指定会话的全部消息（并清理会话目录 memory/mcp/business 等，用于删除会话）
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
}
