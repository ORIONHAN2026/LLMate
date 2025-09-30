/*
 * 通用确认删除对话框组件使用示例
 * 
 * ConfirmDeleteDialog 是一个可重用的确认删除对话框组件，适用于各种删除操作场景。
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chathub/widgets/common/confirm_delete_dialog.dart';

class ConfirmDeleteDialogUsageExample {
  // 示例1: 删除模型
  static Future<void> deleteModelExample(
    BuildContext context,
    String modelName,
  ) async {
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '确认删除',
      itemName: modelName,
      description: '确定要删除大模型',
      warningMessage: '此操作不可撤销',
      icon: CupertinoIcons.exclamationmark_triangle,
      iconColor: Colors.red,
    );

    if (shouldDelete == true) {
      // 执行删除操作
      print('删除模型: $modelName');
    }
  }

  // 示例2: 删除文档
  static Future<void> deleteDocumentExample(
    BuildContext context,
    String documentTitle,
  ) async {
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '删除文档',
      itemName: documentTitle,
      description: '确定要删除文档',
      warningMessage: '此操作不可撤销',
      icon: CupertinoIcons.doc_text,
      iconColor: Colors.red,
    );

    if (shouldDelete == true) {
      // 执行删除操作
      print('删除文档: $documentTitle');
    }
  }

  // 示例3: 删除快捷指令
  static Future<void> deleteCommandExample(
    BuildContext context,
    String commandContent,
  ) async {
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '确认删除',
      itemName: commandContent,
      description: '确定要删除快捷指令',
      warningMessage: '此操作不可撤销',
      icon: CupertinoIcons.command,
      iconColor: Colors.red,
    );

    if (shouldDelete == true) {
      // 执行删除操作
      print('删除快捷指令: $commandContent');
    }
  }

  // 示例4: 自定义样式的删除确认
  static Future<void> customDeleteExample(
    BuildContext context,
    String itemName,
  ) async {
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '移除项目',
      itemName: itemName,
      description: '确定要移除',
      warningMessage: '移除后可以重新添加',
      icon: CupertinoIcons.minus_circle,
      iconColor: Colors.orange,
      confirmText: '移除',
      cancelText: '保留',
    );

    if (shouldDelete == true) {
      // 执行移除操作
      print('移除项目: $itemName');
    }
  }
}

/*
 * ConfirmDeleteDialog 组件的主要特性:
 * 
 * 1. 可定制的标题和描述文本
 * 2. 支持自定义图标和颜色
 * 3. 可选的警告消息显示
 * 4. 一致的UI设计风格
 * 5. 异步返回用户选择结果 (true=确认, false=取消, null=对话框被其他方式关闭)
 * 6. 可自定义按钮文本
 * 7. 只关闭对话框，不会影响页面导航
 * 
 * 适用场景:
 * - 删除模型、文档、配置等重要数据
 * - 任何需要用户二次确认的删除操作
 * - 保持应用内删除确认对话框的一致性
 * 
 * 使用方式:
 * - 点击"取消"按钮: 返回 false，对话框关闭
 * - 点击"确定/删除"按钮: 返回 true，对话框关闭  
 * - 点击对话框外部或按返回键: 返回 null，对话框关闭
 */
