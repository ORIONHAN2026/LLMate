import 'dart:convert';

/// 阿里云百炼 SSE 流式响应体（兼容 OpenAI Chat Completion Chunk 格式）
class QwenResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final String? systemFingerprint;
  final List<QwenChoice> choices;

  const QwenResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    this.systemFingerprint,
    required this.choices,
  });

  factory QwenResponse.fromJson(Map<String, dynamic> json) {
    return QwenResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      systemFingerprint: json['system_fingerprint'] as String?,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => QwenChoice.fromJson(e as Map<String, dynamic>))
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

class QwenChoice {
  final int index;
  final QwenDelta? delta;
  final String? finishReason;

  const QwenChoice({
    required this.index,
    this.delta,
    this.finishReason,
  });

  factory QwenChoice.fromJson(Map<String, dynamic> json) {
    return QwenChoice(
      index: json['index'] as int? ?? 0,
      delta: json['delta'] != null
          ? QwenDelta.fromJson(json['delta'] as Map<String, dynamic>)
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

class QwenDelta {
  final String? content;
  final String? reasoningContent;
  final List<QwenToolCall>? toolCalls;

  const QwenDelta({
    this.content,
    this.reasoningContent,
    this.toolCalls,
  });

  factory QwenDelta.fromJson(Map<String, dynamic> json) {
    return QwenDelta(
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map(
              (e) => QwenToolCall.fromJson(e as Map<String, dynamic>))
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

class QwenToolCall {
  final int? index;
  final String? id;
  final String? type;
  final QwenToolCallFunction? function;

  const QwenToolCall({
    this.index,
    this.id,
    this.type,
    this.function,
  });

  factory QwenToolCall.fromJson(Map<String, dynamic> json) {
    return QwenToolCall(
      index: json['index'] as int?,
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: json['function'] != null
          ? QwenToolCallFunction.fromJson(
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

class QwenToolCallFunction {
  final String? name;
  final String? arguments;

  const QwenToolCallFunction({this.name, this.arguments});

  factory QwenToolCallFunction.fromJson(Map<String, dynamic> json) {
    return QwenToolCallFunction(
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
