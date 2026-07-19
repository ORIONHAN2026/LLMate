import '../models/audit_event.dart';
import 'duckdb_storage.dart';

/// 审计回放服务
///
/// 基于 [DuckDBStorage] 按 [traceId] 还原一次完整业务交互的事件序列，
/// 供审计回溯 / 调试使用。
class ReplayService {
  final DuckDBStorage storage;

  ReplayService(this.storage);

  /// 回放指定链路（traceId）下的全部事件，按发生时间升序返回
  Future<List<AuditEvent>> replay(String traceId) =>
      storage.loadTrace(traceId);
}
