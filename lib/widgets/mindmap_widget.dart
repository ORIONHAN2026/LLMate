import 'package:flutter/material.dart';
import '../models/chat/mindmap_node.dart';

/// 脑图渲染组件
class MindMapWidget extends StatefulWidget {
  final MindMapNode root;
  final double nodeSpacing;
  final double levelIndent;

  const MindMapWidget({
    super.key,
    required this.root,
    this.nodeSpacing = 4,
    this.levelIndent = 24,
  });

  @override
  State<MindMapWidget> createState() => _MindMapWidgetState();
}

class _MindMapWidgetState extends State<MindMapWidget> {
  final Set<String> _collapsedNodes = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: _buildNode(widget.root, 0, isRoot: true),
    );
  }

  Widget _buildNode(MindMapNode node, int depth, {bool isRoot = false}) {
    final hasChildren = node.children.isNotEmpty;
    final isCollapsed = _collapsedNodes.contains(node.title);
    final colorScheme = Theme.of(context).colorScheme;

    // 节点颜色：根节点用主色，其他交替
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.error,
    ];
    final nodeColor = isRoot ? colorScheme.primary : colors[depth % colors.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点内容
        GestureDetector(
          onTap: hasChildren
              ? () {
                  setState(() {
                    if (isCollapsed) {
                      _collapsedNodes.remove(node.title);
                    } else {
                      _collapsedNodes.add(node.title);
                    }
                  });
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 连接线
              if (depth > 0)
                Container(
                  width: 20,
                  height: 2,
                  color: nodeColor.withValues(alpha: 0.3),
                ),
              // 折叠/展开按钮
              if (hasChildren)
                Icon(
                  isCollapsed ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  size: 14,
                  color: nodeColor.withValues(alpha: 0.5),
                )
              else
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeColor.withValues(alpha: 0.2),
                  ),
                ),
              const SizedBox(width: 4),
              // 节点文本
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isRoot ? 12 : 8,
                    vertical: isRoot ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: isRoot ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: nodeColor.withValues(alpha: isRoot ? 0.3 : 0.15),
                      width: isRoot ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    node.title,
                    style: TextStyle(
                      fontSize: isRoot ? 14 : 12,
                      fontWeight: isRoot ? FontWeight.w600 : FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              // 子节点数量
              if (hasChildren && isCollapsed)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '(${node.children.length})',
                    style: TextStyle(
                      fontSize: 10,
                      color: nodeColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 子节点
        if (hasChildren && !isCollapsed)
          Padding(
            padding: EdgeInsets.only(left: widget.levelIndent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: node.children
                  .map((child) => Padding(
                        padding: EdgeInsets.only(top: widget.nodeSpacing),
                        child: _buildNode(child, depth + 1),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
