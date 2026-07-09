import 'dart:convert';

/// OpenAI SSE 流式响应体（兼容 OpenAI Chat Completion Chunk 格式）
class OpenAIResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final String? systemFingerprint;
  final List<OpenAIChoice> choices;

  const OpenAIResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    this.systemFingerprint,
    required this.choices,
  });

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) {
    return OpenAIResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      systemFingerprint: json['system_fingerprint'] as String?,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => OpenAIChoice.fromJson(e as Map<String, dynamic>))
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

class OpenAIChoice {
  final int index;
  final OpenAIDelta? delta;
  final String? finishReason;

  const OpenAIChoice({
    required this.index,
    this.delta,
    this.finishReason,
  });

  factory OpenAIChoice.fromJson(Map<String, dynamic> json) {
    return OpenAIChoice(
      index: json['index'] as int? ?? 0,
      delta: json['delta'] != null
          ? OpenAIDelta.fromJson(json['delta'] as Map<String, dynamic>)
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

class OpenAIDelta {
  final String? role;
  final String? content;
  final String? reasoningContent;
  final List<ToolCall>? toolCalls;

  const OpenAIDelta({
    this.role,
    this.content,
    this.reasoningContent,
    this.toolCalls,
  });

  factory OpenAIDelta.fromJson(Map<String, dynamic> json) {
    return OpenAIDelta(
      role: json['role'] as String?,
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map(
              (e) => ToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (role != null) 'role': role,
        if (content != null) 'content': content,
        if (reasoningContent != null) 'reasoning_content': reasoningContent,
        if (toolCalls != null)
          'tool_calls': toolCalls!.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

class ToolCall {
  final int? index;
  final String? id;
  final String? type;
  final ToolCallFunction? function;

  const ToolCall({
    this.index,
    this.id,
    this.type,
    this.function,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      index: json['index'] as int?,
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: json['function'] != null
          ? ToolCallFunction.fromJson(
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

class ToolCallFunction {
  final String? name;
  final String? arguments;

  const ToolCallFunction({this.name, this.arguments});

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) {
    return ToolCallFunction(
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
