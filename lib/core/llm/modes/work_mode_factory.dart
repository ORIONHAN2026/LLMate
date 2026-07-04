import './work_mode_strategy.dart';
import './conversation_mode.dart';

/// 创建默认策略实例（对话模式）
WorkModeStrategy createWorkModeStrategy([String? workMode]) {
  return ConversationMode();
}
