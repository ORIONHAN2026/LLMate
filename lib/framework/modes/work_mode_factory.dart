import 'work_mode_strategy.dart';
import 'conversation_mode.dart';
import 'contract_mode.dart';
import 'invoice_mode.dart';
import 'chatroom_mode.dart';

/// 根据 workMode 字符串创建对应的策略实例
WorkModeStrategy createWorkModeStrategy(String workMode) {
  switch (workMode) {
    case 'contract':
      return ContractMode();
    case 'invoice':
      return InvoiceMode();
    case 'chatroom':
      return ChatroomMode();
    case 'conversation':
    default:
      return ConversationMode();
  }
}
