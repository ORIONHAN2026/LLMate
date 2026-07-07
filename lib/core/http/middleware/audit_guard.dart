import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../../models/chat/chat_session.dart';

/// 审计日志目录
const String _auditLogDir = 'log_request';

/// 审计回调函数类型
///
/// 业务层在处理完请求/响应后，调用此回调补全审计条目中的实际内容。
typedef AuditCallback = void Function({
  Map<String, dynamic>? rawRequest,
  Map<String, dynamic>? rawResponse,
  String? responseContent,
  int? promptTokens,
  int? completionTokens,
  int? totalTokens,
  double? cost,
  String? error,
});

/// 审计中间件
///
/// 记录每次 API 请求的完整审计信息：
/// - 请求元数据：时间戳、客户端 IP、会话信息
/// - 请求内容：完整的 messages、参数
/// - 响应内容：响应文本、Token 用量、耗时、费用
/// - 安全状态：API Key 校验结果、配额状态
///
/// 通过 `request.context['auditCallback']` 向业务层暴露回调，
/// 业务层在处理完成后调用该回调补全实际内容。
/// 审计日志异步写入 `log_request/` 目录，不阻断请求。
Handler auditGuard(Handler innerHandler) {
  return (Request request) async {
    final startTime = DateTime.now();
    final session = request.context['session'] as ChatSession?;
    final apiKey = request.context['apiKey'] as String?;

    // 读取请求体
    String? requestBodyStr;
    Map<String, dynamic>? parsedBody;
    try {
      requestBodyStr = await request.readAsString();
      request = request.change(body: utf8.encode(requestBodyStr));
      if (requestBodyStr.isNotEmpty) {
        parsedBody = jsonDecode(requestBodyStr) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ [Audit] 读取请求体失败: $e');
    }

    // 构建原始请求（脱敏：移除 API Key 相关信息）
    final rawRequest = _buildRawRequest(parsedBody, session);

    // 提取客户端 IP
    final clientIp = _extractClientIp(request);

    // 构建审计条目基础结构
    final auditEntry = <String, dynamic>{
      'timestamp': startTime.toIso8601String(),
      'sessionId': session?.sessionId ?? 'unknown',
      'sessionName': session?.name ?? '',
      'model': session?.chatModel?.model ?? (parsedBody?['model'] ?? 'unknown'),
      'clientIp': clientIp,
      'apiKeyProvided': apiKey != null && apiKey.isNotEmpty,
      'apiKeyValid': session != null,
      'quotaEnabled': session?.quotaEnabled ?? false,
      'request': rawRequest,
    };

    // 注入审计回调到 context，供业务层补充响应内容
    final completer = _AuditCompleter(auditEntry: auditEntry, startTime: startTime);
    final updatedRequest = request.change(context: {
      ...request.context,
      'auditCallback': ({
        Map<String, dynamic>? rawRequest,
        Map<String, dynamic>? rawResponse,
        String? responseContent,
        int? promptTokens,
        int? completionTokens,
        int? totalTokens,
        double? cost,
        String? error,
      }) =>
          completer.complete(
            rawRequest: rawRequest,
            rawResponse: rawResponse,
            responseContent: responseContent,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            cost: cost,
            error: error,
          ),
    });

    // 执行下游 handler
    final response = await innerHandler(updatedRequest);

    // 补充基础响应信息并写入日志
    final duration = DateTime.now().difference(startTime);
    auditEntry['response'] ??= <String, dynamic>{};
    (auditEntry['response'] as Map<String, dynamic>)
        .addAll({
          'statusCode': response.statusCode,
          'durationMs': duration.inMilliseconds,
        });

    // 如果业务层已通过回调补充了内容，直接写入；否则写入当前状态
    _writeAuditLog(auditEntry);

    return response;
  };
}

/// 审计条目补全器
///
/// 业务层调用 [complete] 后，将实际响应内容写入审计条目并触发写入。
class _AuditCompleter {
  final Map<String, dynamic> auditEntry;
  final DateTime startTime;

  _AuditCompleter({required this.auditEntry, required this.startTime});

  void complete({
    Map<String, dynamic>? rawRequest,
    Map<String, dynamic>? rawResponse,
    String? responseContent,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    double? cost,
    String? error,
  }) {
    final responseMap = (auditEntry['response'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (rawResponse != null) {
      responseMap['rawResponse'] = rawResponse;
    }
    if (responseContent != null) {
      responseMap['content'] = responseContent;
    }
    if (promptTokens != null || completionTokens != null || totalTokens != null) {
      responseMap['usage'] = {
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'totalTokens': totalTokens,
      };
    }
    if (cost != null) {
      responseMap['cost'] = cost;
    }
    if (error != null) {
      responseMap['error'] = error;
    }

    final duration = DateTime.now().difference(startTime);
    responseMap['durationMs'] = duration.inMilliseconds;

    auditEntry['response'] = responseMap;

    // 业务层已补全内容，异步写入
    _writeAuditLog(auditEntry);
  }
}

/// 构建原始请求内容（脱敏处理）
Map<String, dynamic> _buildRawRequest(
  Map<String, dynamic>? parsedBody,
  ChatSession? session,
) {
  final result = <String, dynamic>{
    'stream': parsedBody?['stream'] ?? false,
    'model': session?.chatModel?.model ?? parsedBody?['model'] ?? 'unknown',
  };

  // 复制消息列表（完整的 messages 内容）
  if (parsedBody?['messages'] is List) {
    result['messages'] = parsedBody!['messages'];
  }

  // 复制其他参数
  if (parsedBody?['max_tokens'] != null) result['max_tokens'] = parsedBody!['max_tokens'];
  if (parsedBody?['temperature'] != null) result['temperature'] = parsedBody!['temperature'];
  if (parsedBody?['top_p'] != null) result['top_p'] = parsedBody!['top_p'];
  if (parsedBody?['frequency_penalty'] != null) result['frequency_penalty'] = parsedBody!['frequency_penalty'];
  if (parsedBody?['presence_penalty'] != null) result['presence_penalty'] = parsedBody!['presence_penalty'];
  if (parsedBody?['stop'] != null) result['stop'] = parsedBody!['stop'];
  if (parsedBody?['thinking'] != null) result['thinking'] = parsedBody!['thinking'];

  return result;
}

/// 提取客户端 IP 地址
String _extractClientIp(Request request) {
  final forwarded =
      request.headers['x-forwarded-for'] ??
      request.headers['X-Forwarded-For'];
  if (forwarded != null && forwarded.isNotEmpty) {
    return forwarded.split(',').first.trim();
  }

  final realIp =
      request.headers['x-real-ip'] ?? request.headers['X-Real-IP'];
  if (realIp != null && realIp.isNotEmpty) {
    return realIp.trim();
  }

  try {
    return request.headers['host'] ?? 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

/// 异步写入审计日志到文件
void _writeAuditLog(Map<String, dynamic> entry) {
  // 使用 scheduleMicrotask 避免阻塞响应
  () async {
    try {
      final dir = Directory(_auditLogDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final now = DateTime.now();
      final sessionId = entry['sessionId'] as String;
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}'
          '_$sessionId';

      final file = File('$_auditLogDir/$timestamp.json');
      final encoder = const JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(entry));

      debugPrint('📝 [Audit] 审计日志已写入: $timestamp.json');
    } catch (e) {
      debugPrint('⚠️ [Audit] 写入审计日志失败: $e');
    }
  }();
}
