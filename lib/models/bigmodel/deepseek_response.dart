import 'dart:convert';

/// DeepSeek SSE 流式响应体（兼容 OpenAI Chat Completion Chunk 格式）
///
/// 示例：
/// ```json
/// {
///   "id": "8b415da0-...",
///   "object": "chat.completion.chunk",
///   "created": 1780391398,
///   "model": "deepseek-v4-flash",
///   "system_fingerprint": "fp_...",
///   "choices": [{
///     "index": 0,
///     "delta": {"content": "tool"},
///     "logprobs": null,
///     "finish_reason": null
///   }]
/// }
/// ```
class DeepSeekResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final String? systemFingerprint;
  final List<DeepSeekChoice> choices;

  const DeepSeekResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    this.systemFingerprint,
    required this.choices,
  });

  factory DeepSeekResponse.fromJson(Map<String, dynamic> json) {
    return DeepSeekResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      systemFingerprint: json['system_fingerprint'] as String?,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => DeepSeekChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'object': object,
        'created': created,
        'model': model,
        if (systemFingerprint != null)
          'system_fingerprint': systemFingerprint,
        'choices': choices.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

/// 单个 choice
class DeepSeekChoice {
  final int index;
  final DeepSeekDelta? delta;
  final String? finishReason;

  const DeepSeekChoice({
    required this.index,
    this.delta,
    this.finishReason,
  });

  factory DeepSeekChoice.fromJson(Map<String, dynamic> json) {
    return DeepSeekChoice(
      index: json['index'] as int? ?? 0,
      delta: json['delta'] != null
          ? DeepSeekDelta.fromJson(json['delta'] as Map<String, dynamic>)
          : null,
      finishReason: json['finish_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        if (delta != null) 'delta': delta!.toJson(),
        'logprobs': null,
        'finish_reason': finishReason,
      };

  @override
  String toString() => jsonEncode(toJson());
}

/// delta 增量内容
class DeepSeekDelta {
  final String? content;
  final String? reasoningContent;
  final List<DeepSeekToolCall>? toolCalls;

  const DeepSeekDelta({
    this.content,
    this.reasoningContent,
    this.toolCalls,
  });

  factory DeepSeekDelta.fromJson(Map<String, dynamic> json) {
    return DeepSeekDelta(
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map(
              (e) => DeepSeekToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (content != null) 'content': content,
        if (reasoningContent != null) 'reasoning_content': reasoningContent,
        if (toolCalls != null)
          'tool_calls': toolCalls!.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

/// 工具调用
class DeepSeekToolCall {
  final int? index;
  final String? id;
  final String? type;
  final DeepSeekToolCallFunction? function;

  const DeepSeekToolCall({
    this.index,
    this.id,
    this.type,
    this.function,
  });

  factory DeepSeekToolCall.fromJson(Map<String, dynamic> json) {
    return DeepSeekToolCall(
      index: json['index'] as int?,
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: json['function'] != null
          ? DeepSeekToolCallFunction.fromJson(
              json['function'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (index != null) 'index': index,
        if (id != null) 'id': id,
        if (type != null) 'type': type,
        if (function != null) 'function': function!.toJson(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

/// 工具调用函数详情
class DeepSeekToolCallFunction {
  final String? name;
  final String? arguments;

  const DeepSeekToolCallFunction({this.name, this.arguments});

  factory DeepSeekToolCallFunction.fromJson(Map<String, dynamic> json) {
    return DeepSeekToolCallFunction(
      name: json['name'] as String?,
      arguments: json['arguments'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (arguments != null) 'arguments': arguments,
      };

  @override
  String toString() => jsonEncode(toJson());
}
