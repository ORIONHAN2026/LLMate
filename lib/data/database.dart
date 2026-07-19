import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;

import '../services/storage_paths.dart';
import '../models/audit.dart';
import '../models/chat/mcp.dart';
import '../models/chat/message.dart';
import '../models/chat/session.dart';
import '../models/chat/usage.dart';
import '../models/model.dart';

part 'database.g.dart';

// ══════════════════════════════════════════════════════════
// 表定义
// ══════════════════════════════════════════════════════════

/// 会话元数据表（消息与运行时模型对象不入库，分别由消息表与运行时解析）
class SessionRows extends Table {
  TextColumn get id => text()(); // sessionId
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  TextColumn get data => text()(); // 完整 ChatSession JSON（不含 messages / chatModel）
  @override
  Set<Column> get primaryKey => {id};
}

/// 消息表（每个会话一行，data 为该会话消息列表 JSON）
class MessageRows extends Table {
  TextColumn get sessionId => text()();
  TextColumn get data => text()(); // 消息列表 JSON
  @override
  Set<Column> get primaryKey => {sessionId};
}

/// 模型配置表
class ModelRows extends Table {
  TextColumn get id => text()(); // modelId
  TextColumn get data => text()();
  @override
  Set<Column> get primaryKey => {id};
}

/// MCP 服务配置表
class McpRows extends Table {
  TextColumn get name => text()(); // MCP 名称
  TextColumn get data => text()();
  @override
  Set<Column> get primaryKey => {name};
}

/// 设置表（单条聚合记录 key='systemSetting'）
class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get data => text()();
  @override
  Set<Column> get primaryKey => {key};
}

/// 审计日志表
class AuditRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  IntColumn get timestamp => integer()(); // 毫秒时间戳
  TextColumn get data => text()(); // 完整 AuditLog JSON
}

/// 用量明细表
class UsageRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get detailKey => text()(); // 去重键 timestamp_model_cost
  TextColumn get sessionId => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get timestamp => integer()(); // 毫秒时间戳
  TextColumn get data => text()(); // 完整 UsageDetail JSON
}

/// 供应商密钥表
class VendorKeyRows extends Table {
  TextColumn get vendorId => text()();
  TextColumn get apiKey => text()();
  TextColumn get updatedAt => text()();
  @override
  Set<Column> get primaryKey => {vendorId};
}

// ══════════════════════════════════════════════════════════
// 数据库
// ══════════════════════════════════════════════════════════

@DriftDatabase(
  tables: [
    SessionRows,
    MessageRows,
    ModelRows,
    McpRows,
    SettingRows,
    AuditRows,
    UsageRows,
    VendorKeyRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'llmate',
            native: DriftNativeOptions(databasePath: _dbPath),
          ),
        );

  /// 数据库文件完整路径：~/.llmate/llmate.sqlite
  static Future<String> _dbPath() async {
    await StoragePaths.ensureRoot();
    return p.join(StoragePaths.root, 'llmate.sqlite');
  }

  @override
  int get schemaVersion => 1;
}

/// 全局单例
final AppDatabase appDatabase = AppDatabase();

// ══════════════════════════════════════════════════════════
// 会话 DAO
// ══════════════════════════════════════════════════════════

extension SessionDao on AppDatabase {
  /// 将 ChatSession 转为可入库的 Map（去除运行时字段 messages / chatModel）
  static Map<String, dynamic> _toStorageMap(ChatSession s) {
    final map = s.toJson();
    map.remove('messages');
    map.remove('chatModel');
    return map;
  }

  Future<void> upsertSession(ChatSession session, {bool isCurrent = false}) async {
    await into(sessionRows).insertOnConflictUpdate(
      SessionRowsCompanion.insert(
        id: session.sessionId,
        isCurrent: Value(isCurrent),
        data: jsonEncode(_toStorageMap(session)),
      ),
    );
  }

  Future<void> persistSessions(List<ChatSession> sessions,
      {String? currentId}) async {
    await batch((batch) {
      for (final s in sessions) {
        batch.insert(
          sessionRows,
          SessionRowsCompanion.insert(
            id: s.sessionId,
            isCurrent: Value(s.sessionId == currentId),
            data: jsonEncode(_toStorageMap(s)),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<ChatSession>> getAllSessions() async {
    final rows = await select(sessionRows).get();
    return rows.map((r) {
      final map = jsonDecode(r.data) as Map<String, dynamic>;
      return ChatSession.fromJson(map);
    }).toList();
  }

  Future<ChatSession?> getSession(String sessionId) async {
    final row = await (select(sessionRows)
          ..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
    if (row == null) return null;
    return ChatSession.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
  }

  Future<String?> getCurrentSessionId() async {
    final row = await (select(sessionRows)
          ..where((t) => t.isCurrent.equals(true)))
        .getSingleOrNull();
    return row?.id;
  }

  Future<void> deleteSessionRow(String sessionId) async {
    await (delete(sessionRows)..where((t) => t.id.equals(sessionId))).go();
  }
}

// ══════════════════════════════════════════════════════════
// 消息 DAO
// ══════════════════════════════════════════════════════════

extension MessageDao on AppDatabase {
  Future<List<Map<String, dynamic>>> _readList(String sessionId) async {
    final row = await (select(messageRows)
          ..where((t) => t.sessionId.equals(sessionId)))
        .getSingleOrNull();
    if (row == null) return [];
    final decoded = jsonDecode(row.data);
    if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> _writeList(String sessionId, List<Map<String, dynamic>> list) async {
    await into(messageRows).insertOnConflictUpdate(
      MessageRowsCompanion.insert(
        sessionId: sessionId,
        data: jsonEncode(list),
      ),
    );
  }

  /// 整体写入指定会话的消息列表（用于旧数据迁移）
  Future<void> writeMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    await _writeList(
      sessionId,
      messages.map((m) => m.toJson()).toList(),
    );
  }

  /// 按 msgId upsert 单条消息
  Future<void> upsertMessage(ChatMessage message) async {
    final sessionId = message.sessionId;
    if (sessionId == null || message.msgId.isEmpty) return;
    final list = await _readList(sessionId);
    final json = message.toJson();
    final idx = list.indexWhere((m) => m['id'] == message.msgId);
    if (idx != -1) {
      list[idx] = json;
    } else {
      list.add(json);
    }
    await _writeList(sessionId, list);
  }

  Future<ChatMessage?> getMessage(String sessionId, String msgId) async {
    if (sessionId.isEmpty || msgId.isEmpty) return null;
    final list = await _readList(sessionId);
    for (final m in list) {
      if (m['id'] == msgId) {
        try {
          return ChatMessage.fromJson(m);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    final list = await _readList(sessionId);
    return list.map((m) {
      try {
        return ChatMessage.fromJson(m);
      } catch (_) {
        return null;
      }
    }).whereType<ChatMessage>().toList();
  }

  Future<void> clearMessages(String sessionId) async {
    if (sessionId.isEmpty) return;
    await _writeList(sessionId, []);
  }

  Future<void> deleteMessagesBySession(String sessionId) async {
    await (delete(messageRows)..where((t) => t.sessionId.equals(sessionId))).go();
  }

  /// 按 msgId 从指定会话的消息列表中移除单条消息
  Future<void> deleteMessageById(String sessionId, String msgId) async {
    if (sessionId.isEmpty || msgId.isEmpty) return;
    final list = await _readList(sessionId);
    final newList = list.where((m) => m['id'] != msgId).toList();
    if (newList.length != list.length) {
      await _writeList(sessionId, newList);
    }
  }
}

// ══════════════════════════════════════════════════════════
// 模型 DAO
// ══════════════════════════════════════════════════════════

extension ModelDao on AppDatabase {
  Future<void> upsertModel(ChatModel model) async {
    await into(modelRows).insertOnConflictUpdate(
      ModelRowsCompanion.insert(
        id: model.modelId,
        data: jsonEncode(model.toMap()),
      ),
    );
  }

  Future<List<ChatModel>> getAllModels() async {
    final rows = await select(modelRows).get();
    return rows.map((r) {
      try {
        return ChatModel.fromMap(jsonDecode(r.data) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<ChatModel>().toList();
  }

  Future<ChatModel?> getModel(String modelId) async {
    if (modelId.isEmpty) return null;
    final row = await (select(modelRows)
          ..where((t) => t.id.equals(modelId)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return ChatModel.fromMap(jsonDecode(row.data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteModel(String modelId) async {
    await (delete(modelRows)..where((t) => t.id.equals(modelId))).go();
  }
}

// ══════════════════════════════════════════════════════════
// MCP DAO
// ══════════════════════════════════════════════════════════

extension McpDao on AppDatabase {
  Future<void> upsertMcp(Mcp mcp) async {
    await into(mcpRows).insertOnConflictUpdate(
      McpRowsCompanion.insert(
        name: mcp.name,
        data: jsonEncode(mcp.toJson()),
      ),
    );
  }

  Future<List<Mcp>> getAllMcps() async {
    final rows = await select(mcpRows).get();
    return rows.map((r) {
      try {
        return Mcp.fromJson(
          r.name,
          jsonDecode(r.data) as Map<String, dynamic>,
        );
      } catch (_) {
        return null;
      }
    }).whereType<Mcp>().toList();
  }

  Future<Mcp?> getMcp(String name) async {
    if (name.isEmpty) return null;
    final row = await (select(mcpRows)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return Mcp.fromJson(name, jsonDecode(row.data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteMcp(String name) async {
    await (delete(mcpRows)..where((t) => t.name.equals(name))).go();
  }
}

// ══════════════════════════════════════════════════════════
// 设置 DAO（聚合 SystemSetting 存为单条记录）
// ══════════════════════════════════════════════════════════

extension SettingDao on AppDatabase {
  Future<void> putSettingRaw(String key, Object value) async {
    await into(settingRows).insertOnConflictUpdate(
      SettingRowsCompanion.insert(
        key: key,
        data: jsonEncode(value),
      ),
    );
  }

  Future<Object?> getSettingRaw(String key) async {
    final row = await (select(settingRows)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.data);
  }
}

// ══════════════════════════════════════════════════════════
// 审计 DAO
// ══════════════════════════════════════════════════════════

extension AuditDao on AppDatabase {
  Future<void> insertAudit(AuditLog log, {String? fallbackId}) async {
    final requestId = log.requestId ?? fallbackId;
    await into(auditRows).insert(
      AuditRowsCompanion.insert(
        requestId: Value(requestId),
        sessionId: Value(log.sessionId),
        timestamp: log.timestamp.millisecondsSinceEpoch,
        data: jsonEncode(log.toJson()),
      ),
    );
  }

  Future<void> upsertAudit(AuditLog log) async {
    if (log.requestId == null || log.requestId!.isEmpty) return;
    await into(auditRows).insertOnConflictUpdate(
      AuditRowsCompanion.insert(
        requestId: Value(log.requestId!),
        sessionId: Value(log.sessionId),
        timestamp: log.timestamp.millisecondsSinceEpoch,
        data: jsonEncode(log.toJson()),
      ),
    );
  }

  Future<List<AuditLog>> getAudits({String? sessionId, int limit = 200}) async {
    final query = select(auditRows);
    if (sessionId != null) {
      query.where((t) => t.sessionId.equals(sessionId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    if (limit > 0) query.limit(limit);
    final rows = await query.get();
    return rows.map((r) {
      try {
        return AuditLog.fromJson(jsonDecode(r.data) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<AuditLog>().toList();
  }

  Future<AuditLog?> getAuditById(String requestId) async {
    if (requestId.isEmpty) return null;
    final row = await (select(auditRows)
          ..where((t) => t.requestId.equals(requestId)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return AuditLog.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAudit(String requestId) async {
    if (requestId.isEmpty) return;
    await (delete(auditRows)..where((t) => t.requestId.equals(requestId))).go();
  }

  Future<void> clearAudits() async {
    await delete(auditRows).go();
  }
}

// ══════════════════════════════════════════════════════════
// 用量 DAO
// ══════════════════════════════════════════════════════════

extension UsageDao on AppDatabase {
  static String _detailKey(UsageDetail d) =>
      '${d.timestamp.toIso8601String()}_${d.model}_${d.cost.toStringAsFixed(6)}';

  Future<void> insertUsage(String sessionId, UsageDetail detail) async {
    await into(usageRows).insert(
      UsageRowsCompanion.insert(
        detailKey: _detailKey(detail),
        sessionId: Value(sessionId),
        model: Value(detail.model),
        timestamp: detail.timestamp.millisecondsSinceEpoch,
        data: jsonEncode(detail.toJson()),
      ),
    );
  }

  Future<void> upsertUsage(String sessionId, UsageDetail detail) async {
    await into(usageRows).insertOnConflictUpdate(
      UsageRowsCompanion.insert(
        detailKey: _detailKey(detail),
        sessionId: Value(sessionId),
        model: Value(detail.model),
        timestamp: detail.timestamp.millisecondsSinceEpoch,
        data: jsonEncode(detail.toJson()),
      ),
    );
  }

  Future<List<UsageDetail>> getUsages({
    String? sessionId,
    String? modelId,
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    final query = select(usageRows);
    if (sessionId != null) query.where((t) => t.sessionId.equals(sessionId));
    if (modelId != null) query.where((t) => t.model.equals(modelId));
    if (start != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(
          start.millisecondsSinceEpoch));
    }
    if (end != null) {
      query.where(
          (t) => t.timestamp.isSmallerOrEqualValue(end.millisecondsSinceEpoch));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    if (limit != null && limit > 0) query.limit(limit);
    final rows = await query.get();
    return rows.map((r) {
      try {
        return UsageDetail.fromJson(jsonDecode(r.data) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<UsageDetail>().toList();
  }

  Future<UsageDetail?> getUsage(UsageDetail detail) async {
    final row = await (select(usageRows)
          ..where((t) => t.detailKey.equals(_detailKey(detail))))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return UsageDetail.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUsage(UsageDetail detail) async {
    await (delete(usageRows)..where((t) => t.detailKey.equals(_detailKey(detail))))
        .go();
  }

  Future<void> clearUsages() async {
    await delete(usageRows).go();
  }
}

// ══════════════════════════════════════════════════════════
// 供应商密钥 DAO
// ══════════════════════════════════════════════════════════

extension VendorKeyDao on AppDatabase {
  Future<String?> getVendorKey(String vendorId) async {
    final row = await (select(vendorKeyRows)
          ..where((t) => t.vendorId.equals(vendorId)))
        .getSingleOrNull();
    return row?.apiKey;
  }

  Future<void> putVendorKey(String vendorId, String apiKey) async {
    await into(vendorKeyRows).insertOnConflictUpdate(
      VendorKeyRowsCompanion.insert(
        vendorId: vendorId,
        apiKey: apiKey,
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> deleteVendorKey(String vendorId) async {
    await (delete(vendorKeyRows)..where((t) => t.vendorId.equals(vendorId))).go();
  }
}
