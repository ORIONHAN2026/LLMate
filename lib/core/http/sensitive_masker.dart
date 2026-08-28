import 'package:crypto/crypto.dart';
import 'dart:convert';

enum SensitiveInfoType {
  phone,
  idCard,
  email,
  bankCard,
  address,
  customerId,
  sourceCode,
  contract,
}

enum SensitiveMaskMode { hash, block }

extension SensitiveMaskModeX on SensitiveMaskMode {
  String get value => name;
  static SensitiveMaskMode fromString(String? value) => SensitiveMaskMode.values
      .firstWhere((m) => m.name == value, orElse: () => SensitiveMaskMode.hash);
}

/// 脱敏选项：按敏感类型和处理模式控制。
///
/// 由会话安全设置（[ChatSession.maskPhone] / [ChatSession.maskIdCard]）驱动，
/// 仅当对应开关开启时才对匹配到的敏感信息进行 * 号替换。
class SensitiveMaskOptions {
  /// 是否脱敏手机号
  final bool maskPhone;

  /// 是否脱敏身份证号
  final bool maskIdCard;

  final Set<SensitiveInfoType> types;
  final SensitiveMaskMode mode;

  const SensitiveMaskOptions({
    this.maskPhone = false,
    this.maskIdCard = false,
    this.types = const {},
    this.mode = SensitiveMaskMode.hash,
  });

  /// 两者均未开启
  static const SensitiveMaskOptions disabled = SensitiveMaskOptions(
    maskPhone: false,
    maskIdCard: false,
  );

  /// 是否至少有一项需要脱敏
  bool get hasAny => maskPhone || maskIdCard || types.isNotEmpty;

  bool enabled(SensitiveInfoType type) =>
      types.contains(type) ||
      (type == SensitiveInfoType.phone && maskPhone) ||
      (type == SensitiveInfoType.idCard && maskIdCard);
}

/// 敏感信息脱敏工具
///
/// 用于在风控中间层与审计日志落盘前，对请求体 / 响应内容中的
/// 个人敏感信息（手机号、身份证号等）进行 * 号替换，避免明文 PII
/// 泄露到本地磁盘或转发给第三方大模型。
///
/// 是否脱敏由 [SensitiveMaskOptions] 控制，仅匹配强特征的数字串，以降低误伤：
/// - 手机号：1[3-9] 开头的 11 位中国大陆手机号
/// - 身份证号：15 位纯数字 或 18 位（17 位数字 + 校验位 [0-9Xx]）
class SensitiveMasker {
  SensitiveMasker._();

  /// 手机号（中国大陆）：1[3-9] 开头的 11 位号码
  static final RegExp _phoneRegex = RegExp(r'\b1[3-9]\d{9}\b');

  /// 身份证号：15 位纯数字 或 18 位（17 位数字 + 尾部校验位 [0-9Xx]）
  /// 使用 \b 词边界避免匹配更长数字串的中间片段。
  static final RegExp _idCardRegex = RegExp(r'\b(?:\d{15}|\d{17}[\dXx])\b');
  static final RegExp _emailRegex = RegExp(
    r'\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _bankCardRegex = RegExp(
    r'(?<!\d)(?:\d[ -]?){13,19}(?!\d)',
  );
  static final RegExp _addressRegex = RegExp(
    r'(?:(?:中国)?(?:北京|上海|天津|重庆|广东|江苏|浙江|山东|四川|湖北|福建|湖南|河南|河北|安徽|江西|陕西|辽宁|云南|广西|山西|贵州|吉林|黑龙江|甘肃|海南|新疆|内蒙古|西藏|宁夏|青海)省?[^\n，,。]{2,30}(?:路|街|道|号|室|栋|单元))',
  );
  static final RegExp _customerIdRegex = RegExp(
    r'(?:(?:客户编号|客户号|customer[_ -]?id)\s*[:：]?\s*)[A-Za-z0-9_-]{4,}',
    caseSensitive: false,
  );
  static final RegExp _sourceCodeRegex = RegExp(
    r'```(?:dart|java|python|js|javascript|ts|typescript|go|rust|c\+\+|sql)?\s*[\s\S]*?```',
    caseSensitive: false,
  );
  static final RegExp _contractRegex = RegExp(
    r'(?:(?:合同编号|合同金额|甲方|乙方|签署日期|合同期限)\s*[:：]?\s*)[^\n，,。]{2,40}',
  );

  /// 对一个字符串中的敏感信息进行脱敏，匹配到的数字串整体替换为等长 * 号。
  /// [options] 决定手机号 / 身份证号是否参与脱敏。
  static String maskText(
    String text, [
    SensitiveMaskOptions options = const SensitiveMaskOptions(),
  ]) {
    if (text.isEmpty || !options.hasAny) return text;
    var s = text;
    // 先处理身份证号（15/18 位），再处理手机号（11 位），互不重叠。
    s = _apply(s, _idCardRegex, SensitiveInfoType.idCard, options);
    s = _apply(s, _phoneRegex, SensitiveInfoType.phone, options);
    s = _apply(s, _emailRegex, SensitiveInfoType.email, options);
    s = _apply(s, _bankCardRegex, SensitiveInfoType.bankCard, options);
    s = _apply(s, _addressRegex, SensitiveInfoType.address, options);
    s = _apply(s, _customerIdRegex, SensitiveInfoType.customerId, options);
    s = _apply(s, _sourceCodeRegex, SensitiveInfoType.sourceCode, options);
    s = _apply(s, _contractRegex, SensitiveInfoType.contract, options);
    return s;
  }

  static String _apply(
    String text,
    RegExp regex,
    SensitiveInfoType type,
    SensitiveMaskOptions options,
  ) {
    if (!options.enabled(type)) return text;
    return text.replaceAllMapped(regex, (m) {
      final value = m[0] ?? '';
      switch (options.mode) {
        case SensitiveMaskMode.hash:
          return 'sha256:${sha256.convert(utf8.encode(value)).toString().substring(0, 16)}';
        case SensitiveMaskMode.block:
          return value;
      }
    });
  }

  /// 对单个消息 content 进行脱敏，兼容以下形态：
  /// - String：直接脱敏
  /// - List：OpenAI / Anthropic 多模态 content parts，
  ///   对 part 中的 text / input / input_text 字段脱敏
  static dynamic _maskContent(
    dynamic content, [
    SensitiveMaskOptions options = const SensitiveMaskOptions(),
  ]) {
    if (content is String) {
      return maskText(content, options);
    }
    if (content is List) {
      return content.map((part) {
        if (part is Map) {
          final copy = Map<String, dynamic>.from(part);
          for (final key in const ['text', 'input', 'input_text']) {
            if (copy[key] is String) {
              copy[key] = maskText(copy[key] as String, options);
            }
          }
          return copy;
        }
        return part;
      }).toList();
    }
    return content;
  }

  /// 对请求体中的 messages 进行脱敏（仅处理消息内容，不触碰工具参数、
  /// 调用 ID、时间戳等结构化字段，避免破坏请求）。
  static Map<String, dynamic> maskBody(
    Map<String, dynamic> body, [
    SensitiveMaskOptions options = const SensitiveMaskOptions(),
  ]) {
    if (!options.hasAny) return body;
    final messages = body['messages'];
    if (messages is List) {
      body['messages'] =
          messages.map((m) {
            if (m is Map<String, dynamic>) {
              final copy = Map<String, dynamic>.from(m);
              copy['content'] = _maskContent(copy['content'], options);
              final toolCalls = copy['tool_calls'];
              if (toolCalls is List) {
                copy['tool_calls'] =
                    toolCalls.map((call) {
                      if (call is! Map) return call;
                      final callCopy = Map<String, dynamic>.from(call);
                      final function = callCopy['function'];
                      if (function is Map) {
                        final functionCopy = Map<String, dynamic>.from(
                          function,
                        );
                        if (functionCopy['arguments'] is String) {
                          functionCopy['arguments'] = maskText(
                            functionCopy['arguments'] as String,
                            options,
                          );
                        }
                        callCopy['function'] = functionCopy;
                      }
                      return callCopy;
                    }).toList();
              }
              return copy;
            }
            return m;
          }).toList();
    }
    return body;
  }

  /// 通用脱敏入口：递归处理 Map / List / String，用于审计日志落盘前的兜底。
  static dynamic maskJson(
    dynamic input, [
    SensitiveMaskOptions options = const SensitiveMaskOptions(),
  ]) {
    if (!options.hasAny) return input;
    if (input is String) {
      return maskText(input, options);
    }
    if (input is Map) {
      // 若包含 messages，则按消息体结构脱敏；否则逐字段递归。
      if (input.containsKey('messages')) {
        return maskBody(Map<String, dynamic>.from(input), options);
      }
      return input.map((k, v) => MapEntry(k, maskJson(v, options)));
    }
    if (input is List) {
      return input.map((e) => maskJson(e, options)).toList();
    }
    return input;
  }
}

/// 便捷顶层函数，供中间件与日志模块直接调用。
String maskSensitiveText(
  String text, [
  SensitiveMaskOptions options = const SensitiveMaskOptions(),
]) => SensitiveMasker.maskText(text, options);

/// 便捷顶层函数：对请求体 messages 脱敏。
Map<String, dynamic> maskSensitiveBody(
  Map<String, dynamic> body, [
  SensitiveMaskOptions options = const SensitiveMaskOptions(),
]) => SensitiveMasker.maskBody(body, options);

/// 便捷顶层函数：递归脱敏任意 JSON 结构（审计日志兜底用）。
dynamic maskSensitiveJson(
  dynamic input, [
  SensitiveMaskOptions options = const SensitiveMaskOptions(),
]) => SensitiveMasker.maskJson(input, options);
