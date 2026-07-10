import 'dart:convert';

import 'openai_response.dart' show OpenAIDelta;

/// 单个 SSE Chunk（OpenAI Chat Completion Chunk 格式）
///
/// 对应报文示例：
/// ```json
/// {
///   "id": "668f500d94a042738f0f3843ccd6c647",
///   "choices": [{
///     "delta": {"content": "...", "role": null, "tool_calls": null, "reasoning_content": null},
///     "finish_reason": null,
///     "index": 0
///   }],
///   "created": 1783576643,
///   "model": "mimo-v2.5-pro",
///   "object": "chat.completion.chunk"
/// }
/// ```
class Chunk {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChunkChoice> choices;
  final ChunkUsage? usage;

  const Chunk({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory Chunk.fromJson(Map<String, dynamic> json) {
    return Chunk(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      choices:
          (json['choices'] as List<dynamic>?)
              ?.map((e) => ChunkChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usage:
          json['usage'] != null
              ? ChunkUsage.fromJson(json['usage'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'object': object,
    'created': created,
    'model': model,
    'choices': choices.map((e) => e.toJson()).toList(),
    if (usage != null) 'usage': usage!.toJson(),
  };

  /// 是否为流结束信号 [DONE]
  bool get isDone => false;

  /// 从原始字节流解析（UTF-8 解码后调用 [fromString]）
  factory Chunk.fromIntList(List<int> bytes) {
    final raw = utf8.decode(bytes, allowMalformed: true);
    return Chunk.fromString(raw);
  }

  /// 从 data: 行直接解析（兼容 "data: {...}" 字符串）
  static Chunk? tryParse(String dataLine) {
    final trimmed = dataLine.trim();
    if (!trimmed.startsWith('data: ')) return null;
    final dataStr = trimmed.substring(6).trim();
    if (dataStr == '[DONE]') return null;
    try {
      final json = jsonDecode(dataStr) as Map<String, dynamic>;
      return Chunk.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 从 JSON 字符串或 SSE data 行解析
  ///
  /// 支持两种输入：
  /// - 完整 JSON 字符串：`{"id":"...","choices":[...]}`
  /// - SSE data 行：`data: {"id":"...","choices":[...]}`
  factory Chunk.fromString(String raw) {
    final trimmed = raw.trim();
    final jsonStr =
        trimmed.startsWith('data: ') ? trimmed.substring(6).trim() : trimmed;
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return Chunk.fromJson(json);
  }

  /// 转换为 SSE data 行格式：`data: {...}\n\n`
  String toSseString() => 'data: ${jsonEncode(toJson())}\n\n';

  /// 转换为原始字节流（UTF-8 编码的 SSE data 行），与 [fromIntList] 对称
  List<int> toIntList() => utf8.encode(toSseString());

  @override
  String toString() => toSseString();
}

/// Chunk 中的单个 choice
class ChunkChoice {
  final int index;
  final OpenAIDelta? delta;
  final String? finishReason;

  const ChunkChoice({required this.index, this.delta, this.finishReason});

  factory ChunkChoice.fromJson(Map<String, dynamic> json) {
    return ChunkChoice(
      index: json['index'] as int? ?? 0,
      delta:
          json['delta'] != null
              ? OpenAIDelta.fromJson(json['delta'] as Map<String, dynamic>)
              : null,
      finishReason: json['finish_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    if (delta != null) 'delta': delta!.toJson(),
    'finish_reason': finishReason,
  };

  @override
  String toString() => jsonEncode(toJson());
}

/// Chunk 中的 token 用量信息
class ChunkUsage {
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final CompletionTokensDetails? completionTokensDetails;
  final PromptTokensDetails? promptTokensDetails;

  const ChunkUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.completionTokensDetails,
    this.promptTokensDetails,
  });

  factory ChunkUsage.fromJson(Map<String, dynamic> json) {
    return ChunkUsage(
      promptTokens: json['prompt_tokens'] as int?,
      completionTokens: json['completion_tokens'] as int?,
      totalTokens: json['total_tokens'] as int?,
      completionTokensDetails:
          json['completion_tokens_details'] != null
              ? CompletionTokensDetails.fromJson(
                json['completion_tokens_details'] as Map<String, dynamic>,
              )
              : null,
      promptTokensDetails:
          json['prompt_tokens_details'] != null
              ? PromptTokensDetails.fromJson(
                json['prompt_tokens_details'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (promptTokens != null) 'prompt_tokens': promptTokens,
    if (completionTokens != null) 'completion_tokens': completionTokens,
    if (totalTokens != null) 'total_tokens': totalTokens,
    if (completionTokensDetails != null)
      'completion_tokens_details': completionTokensDetails!.toJson(),
    if (promptTokensDetails != null)
      'prompt_tokens_details': promptTokensDetails!.toJson(),
  };

  @override
  String toString() => jsonEncode(toJson());
}

class CompletionTokensDetails {
  final int? reasoningTokens;

  const CompletionTokensDetails({this.reasoningTokens});

  factory CompletionTokensDetails.fromJson(Map<String, dynamic> json) {
    return CompletionTokensDetails(
      reasoningTokens: json['reasoning_tokens'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (reasoningTokens != null) 'reasoning_tokens': reasoningTokens,
  };
}

class PromptTokensDetails {
  final int? cachedTokens;

  const PromptTokensDetails({this.cachedTokens});

  factory PromptTokensDetails.fromJson(Map<String, dynamic> json) {
    return PromptTokensDetails(cachedTokens: json['cached_tokens'] as int?);
  }

  Map<String, dynamic> toJson() => {
    if (cachedTokens != null) 'cached_tokens': cachedTokens,
  };
}
