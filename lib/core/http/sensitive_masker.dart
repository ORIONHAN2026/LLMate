/// 脱敏选项：分别控制手机号、身份证号是否脱敏
///
/// 由大模型设置（[ChatModel.maskPhone] / [ChatModel.maskIdCard]）驱动，
/// 仅当对应开关开启时才对匹配到的敏感信息进行 * 号替换。
class SensitiveMaskOptions {
  /// 是否脱敏手机号
  final bool maskPhone;

  /// 是否脱敏身份证号
  final bool maskIdCard;

  const SensitiveMaskOptions({
    this.maskPhone = false,
    this.maskIdCard = false,
  });

  /// 两者均未开启
  static const SensitiveMaskOptions disabled =
      SensitiveMaskOptions(maskPhone: false, maskIdCard: false);

  /// 是否至少有一项需要脱敏
  bool get hasAny => maskPhone || maskIdCard;
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
  static final RegExp _idCardRegex =
      RegExp(r'\b(?:\d{15}|\d{17}[\dXx])\b');

  /// 对一个字符串中的敏感信息进行脱敏，匹配到的数字串整体替换为等长 * 号。
  /// [options] 决定手机号 / 身份证号是否参与脱敏。
  static String maskText(String text, [SensitiveMaskOptions options = const SensitiveMaskOptions()]) {
    if (text.isEmpty || !options.hasAny) return text;
    var s = text;
    // 先处理身份证号（15/18 位），再处理手机号（11 位），互不重叠。
    if (options.maskIdCard) {
      s = s.replaceAllMapped(_idCardRegex, (m) => '*' * m[0]!.length);
    }
    if (options.maskPhone) {
      s = s.replaceAllMapped(_phoneRegex, (m) => '*' * m[0]!.length);
    }
    return s;
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
      body['messages'] = messages.map((m) {
        if (m is Map<String, dynamic>) {
          final copy = Map<String, dynamic>.from(m);
          copy['content'] = _maskContent(copy['content'], options);
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
]) =>
    SensitiveMasker.maskText(text, options);

/// 便捷顶层函数：对请求体 messages 脱敏。
Map<String, dynamic> maskSensitiveBody(
  Map<String, dynamic> body, [
  SensitiveMaskOptions options = const SensitiveMaskOptions(),
]) =>
    SensitiveMasker.maskBody(body, options);

/// 便捷顶层函数：递归脱敏任意 JSON 结构（审计日志兜底用）。
dynamic maskSensitiveJson(
  dynamic input, [
  SensitiveMaskOptions options = const SensitiveMaskOptions(),
]) =>
    SensitiveMasker.maskJson(input, options);
