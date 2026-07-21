import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:path/path.dart' as p;

import '../services/storage_paths.dart';
import '../models/audit_event.dart';
import '../models/audit_types.dart';

/// DuckDB 审计存储
///
/// 持久化于 `~/.llmate/audit.duckdb` 的 `audit_events` 表。所有读写均经内部
/// 串行队列（[_serialize]）调度，避免单连接下的并发写冲突。
///
/// 表结构（与架构设计一致）：
/// ```sql
/// audit_events(
///   id, trace_id, span_id, parent_span_id,
///   session_id, user_id,
///   event_type, timestamp, payload_json
/// )
/// ```
class DuckDBStorage {
  DuckDBStorage({String? dbPath}) : _explicitPath = dbPath;

  final String? _explicitPath;

  Database? _db;
  Connection? _conn;
  bool _initialized = false;

  /// 串行化所有数据库操作，保证单连接安全
  Future<void> _lastOp = Future.value();

  /// 打开数据库并建表（幂等）
  ///
  /// 对 DuckDB 的文件锁冲突做容错：重试若干次（应对另一进程正在释放锁的
  /// 短暂窗口），仍失败则降级——仅记录告警、不抛异常，避免拖垮应用启动。
  /// 审计为可观测能力，不可用时业务照常运行。
  Future<void> initialize() async {
    if (_initialized) return;
    await StoragePaths.ensureRoot();
    final path =
        _explicitPath ?? p.join(StoragePaths.root, 'audit.duckdb');
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _db = await duckdb.open(path);
        _conn = await duckdb.connect(_db!);
        await _conn!.execute('''
          CREATE TABLE IF NOT EXISTS audit_events (
            id VARCHAR PRIMARY KEY,
            trace_id VARCHAR,
            span_id VARCHAR,
            parent_span_id VARCHAR,
            session_id VARCHAR,
            user_id VARCHAR,
            event_type VARCHAR,
            timestamp VARCHAR,
            payload_json VARCHAR
          )
        ''');
        _initialized = true;
        debugPrint('🗄️ [Audit] DuckDB 已初始化: $path');
        return;
      } on DuckDBException catch (e) {
        await _safeClose();
        if (_isLockError(e) && attempt < maxAttempts) {
          debugPrint(
            '⚠️ [Audit] 审计库被占用，重试 ($attempt/$maxAttempts): $e',
          );
          await Future.delayed(const Duration(milliseconds: 400));
          continue;
        }
        debugPrint('⚠️ [Audit] 初始化失败，审计功能暂不可用: $e');
        return;
      }
    }
  }

  /// 释放连接与数据库资源
  Future<void> close() async {
    try {
      await _conn?.dispose();
      await _db?.dispose();
    } catch (_) {
      // 忽略关闭异常
    } finally {
      _conn = null;
      _db = null;
      _initialized = false;
    }
  }

  /// 释放已分配的连接 / 数据库资源（忽略异常），用于初始化失败回滚
  Future<void> _safeClose() async {
    try {
      await _conn?.dispose();
      await _db?.dispose();
    } catch (_) {
      // 忽略
    }
    _conn = null;
    _db = null;
  }

  /// 判断异常是否为 DuckDB 文件锁冲突
  bool _isLockError(Object e) =>
      e.toString().toLowerCase().contains('lock');

  /// 写入单条审计事件
  Future<void> save(AuditEvent event) => saveBatch([event]);

  /// 批量写入审计事件（单条 SQL 完成）
  Future<void> saveBatch(List<AuditEvent> events) async {
    if (events.isEmpty) return;
    if (!_initialized || _conn == null) {
      debugPrint('⚠️ [Audit] 存储未就绪，跳过写入');
      return;
    }
    await _serialize(() async {
      final sb = StringBuffer();
      sb.write(
        'INSERT OR REPLACE INTO audit_events '
        '(id, trace_id, span_id, parent_span_id, session_id, '
        'user_id, event_type, timestamp, payload_json) VALUES ',
      );
      for (var i = 0; i < events.length; i++) {
        final e = events[i];
        sb.write(
          '('
          '${_q(e.id)}, '
          '${_q(e.traceId)}, '
          '${_q(e.spanId)}, '
          '${e.parentSpanId == null ? 'NULL' : _q(e.parentSpanId!)}, '
          '${_q(e.sessionId)}, '
          '${_q(e.userId)}, '
          '${_q(e.type.name)}, '
          '${_q(e.timestamp.toIso8601String())}, '
          '${_q(jsonEncode(e.payload))}'
          ')',
        );
        sb.write(i < events.length - 1 ? ', ' : ';');
      }
      await _conn!.execute(sb.toString());
    });
  }

  /// 加载某条链路（traceId）下的全部事件，按时间升序
  Future<List<AuditEvent>> loadTrace(String traceId) => _query(
        'SELECT * FROM audit_events '
        'WHERE trace_id = ${_q(traceId)} '
        'ORDER BY timestamp ASC',
      );

  /// 按过滤器检索审计事件（时间升序）
  Future<List<AuditEvent>> search(AuditFilter filter) {
    final conds = <String>[];
    if (filter.traceId != null) {
      conds.add('trace_id = ${_q(filter.traceId!)}');
    }
    if (filter.sessionId != null) {
      conds.add('session_id = ${_q(filter.sessionId!)}');
    }
    if (filter.userId != null) {
      conds.add('user_id = ${_q(filter.userId!)}');
    }
    if (filter.eventTypes != null && filter.eventTypes!.isNotEmpty) {
      final types = filter.eventTypes!.map((e) => _q(e.name)).join(', ');
      conds.add('event_type IN ($types)');
    }
    // timestamp 以 ISO8601 字符串存储，字典序即时间序，可直接比较
    if (filter.start != null) {
      conds.add('timestamp >= ${_q(filter.start!.toIso8601String())}');
    }
    if (filter.end != null) {
      conds.add('timestamp <= ${_q(filter.end!.toIso8601String())}');
    }

    var sql = 'SELECT * FROM audit_events';
    if (conds.isNotEmpty) sql += ' WHERE ${conds.join(' AND ')}';
    sql += ' ORDER BY timestamp ASC';
    if (filter.limit != null && filter.limit! > 0) {
      sql += ' LIMIT ${filter.limit}';
    }
    return _query(sql);
  }

  // ───────────────────────────────────────────────────────────
  // 内部工具
  // ───────────────────────────────────────────────────────────

  /// 执行查询并将结果行映射为 [AuditEvent]
  Future<List<AuditEvent>> _query(String sql) {
    if (!_initialized || _conn == null) return Future.value([]);
    return _serialize(() async {
        final rs = await _conn!.query(sql);
        final names = rs.columnNames.map((n) => n.toLowerCase()).toList();
        final rows = rs.fetchAll();
        await rs.dispose();
        return rows.map((row) {
          final map = <String, dynamic>{};
          for (var i = 0; i < names.length; i++) {
            map[names[i]] = i < row.length ? row[i] : null;
          }
          return AuditEvent.fromRow(map);
        }).toList();
      });
  }

  /// 将所有数据库操作串行进队列，保证单连接安全
  Future<T> _serialize<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _lastOp = _lastOp.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }).catchError((_) {
      // 前序任务失败不影响后续任务，保持队列存活
    });
    return completer.future;
  }

  /// 转义 SQL 字符串字面量（仅将单引号转义为双单引号，符合标准 SQL）
  static String _q(String s) => "'${s.replaceAll("'", "''")}'";
}
