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
  Map<String, dynamic>? organizedRequest,
  Map<String, dynamic>? rawResponse,
  String? responseContent,
  int? promptTokens,
  int? completionTokens,
  int? totalTokens,
  int? reasoningTokens,
  int? cachedTokens,
  double? cost,
  String? error,
  List<Map<String, dynamic>>? toolCallResults,
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
    // 读取上游注入的唯一 RequestId（由路由层生成）
    final requestId = request.context['requestId'] as String?;

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
      'requestId': requestId ?? 'unknown',
      'sessionName': session?.name ?? '',
      'model': session?.chatModel?.model ?? (parsedBody?['model'] ?? 'unknown'),
      'clientIp': clientIp,
      'apiKeyProvided': apiKey != null && apiKey.isNotEmpty,
      'apiKeyValid': session != null,
      'quotaEnabled': session?.quotaEnabled ?? false,
      'rawRequest': rawRequest,
      'organizedRequest': null,
    };

    // 注入审计回调到 context，供业务层补充响应内容
    final completer = _AuditCompleter(auditEntry: auditEntry, startTime: startTime);
    final updatedRequest = request.change(context: {
      ...request.context,
      'auditCallback': ({
        Map<String, dynamic>? rawRequest,
        Map<String, dynamic>? organizedRequest,
        Map<String, dynamic>? rawResponse,
        String? responseContent,
        int? promptTokens,
        int? completionTokens,
        int? totalTokens,
        int? reasoningTokens,
        int? cachedTokens,
        double? cost,
        String? error,
        List<Map<String, dynamic>>? toolCallResults,
      }) =>
          completer.complete(
            rawRequest: rawRequest,
            organizedRequest: organizedRequest,
            rawResponse: rawResponse,
            responseContent: responseContent,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            reasoningTokens: reasoningTokens,
            cachedTokens: cachedTokens,
            cost: cost,
            error: error,
            toolCallResults: toolCallResults,
          ),
    });

    // 执行下游 handler
    final response = await innerHandler(updatedRequest);

    // 补充基础响应信息（状态码、耗时），实际落盘由业务层回调触发
    final duration = DateTime.now().difference(startTime);
    auditEntry['response'] ??= <String, dynamic>{};
    (auditEntry['response'] as Map<String, dynamic>)
        .addAll({
          'statusCode': response.statusCode,
          'durationMs': duration.inMilliseconds,
        });

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
    Map<String, dynamic>? organizedRequest,
    Map<String, dynamic>? rawResponse,
    String? responseContent,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    int? reasoningTokens,
    int? cachedTokens,
    double? cost,
    String? error,
    List<Map<String, dynamic>>? toolCallResults,
  }) {
    final responseMap = (auditEntry['response'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (rawRequest != null) auditEntry['rawRequest'] = rawRequest;
    if (organizedRequest != null) auditEntry['organizedRequest'] = organizedRequest;

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
        if (reasoningTokens != null) 'reasoningTokens': reasoningTokens,
        if (cachedTokens != null) 'cachedTokens': cachedTokens,
      };
    }
    if (cost != null) {
      responseMap['cost'] = cost;
    }
    if (error != null) {
      responseMap['error'] = error;
    }
    if (toolCallResults != null && toolCallResults.isNotEmpty) {
      auditEntry['toolCallResults'] = toolCallResults;
    }

    final duration = DateTime.now().difference(startTime);
    responseMap['durationMs'] = duration.inMilliseconds;

    auditEntry['response'] = responseMap;

    // 仅当有响应内容或错误时才触发写入（仅有请求信息的调用不写盘）
    if (responseContent != null || error != null) {
      _writeAuditLog(auditEntry);
    }
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
///
/// 目录结构：log_request/{sessionId}/{requestId}/
///   - request.json           收到的请求（原始）
///   - request_organized.json 根据会话组织后的请求（注入 model / tools 等）
///   - response.json          返回的响应内容
void _writeAuditLog(Map<String, dynamic> entry) {
  () async {
    try {
      final sessionId = entry['sessionId'] as String? ?? 'unknown';
      final requestId = entry['requestId'] as String? ?? 'unknown';
      final dir = Directory('$_auditLogDir/$sessionId/$requestId');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final encoder = const JsonEncoder.withIndent('  ');

      // 1. 收到的请求（原始）
      final rawRequest = entry['rawRequest'] ?? {};
      await File('${dir.path}/request.json')
          .writeAsString(encoder.convert(rawRequest));

      // 2. 根据会话组织后的请求
      final organizedRequest = entry['organizedRequest'] ?? {};
      await File('${dir.path}/request_organized.json')
          .writeAsString(encoder.convert(organizedRequest));

      // 3. 返回
      final responseMap = <String, dynamic>{};
      final resp = entry['response'] as Map<String, dynamic>?;
      if (resp != null) {
        if (resp['content'] != null) responseMap['content'] = resp['content'];
        if (resp['rawResponse'] != null) responseMap['rawResponse'] = resp['rawResponse'];
        if (resp['usage'] != null) responseMap['usage'] = resp['usage'];
        if (resp['error'] != null) responseMap['error'] = resp['error'];
        if (resp['statusCode'] != null) responseMap['statusCode'] = resp['statusCode'];
        if (resp['cost'] != null) responseMap['cost'] = resp['cost'];
        responseMap['durationMs'] = resp['durationMs'] ?? 0;
      }
      await File('${dir.path}/response.json')
          .writeAsString(encoder.convert(responseMap));

      // 4. 工具调用结果
      final toolCallResults = entry['toolCallResults'] as List?;
      if (toolCallResults != null && toolCallResults.isNotEmpty) {
        await File('${dir.path}/tool_calls.json')
            .writeAsString(encoder.convert(toolCallResults));
      }

      debugPrint('📝 [Audit] 请求日志已写入: ${dir.path}');
    } catch (e) {
      debugPrint('⚠️ [Audit] 写入审计日志失败: $e');
    }
  }();
}
