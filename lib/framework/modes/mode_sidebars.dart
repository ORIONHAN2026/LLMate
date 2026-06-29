import 'package:flutter/material.dart';
import '../../widgets/contract_sidebar.dart';
import '../../widgets/invoice_sidebar.dart';
import '../../widgets/chatroom_sidebar.dart';
import 'work_mode_sidebar.dart';
import 'creative_mode.dart';
import 'task_mode.dart';

/// 对话模式侧边栏（默认，无模式专属 tab）
class ConversationModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 0;

  @override
  List<String> get tabTitles => [];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    return const SizedBox.shrink();
  }
}

/// 合同模式侧边栏（不含文件列表）
class ContractModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 4; // 合约要点、合同履约、合同争议、备忘录

  @override
  List<String> get tabTitles => ['合约要点', '合同履约', '合同争议', '备忘录'];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    // index 0-3 对应 合约要点、合同履约、合同争议、备忘录
    return ContractSidebar.buildTabContent(context, index + 1, sessionId, workDirectory: workDirectory);
  }
}

/// 发票模式侧边栏（不含文件列表）
class InvoiceModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 4; // 发票汇总、发票明细、报销记录、备忘录

  @override
  List<String> get tabTitles => ['发票汇总', '发票明细', '报销记录', '备忘录'];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    // index 0-3 对应 发票汇总、发票明细、报销记录、备忘录
    return InvoiceSidebar.buildTabContent(context, index + 1, sessionId, workDirectory: workDirectory);
  }
}

/// 聊天室模式侧边栏（不含文件列表）
class ChatroomModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 2; // 角色列表、备忘录

  @override
  List<String> get tabTitles => ['角色列表', '备忘录'];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    // index 0-1 对应 角色列表、备忘录
    return ChatroomSidebar.buildTabContent(context, index + 1, sessionId, workDirectory: workDirectory);
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
    case 'task':
      return TaskModeSidebar();
    default:
      return ConversationModeSidebar();
  }
}
