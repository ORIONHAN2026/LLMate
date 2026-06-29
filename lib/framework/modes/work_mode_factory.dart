import 'work_mode_strategy.dart';
import 'conversation_mode.dart';
import 'contract_mode.dart';
import 'invoice_mode.dart';
import 'chatroom_mode.dart';
import 'creative_mode.dart';
import 'task_mode.dart';

/// 根据 workMode 字符串创建对应的策略实例
WorkModeStrategy createWorkModeStrategy(String workMode) {
  switch (workMode) {
    case 'contract':
      return ContractMode();
    case 'invoice':
      return InvoiceMode();
    case 'chatroom':
      return ChatroomMode();
    case 'creative':
      return CreativeMode();
    case 'task':
      return TaskMode();
    case 'conversation':
    default:
      return ConversationMode();
  }
}

/// 获取工作模式的显示名称
String getWorkModeDisplayName(String workMode) {
  return createWorkModeStrategy(workMode).displayName;
}

/// 获取工作模式的图标
String getWorkModeIcon(String workMode) {
  return createWorkModeStrategy(workMode).icon;
}
