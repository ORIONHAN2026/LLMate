import 'package:flutter/foundation.dart';

/// 流式工具调用拦截状态机
///
/// 在 LLM 流式输出过程中实时拦截工具调用标签（如 `<tool_calls>`、`<|tool_calls|>`、
/// `<｜｜DSML｜｜tool_calls>` 等），防止这些标签内容泄露到前端 UI。
///
/// 三种核心状态：
/// - [StreamFilterState.text]：正文状态，正常放行
/// - [StreamFilterState.buffer]：匹配中状态，可能遇到标签开头，先缓存不发
/// - [StreamFilterState.tool]：工具调用状态，死死扣住不发
///
/// 使用方式：
/// ```dart
/// final filter = StreamToolCallFilter();
/// for (final chunk in contentChunks) {
///   final result = filter.feed(chunk);
///   // result.cleanText → 放行给前端
///   // result.isInToolCall → 是否正在工具调用中
/// }
/// final leftover = filter.flush(); // 流结束时刷出缓存
/// ```
class StreamToolCallFilter {
  StreamFilterState _state = StreamFilterState.text;
  final StringBuffer _holdBuffer = StringBuffer();

  /// 需要拦截的标签开头模式（按长度降序排列，优先匹配更长的模式）
  static const List<_TagPattern> _openPatterns = [
    // <｜｜DSML｜｜tool_calls> 系列（全角竖线 + DSML）
    _TagPattern('<｜｜DSML｜｜tool_calls>'),
    // <|tool_calls|> 系列
    _TagPattern('<|tool_calls|>'),
    // <tool_calls> 标准 XML
    _TagPattern('<tool_calls'),
    // <|tool_call|> 变体
    _TagPattern('<|tool_call|>'),
    // <tool_call 变体
    _TagPattern('<tool_call'),
  ];

  /// 闭合标签模式
  static const List<_TagPattern> _closePatterns = [
    _TagPattern('</｜｜DSML｜｜tool_calls>'),
    _TagPattern('</|tool_calls|>'),
    _TagPattern('</tool_calls>'),
    _TagPattern('</|tool_call|>'),
    _TagPattern('</tool_call'),
  ];

  /// 闭合标签的最大长度（用于 TOOL 状态下的滑动窗口）
  static int get _maxCloseTagLength {
    int maxLen = 0;
    for (final p in _closePatterns) {
      if (p.prefix.length > maxLen) maxLen = p.prefix.length;
    }
    return maxLen;
  }

  /// 当前状态
  StreamFilterState get state => _state;

  /// 向状态机输入一段文本，返回过滤结果
  ///
  /// 每次调用 [feed] 时，状态机根据输入内容切换状态并决定哪些文本放行、哪些扣留。
  StreamFilterResult feed(String chunk) {
    if (chunk.isEmpty) return const StreamFilterResult(cleanText: '', isInToolCall: false);

    final cleanOutput = StringBuffer();

    for (int i = 0; i < chunk.length; i++) {
      final char = chunk[i];

      switch (_state) {
        case StreamFilterState.text:
          _handleTextChar(char, cleanOutput);
        case StreamFilterState.buffer:
          _handleBufferChar(char, cleanOutput);
        case StreamFilterState.tool:
          _handleToolChar(char);
      }
    }

    return StreamFilterResult(
      cleanText: cleanOutput.toString(),
      isInToolCall: _state == StreamFilterState.tool,
    );
  }

  /// 处理 TEXT 状态下的字符
  void _handleTextChar(String char, StringBuffer cleanOutput) {
    if (char == '<') {
      // 可能是工具调用标签的开头，切换到 BUFFER 状态
      _holdBuffer.clear();
      _holdBuffer.write(char);
      _state = StreamFilterState.buffer;
    } else {
      cleanOutput.write(char);
    }
  }

  /// 处理 BUFFER 状态下的字符
  void _handleBufferChar(String char, StringBuffer cleanOutput) {
    _holdBuffer.write(char);
    final held = _holdBuffer.toString();

    // 1) 检查是否已经完整匹配到某个 open pattern → 切换到 TOOL 状态
    if (_matchesOpenPattern(held)) {
      _state = StreamFilterState.tool;
      _holdBuffer.clear();
      if (kDebugMode) {
        debugPrint('🎯 [StreamFilter] 检测到工具调用标签: $held');
      }
      return;
    }

    // 2) 检查当前 buffer 是否还有可能是某个 pattern 的前缀
    if (_couldBeOpenPrefix(held)) {
      // 仍然可能是某个 pattern 的前缀，继续等待
      return;
    }

    // 3) 确认不是工具调用标签 → 将缓存内容放行，回到 TEXT 状态
    //    但需要注意：缓存中可能包含新的 `<`（如 `<a<tool_calls>`），
    //    需要回溯找到最后一个 `<` 并重新开始匹配
    final lastLtIndex = held.lastIndexOf('<');
    if (lastLtIndex > 0) {
      // 放行最后一个 `<` 之前的内容
      cleanOutput.write(held.substring(0, lastLtIndex));
      // 将最后一个 `<` 及之后的内容作为新的 buffer
      _holdBuffer.clear();
      _holdBuffer.write(held.substring(lastLtIndex));
      // 保持 BUFFER 状态继续匹配
    } else {
      // 没有 `<` 或 `<` 就在开头 → 全部放行
      cleanOutput.write(held);
      _holdBuffer.clear();
      _state = StreamFilterState.text;
    }
  }

  /// 处理 TOOL 状态下的字符
  /// 只追踪最近的字符用于匹配闭合标签，避免缓存无限增长
  void _handleToolChar(String char) {
    _holdBuffer.write(char);

    // 只保留最近 maxCloseTagLength 个字符用于匹配闭合标签
    // 这样避免长工具调用时 _holdBuffer 无限增长
    final maxLen = _maxCloseTagLength;
    if (_holdBuffer.length > maxLen * 2) {
      // 安全地截断：保留最近 maxLen*2 个字符
      final current = _holdBuffer.toString();
      _holdBuffer.clear();
      _holdBuffer.write(current.substring(current.length - maxLen));
    }

    final held = _holdBuffer.toString();

    // 检查是否匹配到闭合标签
    for (final pattern in _closePatterns) {
      if (held.endsWith(pattern.prefix)) {
        // 完全匹配到闭合标签 → 回到 TEXT 状态
        _state = StreamFilterState.text;
        _holdBuffer.clear();
        if (kDebugMode) {
          debugPrint('🎯 [StreamFilter] 工具调用标签闭合，恢复正文状态');
        }
        return;
      }
    }
    // 还在工具调用中，继续扣留
  }

  /// 检查 held 字符串是否匹配某个 open pattern
  /// 即 held 以某个 open pattern 的 prefix 开头（允许标签后有属性等）
  bool _matchesOpenPattern(String held) {
    for (final pattern in _openPatterns) {
      if (held.startsWith(pattern.prefix)) return true;
    }
    return false;
  }

  /// 检查 held 是否仍然可能是某个 open pattern 的前缀
  bool _couldBeOpenPrefix(String held) {
    for (final pattern in _openPatterns) {
      if (pattern.prefix.startsWith(held)) return true;
    }
    return false;
  }

  /// 流结束时刷出缓存中剩余的内容
  ///
  /// 如果流结束时仍在 BUFFER 状态，说明之前缓存的 `<` 实际上不是标签开头，
  /// 需要将缓存内容放行。如果在 TOOL 状态，说明标签未闭合，丢弃缓存。
  StreamFilterResult flush() {
    final held = _holdBuffer.toString();
    final previousState = _state;
    _holdBuffer.clear();
    _state = StreamFilterState.text;

    if (held.isEmpty) return const StreamFilterResult(cleanText: '', isInToolCall: false);

    // TOOL 状态结束 → 丢弃（未闭合的工具调用标签，不应泄露到前端）
    if (previousState == StreamFilterState.tool) {
      return const StreamFilterResult(cleanText: '', isInToolCall: false);
    }

    // BUFFER 状态结束 → 放行缓存内容（之前的 < 不是标签开头）
    return StreamFilterResult(cleanText: held, isInToolCall: false);
  }

  /// 重置状态机
  void reset() {
    _state = StreamFilterState.text;
    _holdBuffer.clear();
  }
}

/// 状态机状态
enum StreamFilterState {
  /// 正文状态：正常放行
  text,

  /// 匹配中状态：收到标签开头特征，缓存不发
  buffer,

  /// 工具调用状态：确定在标签内，扣留不发
  tool,
}

/// 过滤结果
class StreamFilterResult {
  /// 放行给前端的干净文本
  final String cleanText;

  /// 是否正在工具调用中
  final bool isInToolCall;

  const StreamFilterResult({required this.cleanText, required this.isInToolCall});
}

/// 标签模式（用于模式匹配）
class _TagPattern {
  final String prefix;
  const _TagPattern(this.prefix);
}
