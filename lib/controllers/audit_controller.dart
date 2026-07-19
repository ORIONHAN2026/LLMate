import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/audit_event.dart';
import '../models/audit_trace.dart';
import '../models/audit_types.dart';
import '../services/duckdb_storage.dart';
import '../services/replay_service.dart';

/// 审计控制器
///
/// 业务层只与本控制器交互，所有审计事件经其统一写入 [DuckDBStorage]，
/// 底层落盘到 `~/.llmate/audit.duckdb`。
///
/// 采用「链路（Trace）+ 事件（Event）」模型：一次业务请求 [beginTrace] 开启
/// 一条链路，后续 [prompt] / [llmRequest] / [toolStart] / [response] 等高层
/// API 向该链路追加事件；请求结束时 [endTrace] 收尾。事件以 span 形式记录
/// 层级关系，支持通过 [replayService] 回放整条链路。
///
/// 设计意图：仅暴露高层 API，内部 [emit] 方法负责构造 [AuditEvent] 并落盘。
class AuditController {
  final DuckDBStorage storage;
  late final ReplayService replayService;

  AuditController(this.storage) {
    replayService = ReplayService(storage);
  }

  static const Uuid _uuid = Uuid();
  static AuditController? _instance;

  /// 全局单例（延迟创建并初始化 DuckDB 存储）
  static AuditController get instance {
    _instance ??= AuditController(DuckDBStorage());
    return _instance!;
  }

  /// 启动时显式初始化底层存储（创建 audit.duckdb 与表结构）
  Future<void> ensureInitialized() => storage.initialize();

  // ══════════════════════════════════════════════════════════
  // 链路生命周期
  // ══════════════════════════════════════════════════════════

  /// 开启一条审计链路
  Future<AuditTrace> beginTrace({
    required String sessionId,
    required String userId,
    required String tenantId,
  }) async {
    final trace = AuditTrace(
      traceId: _uuid.v4(),
      sessionId: sessionId,
      userId: userId,
      tenantId: tenantId,
    );
    await emit(
      trace,
      AuditEventType.request,
      {'sessionId': sessionId, 'userId': userId, 'tenantId': tenantId},
    );
    return trace;
  }

  /// 结束一条审计链路
  Future<void> endTrace(AuditTrace trace) async {
    await emit(trace, AuditEventType.response, {'ended': true});
  }

  // ══════════════════════════════════════════════════════════
  // 高层事件 API
  // ══════════════════════════════════════════════════════════

  Future<void> prompt(AuditTrace trace, String prompt) =>
      emit(trace, AuditEventType.prompt, {'prompt': prompt});

  Future<void> policy(AuditTrace trace, Map<String, dynamic> policy) =>
      emit(trace, AuditEventType.policy, policy);

  Future<void> memoryRead(AuditTrace trace, String key, dynamic value) => emit(
        trace,
        AuditEventType.memoryRead,
        {'key': key, 'value': value},
      );

  Future<void> memoryWrite(AuditTrace trace, String key, dynamic value) => emit(
        trace,
        AuditEventType.memoryWrite,
        {'key': key, 'value': value},
      );

  Future<void> toolStart(AuditTrace trace, String tool) =>
      emit(trace, AuditEventType.toolStart, {'tool': tool});

  Future<void> toolFinish(
    AuditTrace trace,
    String tool,
    Map<String, dynamic> result,
  ) =>
      emit(trace, AuditEventType.toolFinish, {'tool': tool, 'result': result});

  Future<void> llmRequest(AuditTrace trace, String provider, String model) =>
      emit(trace, AuditEventType.llmRequest, {
        'provider': provider,
        'model': model,
      });

  Future<void> llmResponse(
    AuditTrace trace,
    int inputTokens,
    int outputTokens,
    double cost,
  ) =>
      emit(trace, AuditEventType.llmResponse, {
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'cost': cost,
      });

  Future<void> response(AuditTrace trace, String text) =>
      emit(trace, AuditEventType.response, {'text': text});

  Future<void> error(AuditTrace trace, String message) =>
      emit(trace, AuditEventType.error, {'message': message});

  Future<void> cost(AuditTrace trace, double cost, String currency) =>
      emit(trace, AuditEventType.cost, {'cost': cost, 'currency': currency});

  // ══════════════════════════════════════════════════════════
  // 内部：构造并落盘单条事件
  // ══════════════════════════════════════════════════════════

  /// 构造 [AuditEvent] 并写入存储。所有高层 API 均经由此方法。
  Future<void> emit(
    AuditTrace trace,
    AuditEventType type,
    Map<String, dynamic> payload, {
    String? parentSpanId,
  }) async {
    try {
      final event = AuditEvent(
        id: _uuid.v4(),
        traceId: trace.traceId,
        spanId: _uuid.v4(),
        parentSpanId: parentSpanId,
        tenantId: trace.tenantId,
        sessionId: trace.sessionId,
        userId: trace.userId,
        agentId: '', // 当前业务未区分 agent，留空
        type: type,
        timestamp: DateTime.now(),
        payload: payload,
      );
      await storage.save(event);
    } catch (e) {
      debugPrint('⚠️ [Audit] 写入事件失败 ($type): $e');
    }
  }
}
