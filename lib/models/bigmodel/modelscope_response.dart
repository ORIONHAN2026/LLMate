import 'dart:convert';

/// ModelScope SSE 流式响应体（兼容 OpenAI Chat Completion Chunk 格式）
class ModelScopeResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final String? systemFingerprint;
  final List<ModelScopeChoice> choices;

  const ModelScopeResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    this.systemFingerprint,
    required this.choices,
  });

  factory ModelScopeResponse.fromJson(Map<String, dynamic> json) {
    return ModelScopeResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      systemFingerprint: json['system_fingerprint'] as String?,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => ModelScopeChoice.fromJson(e as Map<String, dynamic>))
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

class ModelScopeChoice {
  final int index;
  final ModelScopeDelta? delta;
  final String? finishReason;

  const ModelScopeChoice({
    required this.index,
    this.delta,
    this.finishReason,
  });

  factory ModelScopeChoice.fromJson(Map<String, dynamic> json) {
    return ModelScopeChoice(
      index: json['index'] as int? ?? 0,
      delta: json['delta'] != null
          ? ModelScopeDelta.fromJson(json['delta'] as Map<String, dynamic>)
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

class ModelScopeDelta {
  final String? content;
  final String? reasoningContent;
  final List<ModelScopeToolCall>? toolCalls;

  const ModelScopeDelta({
    this.content,
    this.reasoningContent,
    this.toolCalls,
  });

  factory ModelScopeDelta.fromJson(Map<String, dynamic> json) {
    return ModelScopeDelta(
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map(
              (e) => ModelScopeToolCall.fromJson(e as Map<String, dynamic>))
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

class ModelScopeToolCall {
  final int? index;
  final String? id;
  final String? type;
  final ModelScopeToolCallFunction? function;

  const ModelScopeToolCall({
    this.index,
    this.id,
    this.type,
    this.function,
  });

  factory ModelScopeToolCall.fromJson(Map<String, dynamic> json) {
    return ModelScopeToolCall(
      index: json['index'] as int?,
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: json['function'] != null
          ? ModelScopeToolCallFunction.fromJson(
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

class ModelScopeToolCallFunction {
  final String? name;
  final String? arguments;

  const ModelScopeToolCallFunction({this.name, this.arguments});

  factory ModelScopeToolCallFunction.fromJson(Map<String, dynamic> json) {
    return ModelScopeToolCallFunction(
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
