import 'dart:io' show Platform;

import 'package:flutter/material.dart';

/// 标准页头 AppBar。
///
/// 统一所有页面的标题栏样式：
/// - 透明无阴影、固定高度 44
/// - macOS 下返回箭头避让窗口红绿灯按钮
/// - 标题统一为 16 / w600，并整体垂直上移 5px 与箭头对齐
/// - 可选底部 1px 分割线，或自定义 bottom（如 TabBar）
///
/// 用法：
/// ```dart
/// appBar: StandardAppBar(title: '模型管理', showBottomDivider: true)
/// ```
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 标题文本（自动套用标准样式）。与 [titleWidget] 二选一。
  final String? title;

  /// 自定义标题内容（如需要非文本标题时）。
  final Widget? titleWidget;

  /// 是否显示返回箭头（默认 true）。
  final bool showBack;

  /// 返回按钮点击回调，默认 `Navigator.pop`。
  final VoidCallback? onBack;

  /// 自定义左侧控件（如主页面的菜单按钮）。提供时优先于返回箭头。
  final Widget? leading;

  /// 右侧操作按钮。
  final List<Widget>? actions;

  /// 自定义底部控件（如 TabBar）。
  final PreferredSizeWidget? bottom;

  /// 标题是否居中。
  final bool centerTitle;

  /// 是否显示底部分割线。
  final bool showBottomDivider;

  /// 自定义 leading 区域宽度；为 null 时按是否含 leading 自动计算。
  final double? leadingWidth;

  const StandardAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.showBottomDivider = false,
    this.leadingWidth,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        44 + (bottom?.preferredSize.height ?? (showBottomDivider ? 1 : 0)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLeading = leading != null || showBack;

    final Widget? resolvedLeading = leading ??
        (showBack
            ? Padding(
                padding: EdgeInsets.only(left: Platform.isMacOS ? 100 : 0),
                child: Transform.translate(
                  offset: const Offset(0, -5),
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 10, minHeight: 20),
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: onBack ??
                        () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                  ),
                ),
              )
            : null);

    final Widget? resolvedTitle = titleWidget ??
        (title != null
            ? Transform.translate(
                offset: const Offset(0, -5),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              )
            : null);

    final PreferredSizeWidget? resolvedBottom = bottom ??
        (showBottomDivider
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: theme.dividerColor),
              )
            : null);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 44,
      leadingWidth: leadingWidth ??
          (hasLeading ? (Platform.isMacOS ? 125 : 44) : null),
      leading: resolvedLeading,
      title: resolvedTitle,
      centerTitle: centerTitle,
      actions: actions,
      bottom: resolvedBottom,
    );
  }
}
