import 'dart:convert';

import 'package:get/get.dart';

import '../../controllers/audit_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/usage_controller.dart';
import '../../models/audit_types.dart';
import '../../models/chat/session.dart';

/// 管理模式下的「系统工具」定义（OpenAI function-calling 格式）。
///
/// 仅在管理模式（本地直连大模型）时注入，用于让大模型通过工具调用完成：
///   - 审计内容：增删改查（[audit_search] / [audit_get] / [audit_add] /
///     [audit_update] / [audit_delete]）
///   - 用量与额度：用量查询（[usage_query]）、会话额度查询（[quota_get]）、
///     会话额度设置（[quota_set]）、会话额度重置（[quota_reset]）
///
/// 这些工具在客户端本地执行（[executeManagementTool]），不经过本机 HTTP 服务，
/// 也不写入新的审计 / 用量记录（即「管理模式用量不计入统计」）。
const List<Map<String, dynamic>> managementToolDefinitions = [
  // ───────────────── 审计：查询 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'audit_search',
      'description':
          '检索审计事件。可按会话ID、链路ID、事件类型、时间范围过滤，时间升序返回。'
          '用于排查「谁在何时调用了哪个工具 / 模型」「某次请求的输入输出」等审计问题。',
      'parameters': {
        'type': 'object',
        'properties': {
          'sessionId': {
            'type': 'string',
            'description': '按会话ID过滤',
          },
          'traceId': {
            'type': 'string',
            'description': '按审计链路ID过滤',
          },
          'eventTypes': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                '事件类型列表，可选值：request/prompt/policy/memoryRead/'
                'memoryWrite/toolStart/toolFinish/llmRequest/llmResponse/'
                'response/error/cost',
          },
          'start': {
            'type': 'string',
            'description': '起始时间，ISO8601 格式（如 2026-07-01T00:00:00）',
          },
          'end': {
            'type': 'string',
            'description': '结束时间，ISO8601 格式',
          },
          'limit': {
            'type': 'integer',
            'description': '最大返回条数，默认 100',
          },
        },
      },
    },
  },
  // ───────────────── 审计：单条获取 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'audit_get',
      'description': '按 id 获取单条审计事件的完整内容（含 payload）。',
      'parameters': {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'string',
            'description': '审计事件 id',
          },
        },
        'required': ['id'],
      },
    },
  },
  // ───────────────── 审计：新增 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'audit_add',
      'description':
          '新增一条审计事件（系统自动生成 id 与 spanId）。可用于手动记录管理操作。',
      'parameters': {
        'type': 'object',
        'properties': {
          'sessionId': {
            'type': 'string',
            'description': '所属会话ID',
          },
          'traceId': {
            'type': 'string',
            'description': '可选，归属的审计链路ID；不填则自动新建链路',
          },
          'type': {
            'type': 'string',
            'description':
                '事件类型，如 request/prompt/toolStart/toolFinish/'
                'llmRequest/llmResponse/response/error/cost',
          },
          'payload': {
            'type': 'object',
            'description': '事件负载（任意 JSON 对象）',
          },
          'parentSpanId': {
            'type': 'string',
            'description': '可选，父 spanId，用于表达调用层级',
          },
        },
        'required': ['sessionId', 'type', 'payload'],
      },
    },
  },
  // ───────────────── 审计：更新 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'audit_update',
      'description': '按 id 更新审计事件的 payload（其余字段不变）。',
      'parameters': {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'string',
            'description': '审计事件 id',
          },
          'payload': {
            'type': 'object',
            'description': '要写入的新 payload（任意 JSON 对象）',
          },
        },
        'required': ['id', 'payload'],
      },
    },
  },
  // ───────────────── 审计：删除 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'audit_delete',
      'description': '按 id 删除一条审计事件。',
      'parameters': {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'string',
            'description': '审计事件 id',
          },
        },
        'required': ['id'],
      },
    },
  },
  // ───────────────── 用量：查询 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'usage_query',
      'description':
          '查询用量统计。可按会话ID、模型、时间范围过滤，返回累计统计与明细列表。',
      'parameters': {
        'type': 'object',
        'properties': {
          'sessionId': {
            'type': 'string',
            'description': '按会话ID过滤',
          },
          'modelId': {
            'type': 'string',
            'description': '按模型过滤',
          },
          'start': {
            'type': 'string',
            'description': '起始时间 ISO8601',
          },
          'end': {
            'type': 'string',
            'description': '结束时间 ISO8601',
          },
          'limit': {
            'type': 'integer',
            'description': '返回明细条数上限，默认 50',
          },
        },
      },
    },
  },
  // ───────────────── 额度：查询 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'quota_get',
      'description':
          '查询当前会话的额度配置（是否启用、各项上限、重置周期）及当前用量。',
      'parameters': {
        'type': 'object',
        'properties': {},
      },
    },
  },
  // ───────────────── 额度：设置 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'quota_set',
      'description':
          '设置当前会话的额度。仅传入需要修改的字段即可，未传入的字段保持不变。',
      'parameters': {
        'type': 'object',
        'properties': {
          'enabled': {
            'type': 'boolean',
            'description': '是否启用额度限制',
          },
          'tokenLimit': {
            'type': 'integer',
            'description': 'Token 用量上限（null/不传=不限制）',
          },
          'costLimit': {
            'type': 'number',
            'description': '费用预算上限（null/不传=不限制）',
          },
          'requestLimit': {
            'type': 'integer',
            'description': '请求次数上限（null/不传=不限制）',
          },
          'resetPeriod': {
            'type': 'string',
            'description': '重置周期：daily=每天 / monthly=每月 / 不传=不修改',
          },
        },
      },
    },
  },
  // ───────────────── 额度：重置 ─────────────────
  {
    'type': 'function',
    'function': {
      'name': 'quota_reset',
      'description':
          '重置当前会话的额度计数（清零请求次数并将周期起点设为现在）。',
      'parameters': {
        'type': 'object',
        'properties': {},
      },
    },
  },
];

/// 所有管理模式系统工具的名称集合
const Set<String> managementToolNames = {
  'audit_search',
  'audit_get',
  'audit_add',
  'audit_update',
  'audit_delete',
  'usage_query',
  'quota_get',
  'quota_set',
  'quota_reset',
};

/// 执行一个管理模式系统工具，返回 JSON 字符串结果（含 success / error 或 data）。
///
/// [session] 为发起请求的管理会话，额度类工具作用于其实时存储的会话对象。
Future<String> executeManagementTool(
  String name,
  Map<String, dynamic> args,
  ChatSession session,
) async {
  try {
    switch (name) {
      // ───────────── 审计 ─────────────
      case 'audit_search':
        await AuditController.instance.ensureInitialized();
        final events = await AuditController.instance.queryEvents(
          AuditFilter(
            sessionId: _strOrNull(args['sessionId']),
            traceId: _strOrNull(args['traceId']),
            eventTypes: _parseEventTypes(args['eventTypes']),
            start: _parseTime(args['start']),
            end: _parseTime(args['end']),
            limit: _intOrNull(args['limit']) ?? 100,
          ),
        );
        return _ok({
          'count': events.length,
          'events': events.map((e) => e.toJson()).toList(),
        });

      case 'audit_get':
        await AuditController.instance.ensureInitialized();
        final id = _strOrNull(args['id']);
        if (id == null) return _err('缺少 id');
        final e = await AuditController.instance.getEvent(id);
        if (e == null) return _err('未找到 id=$id 的审计事件');
        return _ok(e.toJson());

      case 'audit_add':
        await AuditController.instance.ensureInitialized();
        final sessionId = _strOrNull(args['sessionId']);
        if (sessionId == null) return _err('缺少 sessionId');
        final type = AuditEventTypeX.fromName(
          _strOrNull(args['type']) ?? 'request',
        );
        final payload =
            args['payload'] is Map
                ? Map<String, dynamic>.from(args['payload'] as Map)
                : <String, dynamic>{};
        final event = await AuditController.instance.addEvent(
          sessionId: sessionId,
          traceId: _strOrNull(args['traceId']),
          type: type,
          payload: payload,
          parentSpanId: _strOrNull(args['parentSpanId']),
        );
        return _ok({'id': event.id});

      case 'audit_update':
        await AuditController.instance.ensureInitialized();
        final id = _strOrNull(args['id']);
        if (id == null) return _err('缺少 id');
        final payload =
            args['payload'] is Map
                ? Map<String, dynamic>.from(args['payload'] as Map)
                : <String, dynamic>{};
        await AuditController.instance.updateEvent(id, payload);
        return _ok({'success': true});

      case 'audit_delete':
        await AuditController.instance.ensureInitialized();
        final id = _strOrNull(args['id']);
        if (id == null) return _err('缺少 id');
        await AuditController.instance.deleteEvent(id);
        return _ok({'success': true});

      // ───────────── 用量 ─────────────
      case 'usage_query':
        final sessionId = _strOrNull(args['sessionId']);
        final modelId = _strOrNull(args['modelId']);
        final start = _parseTime(args['start']);
        final end = _parseTime(args['end']);
        final limit = _intOrNull(args['limit']) ?? 50;
        final stats = await UsageController.instance.getStats(
          sessionId: sessionId,
          modelId: modelId,
          start: start,
          end: end,
        );
        final details = await UsageController.instance.loadDetails(
          sessionId: sessionId,
          modelId: modelId,
          start: start,
          end: end,
          limit: limit,
        );
        return _ok({
          'stats': stats.toJson(),
          'details': details.map((d) => d.toJson()).toList(),
        });

      // ───────────── 额度 ─────────────
      case 'quota_get':
        final s = Get.find<SessionController>().currentSession.value ?? session;
        final stats = await UsageController.instance.getStats(
          sessionId: s.sessionId,
        );
        return _ok({
          ..._quotaSnapshot(s),
          'usage': {
            'requests': stats.requests,
            'promptTokens': stats.promptTokens,
            'completionTokens': stats.completionTokens,
            'totalTokens': stats.totalTokens,
            'costsByCurrency': stats.costsByCurrency,
          },
        });

      case 'quota_set':
        final sc = Get.find<SessionController>();
        var s = sc.currentSession.value ?? session;
        if (args.containsKey('enabled')) {
          s = s.copyWith(quotaEnabled: args['enabled'] as bool);
        }
        if (args.containsKey('tokenLimit')) {
          s = s.copyWith(quotaTokenLimit: _intOrNull(args['tokenLimit']));
        }
        if (args.containsKey('costLimit')) {
          s = s.copyWith(quotaCostLimit: _doubleOrNull(args['costLimit']));
        }
        if (args.containsKey('requestLimit')) {
          s = s.copyWith(quotaRequestLimit: _intOrNull(args['requestLimit']));
        }
        if (args.containsKey('resetPeriod')) {
          s = s.copyWith(quotaResetPeriod: _strOrNull(args['resetPeriod']));
        }
        sc.updateSession(s);
        return _ok(_quotaSnapshot(s));

      case 'quota_reset':
        final sc = Get.find<SessionController>();
        final s = sc.currentSession.value ?? session;
        final updated = s.copyWith(
          quotaRequestCount: 0,
          quotaPeriodStart: DateTime.now(),
        );
        sc.updateSession(updated);
        return _ok(_quotaSnapshot(updated));

      default:
        return _err('未知的系统工具: $name');
    }
  } catch (e) {
    return _err('工具执行异常: $e');
  }
}

// ───────────────────── 内部工具 ─────────────────────

Map<String, dynamic> _quotaSnapshot(ChatSession s) => {
  'sessionId': s.sessionId,
  'quotaEnabled': s.quotaEnabled,
  'quotaTokenLimit': s.quotaTokenLimit,
  'quotaCostLimit': s.quotaCostLimit,
  'quotaRequestLimit': s.quotaRequestLimit,
  'quotaResetPeriod': s.quotaResetPeriod,
  'quotaPeriodStart': s.quotaPeriodStart?.toIso8601String(),
  'quotaRequestCount': s.quotaRequestCount,
};

String _ok(Map<String, dynamic> data) =>
    jsonEncode({'success': true, ...data});

String _err(String message) => jsonEncode({'success': false, 'error': message});

Set<AuditEventType>? _parseEventTypes(dynamic v) {
  if (v is List) {
    return v.map((e) => AuditEventTypeX.fromName(e.toString())).toSet();
  }
  return null;
}

DateTime? _parseTime(dynamic v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _doubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _strOrNull(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  return v.toString();
}
