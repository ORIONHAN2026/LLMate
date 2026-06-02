import 'package:flutter/foundation.dart';

/// 流式工具调用拦截状态机
///
/// 在 LLM 流式输出过程中实时拦截工具调用标签（如 `<tool_calls>`、`<|tool_calls|>`、
/// `<\uff5ctool_calls>` 等），防止这些标签内容泄露到前端 UI。
///
/// 三种核心状态：
/// - [StreamFilterState.text]：正文状态，正常放行
/// - [StreamFilterState.buffer]：匹配中状态，可能遇到标签开头，先缓存不发
/// - [StreamFilterState.tool]：工具调用状态，死死扣住不发
///
/// 状态转换事件通过 [StreamFilterResult.transitions] 传递给调用方，
/// 调用方可据此向 UI 层发送实时进展信息（通过 tool 字段）。
class StreamToolCallFilter {
  StreamFilterState _state = StreamFilterState.text;
  final StringBuffer _holdBuffer = StringBuffer();

  /// 当前 feed 调用期间累积的状态转换事件
  final List<StreamFilterTransition> _transitions = [];

  /// 需要拦截的标签开头模式（按长度降序排列，优先匹配更长的模式）
  static const List<_TagPattern> _openPatterns = [
    // <\uff5ctool_calls> 系列（全角竖线 + DSML，含内层标签）
    _TagPattern('<\uff5ctool_calls>'),
    _TagPattern('<\uff5cinvoke'),
    _TagPattern('<\uff5cparameter'),
    _TagPattern('<\uff5carguments'),
    // <|tool_calls|> 系列（含内层标签）
    _TagPattern('<|tool_calls|>'),
    _TagPattern('<|invoke'),
    _TagPattern('<|parameter'),
    _TagPattern('<|arguments'),
    // <tool_calls> 标准 XML
    _TagPattern('<tool_calls'),
    // <|tool_call|> 变体
    _TagPattern('<|tool_call|>'),
    // <tool_call 变体
    _TagPattern('<tool_call'),
    // 内层标签（模型可能不包外层 tool_calls，直接输出）
    _TagPattern('<invoke'),
    _TagPattern('<parameter'),
    _TagPattern('<arguments'),
  ];

  /// 闭合标签模式
  static const List<_TagPattern> _closePatterns = [
    // 全角竖线 / DSML
    _TagPattern('</\uff5ctool_calls>'),
    _TagPattern('</\uff5cinvoke>'),
    _TagPattern('</\uff5cparameter>'),
    _TagPattern('</\uff5carguments>'),
    // 管道符分隔
    _TagPattern('</|tool_calls|>'),
    _TagPattern('</|tool_call|>'),
    _TagPattern('</|invoke|>'),
    _TagPattern('</|parameter|>'),
    _TagPattern('</|arguments|>'),
    // 标准 XML
    _TagPattern('</tool_calls>'),
    _TagPattern('</tool_call'),
    _TagPattern('</invoke>'),
    _TagPattern('</parameter>'),
    _TagPattern('</arguments>'),
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
  StreamFilterResult feed(String chunk) {
    if (chunk.isEmpty) {
      return const StreamFilterResult(
        cleanText: '',
        isInToolCall: false,
        transitions: [],
      );
    }

    _transitions.clear();
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
      transitions: List.unmodifiable(_transitions),
    );
  }

  /// 处理 TEXT 状态下的字符
  void _handleTextChar(String char, StringBuffer cleanOutput) {
    if (char == '<') {
      // 可能是工具调用标签的开头，切换到 BUFFER 状态
      _holdBuffer.clear();
      _holdBuffer.write(char);
      _transition(StreamFilterTransition.enteredBuffer);
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
      _holdBuffer.clear();
      _transition(StreamFilterTransition.confirmedTool);
      if (kDebugMode) {
        debugPrint('\u{1F3AF} [StreamFilter] 检测到工具调用标签: $held');
      }
      return;
    }

    // 2) 检查当前 buffer 是否还有可能是某个 pattern 的前缀
    if (_couldBeOpenPrefix(held)) {
      // 仍然可能是某个 pattern 的前缀，继续等待
      return;
    }

    // 3) 确认不是工具调用标签 → 将缓存内容放行，回到 TEXT 状态
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
      _transition(StreamFilterTransition.bufferCancelled);
    }
  }

  /// 处理 TOOL 状态下的字符
  ///
  /// 使用滑动窗口保留最近的字符用于匹配闭合标签。
  /// 窗口大小为 `_maxCloseTagLength + chunk 最大长度`，确保闭合标签
  /// 即使跨 chunk 到达也不会被截断。
  void _handleToolChar(String char) {
    _holdBuffer.write(char);

    // 滑动窗口：保留足够多的尾部字符以匹配闭合标签
    // 必须保留至少 _maxCloseTagLength + 一个合理余量
    // （防止闭合标签跨 chunk 到达时前半部分被截断）
    final maxLen = _maxCloseTagLength;
    if (_holdBuffer.length > maxLen + 256) {
      // 保留最后 (maxLen + 256) 个字符
      // 256 的余量确保即使闭合标签前半部分在上一个 chunk 末尾开始，
      // 也能在当前缓冲区中完整保留
      final current = _holdBuffer.toString();
      _holdBuffer.clear();
      _holdBuffer.write(current.substring(current.length - maxLen - 256));
    }

    final held = _holdBuffer.toString();

    // 检查是否匹配到闭合标签
    for (final pattern in _closePatterns) {
      if (held.endsWith(pattern.prefix)) {
        _holdBuffer.clear();
        _transition(StreamFilterTransition.toolClosed);
        if (kDebugMode) {
          debugPrint('\u{1F3AF} [StreamFilter] 工具调用标签闭合，恢复正文状态');
        }
        return;
      }
    }
  }

  /// 检查 held 字符串是否匹配某个 open pattern
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

  /// 执行状态转换，同时记录转换事件
  void _transition(StreamFilterTransition transition) {
    switch (transition) {
      case StreamFilterTransition.enteredBuffer:
        _state = StreamFilterState.buffer;
      case StreamFilterTransition.confirmedTool:
        _state = StreamFilterState.tool;
      case StreamFilterTransition.bufferCancelled:
        _state = StreamFilterState.text;
      case StreamFilterTransition.toolClosed:
        _state = StreamFilterState.text;
    }
    _transitions.add(transition);
  }

  /// 流结束时刷出缓存中剩余的内容
  StreamFilterResult flush() {
    final held = _holdBuffer.toString();
    final previousState = _state;
    _holdBuffer.clear();
    _state = StreamFilterState.text;

    if (held.isEmpty) {
      return const StreamFilterResult(
        cleanText: '',
        isInToolCall: false,
        transitions: [],
      );
    }

    // TOOL 状态结束 → 丢弃
    if (previousState == StreamFilterState.tool) {
      return const StreamFilterResult(
        cleanText: '',
        isInToolCall: false,
        transitions: [],
      );
    }

    // BUFFER 状态结束 → 放行缓存内容
    return StreamFilterResult(
      cleanText: held,
      isInToolCall: false,
      transitions: previousState == StreamFilterState.buffer
          ? [StreamFilterTransition.bufferCancelled]
          : [],
    );
  }

  /// 重置状态机
  void reset() {
    _state = StreamFilterState.text;
    _holdBuffer.clear();
    _transitions.clear();
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

/// 状态转换事件
enum StreamFilterTransition {
  /// TEXT → BUFFER：收到 `<`，可能进入工具调用标签
  enteredBuffer,

  /// BUFFER → TOOL：确认匹配到工具调用标签开头
  confirmedTool,

  /// BUFFER → TEXT：匹配失败，之前的 `<` 不是工具调用标签（误报）
  bufferCancelled,

  /// TOOL → TEXT：工具调用标签闭合，回到正文
  toolClosed,
}

/// 过滤结果
class StreamFilterResult {
  /// 放行给前端的干净文本
  final String cleanText;

  /// 是否正在工具调用中
  final bool isInToolCall;

  /// 本次 feed 期间发生的状态转换事件列表
  final List<StreamFilterTransition> transitions;

  const StreamFilterResult({
    required this.cleanText,
    required this.isInToolCall,
    required this.transitions,
  });
}

/// 标签模式（用于模式匹配）
class _TagPattern {
  final String prefix;
  const _TagPattern(this.prefix);
}
