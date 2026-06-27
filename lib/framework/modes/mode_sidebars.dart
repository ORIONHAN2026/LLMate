import 'package:flutter/material.dart';
import '../../widgets/contract_sidebar.dart';
import '../../widgets/invoice_sidebar.dart';
import '../../widgets/chatroom_sidebar.dart';
import 'work_mode_sidebar.dart';
import 'creative_mode.dart';

/// 对话模式侧边栏（默认，仅文件列表）
class ConversationModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 1;

  @override
  List<String> get tabTitles => ['文件列表'];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    return const SizedBox.shrink();
  }
}

/// 合同模式侧边栏
class ContractModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => ContractSidebar.tabCount;

  @override
  List<String> get tabTitles => ContractSidebar.getTabTitles();

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    return ContractSidebar.buildTabContent(context, index, sessionId, workDirectory: workDirectory);
  }
}

/// 发票模式侧边栏
class InvoiceModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => InvoiceSidebar.tabCount;

  @override
  List<String> get tabTitles => InvoiceSidebar.getTabTitles();

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    return InvoiceSidebar.buildTabContent(context, index, sessionId, workDirectory: workDirectory);
  }
}

/// 聊天室模式侧边栏
class ChatroomModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => ChatroomSidebar.tabCount;

  @override
  List<String> get tabTitles => ChatroomSidebar.getTabTitles();

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    return ChatroomSidebar.buildTabContent(context, index, sessionId, workDirectory: workDirectory);
  }
}

/// 根据工作模式获取对应的侧边栏策略
WorkModeSidebar getSidebarByMode(String workMode) {
  switch (workMode) {
    case 'contract':
      return ContractModeSidebar();
    case 'invoice':
      return InvoiceModeSidebar();
    case 'chatroom':
      return ChatroomModeSidebar();
    case 'creative':
      return CreativeModeSidebar();
    default:
      return ConversationModeSidebar();
  }
}
