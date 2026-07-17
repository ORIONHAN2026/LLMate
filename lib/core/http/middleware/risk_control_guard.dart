import 'package:shelf/shelf.dart';

import '../../../models/chat/chat_session.dart';
import '../sensitive_masker.dart';

/// 风控脱敏中间件（请求路径 / 前置处理）
///
/// 位于 [modelToolGuard] 之后、[userMessageGuard] 之前执行，
/// 此时 `request.context['body']` 已由上游中间件装载好增强后的请求体。
///
/// 职责：根据会话所绑定模型的设置（[ChatSettings.maskPhone] /
/// [ChatSettings.maskIdCard]），对请求体中所有消息内容（用户消息 / 系统提示 /
/// 工具结果等）内的手机号、身份证号等敏感信息进行 * 号脱敏（仅开启的项才处理），
/// 再向下游注入。这样既避免明文 PII 被转发给第三方大模型，也保证落盘的审计日志
/// 是脱敏后的。
///
/// 仅脱敏消息文本，不触碰 tool_calls 的 id、arguments 结构字段，
/// 以免破坏工具调用协议的完整性。脱敏开关存入 `request.context['riskControl']`，
/// 供下游日志落盘与工具循环复用，保持整条链路一致。
Handler riskControlGuard(Handler innerHandler) {
  return (Request request) async {
    final session = request.context['session'] as ChatSession?;
    if (session == null) {
      return innerHandler(request);
    }

    final body = request.context['body'] as Map<String, dynamic>?;
    if (body == null) {
      // 上游未装载 body，直接放行
      return innerHandler(request);
    }

    // 从模型设置读取脱敏开关
    final settings = session.chatModel?.chatSettings;
    final options = SensitiveMaskOptions(
      maskPhone: settings?.maskPhone ?? false,
      maskIdCard: settings?.maskIdCard ?? false,
    );

    // 未开启任何脱敏项则直接放行，零开销
    if (!options.hasAny) {
      return innerHandler(request);
    }

    // 脱敏后的请求体重新注入下游，并记录脱敏开关供日志/工具循环使用
    final maskedBody = maskSensitiveBody(body, options);

    final updatedRequest = request.change(
      context: {
        ...request.context,
        'body': maskedBody,
        'riskControl': options,
      },
    );

    return innerHandler(updatedRequest);
  };
}

/// 从请求 context 中读取风控脱敏开关，缺省视为全部关闭。
SensitiveMaskOptions riskControlOptionsOf(Request request) {
  final opts = request.context['riskControl'];
  return opts is SensitiveMaskOptions ? opts : SensitiveMaskOptions.disabled;
}
