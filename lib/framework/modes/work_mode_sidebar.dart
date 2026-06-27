import 'package:flutter/material.dart';

/// 右侧边栏策略接口
///
/// 每种 workMode 对应一个实现类，定义该模式下右栏的 Tab 数量、标题和内容。
abstract class WorkModeSidebar {
  /// Tab 总数（含文件列表）
  int get tabCount;

  /// Tab 标题列表
  List<String> get tabTitles;

  /// 构建指定 Tab 的内容
  Widget buildTabContent(BuildContext context, int index, String sessionId);
}
