import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';

/// 工作模式策略接口
///
/// 每种 workMode（conversation/contract/invoice/chatroom）对应一个实现类，
/// 负责该模式下的消息组装、系统提示词注入和工具列表构建。
abstract class WorkModeStrategy {
  /// 模式名称
  String get modeName;

  /// 构建完整的消息列表（系统提示词 + 历史消息 + 用户消息）
  ///
  /// 由 OpenAiProvider 在发送请求前调用。
  Future<List<Map<String, dynamic>>> buildMessages({
    required ChatModel? model,
    required ChatMessage userMessage,
    required ChatSession session,
  });

  /// 构建该模式下可用的工具列表（OpenAI function-calling 格式）
  List<Map<String, dynamic>> buildTools(ChatSession? session);
}
