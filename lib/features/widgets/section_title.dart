import 'package:flutter/material.dart';

/// 区块标题组件。
///
/// 统一各页面的分区标题样式（参考设置页 / 模型详情页），采用 colorScheme
/// 配色与一致的字号、字重、内边距，避免各页面零散手写 Text 导致风格不一致。
class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const SectionTitle(this.title, {super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
