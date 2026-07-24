import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/database.dart';
import '../models/chat/message.dart';

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
/// 数据统一存储在 Drift / SQLite 数据库 `~/.llmate/llmate.sqlite`
/// 的 `message_rows` 表（每个会话一行，data 为该会话的消息列表 JSON）。
class MessageController extends GetxController {
  static MessageController get instance => Get.find<MessageController>();

  // ==================== 单条消息：增 / 删 / 改 / 查 ====================

  /// 新增单条消息（按 msgId upsert 到对应会话的消息列表）
  Future<void> addMessage(ChatMessage message) async {
    try {
      await appDatabase.upsertMessage(message);
    } catch (e) {
      debugPrint('新增单条消息失败: $e');
    }
  }

  /// 更新单条消息（按 msgId upsert 到对应会话的消息列表）
  Future<void> updateMessage(ChatMessage message) async {
    try {
      await appDatabase.upsertMessage(message);
    } catch (e) {
      debugPrint('更新单条消息失败: $e');
    }
  }

  /// 删除单条消息（按 msgId 从对应会话的消息列表移除）
  Future<void> deleteMessage(ChatMessage message) async {
    final sessionId = message.sessionId;
    if (sessionId == null || message.msgId.isEmpty) return;
    try {
      await appDatabase.deleteMessageById(sessionId, message.msgId);
    } catch (e) {
      debugPrint('删除单条消息 DB 失败: $e');
    }
  }

  /// 查询单条消息（按 sessionId + msgId）
  Future<ChatMessage?> getMessage(String sessionId, String msgId) async {
    if (sessionId.isEmpty || msgId.isEmpty) return null;
    try {
      return await appDatabase.getMessage(sessionId, msgId);
    } catch (e) {
      debugPrint('查询单条消息失败: $e');
      return null;
    }
  }

  // ==================== 多个消息：仅载入 / 查询 ====================

  /// 加载指定会话的消息列表（从 SQLite 读取）
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    try {
      return await appDatabase.loadMessages(sessionId);
    } catch (e) {
      debugPrint('加载会话消息失败: $e');
      return [];
    }
  }

  /// 清空指定会话的全部消息（仅清空消息列表，保留会话与目录；用于"清除历史记录"）
  Future<void> clearMessages(String sessionId) async {
    if (sessionId.isEmpty) return;
    try {
      await appDatabase.clearMessages(sessionId);
    } catch (e) {
      debugPrint('清空会话消息失败: $e');
    }
  }

  /// 删除指定会话的全部消息（消息数据均存于数据库，无需清理磁盘文件）
  Future<void> deleteMessagesBySession(String sessionId) async {
    try {
      await appDatabase.deleteMessagesBySession(sessionId);
    } catch (e) {
      debugPrint('删除会话消息 DB 失败: $e');
    }
  }
}
