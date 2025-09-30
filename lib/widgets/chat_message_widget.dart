import '../models/chat/chat_message.dart';

// 重新生成操作类型枚举
enum RegenerateActionType {
  regenerate, // 重新生成
  regenerateFromHere, // 从此处重新生成
  regenerateThisReply, // 重新生成此回复
  regenerateLastReply, // 重新生成最后一条回复
}

// 重新生成回调函数类型定义
typedef RegenerateCallback =
    void Function(
      RegenerateActionType action,
      ChatMessage message,
      List<ChatMessage> allMessages,
    );

// 会话更新回调函数类型定义
typedef SessionUpdateCallback = void Function(List<ChatMessage> messages);

// AI消息编辑回调函数类型定义
typedef EditAiMessageCallback =
    void Function(ChatMessage message, String newContent);

// 消息操作类型定义
enum MessageActionType {
  delete,
  edit,
  deleteReply,
  createNewSessionFromMessage,
  screenshotEntireConversation,
  screenshotCurrentRound,
  screenshotCurrentMessage,
}

// 具体的消息操作回调类型定义
typedef DeleteMessageCallback = void Function(ChatMessage message);
typedef EditUserMessageCallback = void Function(String content);
typedef DeleteReplyCallback = void Function(ChatMessage message);
typedef CreateNewSessionCallback = void Function(ChatMessage message);
typedef ScreenshotCallback = void Function(ChatMessage message, String type);
