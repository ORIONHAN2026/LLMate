import '../models/chat/chat_message.dart';
import '../models/chat/chat_session.dart';
import 'memory_service.dart';

/// MemoryProviderMixin
/// 
/// 为BaseLlmProvider添加记忆功能的mixin
/// 自动在消息构建时注入相关记忆
mixin MemoryProviderMixin {
  MemoryService? _memoryService;

  /// 设置记忆服务
  void setMemoryService(MemoryService service) {
    _memoryService = service;
  }

  /// 获取记忆服务
  MemoryService? get memoryService => _memoryService;

  /// 是否启用记忆
  bool get memoryEnabled => _memoryService?.isInitialized ?? false;

  /// 构建带记忆的messages
  /// 
  /// 在原有buildMessages基础上，添加：
  /// 1. 召回的L1记忆（追加到用户消息前）
  /// 2. L3人物画像（追加到系统提示词）
  Future<List<Map<String, dynamic>>> buildMessagesWithMemory({
    required ChatMessage userMessage,
    required ChatSession session,
    required List<Map<String, dynamic>> Function() baseBuilder,
  }) async {
    // 获取基础消息列表
    final messages = baseBuilder();

    if (!memoryEnabled || _memoryService == null) {
      return messages;
    }

    try {
      // 执行记忆召回
      final recallResult = await _memoryService!.recall(
        userText: userMessage.content,
        sessionKey: session.sessionId,
        userId: 'user_${session.sessionId}',
      );

      // 如果有相关记忆，修改用户消息
      if (recallResult.relevantMemories.isNotEmpty) {
        final memoryContext = recallResult.formattedMemoryContext;
        final enhancedContent = '$memoryContext\n\n## 当前问题\n${userMessage.content}';

        // 找到并替换最后一条用户消息
        for (var i = messages.length - 1; i >= 0; i--) {
          if (messages[i]['role'] == 'user') {
            messages[i] = {
              ...messages[i],
              'content': enhancedContent,
            };
            break;
          }
        }
      }

      // 如果有系统上下文追加，添加到第一条系统消息或创建新的
      if (recallResult.systemContextAppend != null &&
          recallResult.systemContextAppend!.isNotEmpty) {
        final systemAppend = recallResult.systemContextAppend!;

        // 查找是否已有系统消息
        var hasSystem = false;
        for (var i = 0; i < messages.length; i++) {
          if (messages[i]['role'] == 'system') {
            final existingContent = messages[i]['content'] as String? ?? '';
            messages[i] = {
              ...messages[i],
              'content': '$existingContent\n\n$systemAppend',
            };
            hasSystem = true;
            break;
          }
        }

        // 如果没有系统消息，在开头添加
        if (!hasSystem) {
          messages.insert(0, {
            'role': 'system',
            'content': systemAppend,
          });
        }
      }
    } catch (e) {
      // 记忆召回失败不影响正常对话
      if (debugMode) {
        print('Memory recall failed: $e');
      }
    }

    return messages;
  }

  /// 捕获对话回合
  /// 
  /// 在AI回复完成后调用，保存到L0
  Future<void> captureConversationTurn({
    required ChatSession session,
    required ChatMessage userMessage,
    required String assistantResponse,
    required List<Map<String, dynamic>> fullMessages,
  }) async {
    if (!memoryEnabled || _memoryService == null) return;

    try {
      await _memoryService!.captureTurn(
        sessionKey: session.sessionId,
        sessionId: session.sessionId,
        userText: userMessage.content,
        assistantText: assistantResponse,
        messages: fullMessages,
      );
    } catch (e) {
      if (debugMode) {
        print('Memory capture failed: $e');
      }
    }
  }

  bool get debugMode => false;
}
