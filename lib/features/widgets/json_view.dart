import 'dart:convert';

import 'package:flutter/material.dart';

/// 可折叠、带语法高亮的 JSON 树形渲染组件。
///
/// 相比把 JSON 直接序列化成纯文本，本组件会：
/// 1. 将对象 / 数组渲染为可折叠的树，便于逐层展开查看；
/// 2. 对 key、字符串、数字、布尔、null 分别着色；
/// 3. 自动识别「值为 JSON 字符串」的字段（如审计 payload 中的 `body`），
///    将其解析为可展开节点，避免显示成一长串转义字符。
class JsonView extends StatelessWidget {
  final dynamic data;

  /// 默认展开的层级深度（0 为根节点，其余层级默认折叠）。
  final int initialExpandDepth;

  const JsonView(this.data, {super.key, this.initialExpandDepth = 2});

  @override
  Widget build(BuildContext context) {
    return _JsonNode(
      value: data,
      keyName: null,
      depth: 0,
      colors: _JsonColors.of(context),
      initialExpandDepth: initialExpandDepth,
    );
  }
}

/// 单个 JSON 节点的渲染（对象 / 数组 / 标量），自行维护展开状态。
class _JsonNode extends StatefulWidget {
  final dynamic value;
  final String? keyName;
  final int depth;
  final _JsonColors colors;
  final int initialExpandDepth;

  const _JsonNode({
    required this.value,
    required this.keyName,
    required this.depth,
    required this.colors,
    required this.initialExpandDepth,
  });

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  late bool _expanded = widget.depth < widget.initialExpandDepth;

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    if (v is Map) {
      return _buildMap(v);
    }
    if (v is List) {
      return _buildList(v);
    }
    if (v is String) {
      // 值本身是 JSON 字符串时，解析为可展开节点。
      final embedded = _tryDecodeJson(v);
      if (embedded != null) {
        return _buildEmbeddedJson(v, embedded);
      }
    }
    return _buildScalar(v);
  }

  /// 折叠箭头（无子节点时不显示）
  Widget _arrow(bool hasChildren) {
    if (!hasChildren) {
      return const SizedBox(width: 14);
    }
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Icon(
        _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
        size: 16,
        color: widget.colors.punct,
      ),
    );
  }

  /// key 标签，例如 `"foo": `（数组元素或根节点无 key）
  Widget _keyLabel() {
    final k = widget.keyName;
    if (k == null) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '"$k"', style: TextStyle(color: widget.colors.key)),
          TextSpan(
            text: ': ',
            style: TextStyle(color: widget.colors.punct),
          ),
        ],
      ),
      style: _baseStyle,
    );
  }

  Widget _buildMap(Map<dynamic, dynamic> map) {
    final entries = map.entries.toList();
    final hasChildren = entries.isNotEmpty;
    return _indent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerLine(
            leading: _arrow(hasChildren),
            child: Row(
              children: [
                _keyLabel(),
                _brace('{'),
                if (!_expanded && hasChildren)
                  _meta(' ${entries.length} 项 '),
                if (!_expanded) _brace('}'),
              ],
            ),
          ),
          if (_expanded && hasChildren)
            ...entries.map(
              (e) => _JsonNode(
                value: e.value,
                keyName: '${e.key}',
                depth: widget.depth + 1,
                colors: widget.colors,
                initialExpandDepth: widget.initialExpandDepth,
              ),
            ),
          if (_expanded && hasChildren)
            _indent(child: _brace('}')),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> list) {
    final hasChildren = list.isNotEmpty;
    return _indent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerLine(
            leading: _arrow(hasChildren),
            child: Row(
              children: [
                _keyLabel(),
                _brace('['),
                if (!_expanded && hasChildren)
                  _meta(' ${list.length} 项 '),
                if (!_expanded) _brace(']'),
              ],
            ),
          ),
          if (_expanded && hasChildren)
            ...list.map(
              (item) => _JsonNode(
                value: item,
                keyName: null,
                depth: widget.depth + 1,
                colors: widget.colors,
                initialExpandDepth: widget.initialExpandDepth,
              ),
            ),
          if (_expanded && hasChildren) _indent(child: _brace(']')),
        ],
      ),
    );
  }

  /// 值本身是 JSON 字符串的字段：折叠时显示字符串缩略，展开时渲染解析出的树。
  Widget _buildEmbeddedJson(String raw, dynamic decoded) {
    final preview = _preview(raw);
    final hasChildren = decoded is Map && decoded.isNotEmpty ||
        decoded is List && decoded.isNotEmpty;
    return _indent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerLine(
            leading: _arrow(hasChildren),
            child: Row(
              children: [
                _keyLabel(),
                Text(
                  _expanded ? '（JSON）' : '"$preview"',
                  style: TextStyle(
                    color: widget.colors.string,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (_expanded)
            _JsonNode(
              value: decoded,
              keyName: null,
              depth: widget.depth + 1,
              colors: widget.colors,
              initialExpandDepth: widget.initialExpandDepth,
            ),
        ],
      ),
    );
  }

  Widget _buildScalar(dynamic v) {
    final (text, color) = _scalarText(v, widget.colors);
    return _indent(
      child: _headerLine(
        leading: const SizedBox(width: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _keyLabel(),
            Expanded(child: SelectableText(text, style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace'))),
          ],
        ),
      ),
    );
  }

  /// 折叠行（箭头 + 内容）
  Widget _headerLine({required Widget leading, required Widget child}) {
    return InkWell(
      onTap: () {
        // 点击整行切换折叠（无子节点的标量行不响应）
        if (widget.value is Map || widget.value is List) {
          setState(() => _expanded = !_expanded);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [leading, Expanded(child: child)],
      ),
    );
  }

  Widget _indent({required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 14.0),
      child: child,
    );
  }

  Widget _brace(String s) =>
      Text(s, style: TextStyle(color: widget.colors.punct, fontSize: 12, fontFamily: 'monospace'));

  Widget _meta(String s) =>
      Text(s, style: TextStyle(color: widget.colors.meta, fontSize: 12, fontFamily: 'monospace'));

  static const TextStyle _baseStyle = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    height: 1.4,
  );
}

/// 根据主题亮度提供 JSON 语法高亮配色。
class _JsonColors {
  final Color key;
  final Color string;
  final Color number;
  final Color boolean;
  final Color nullColor;
  final Color punct;
  final Color meta;

  const _JsonColors({
    required this.key,
    required this.string,
    required this.number,
    required this.boolean,
    required this.nullColor,
    required this.punct,
    required this.meta,
  });

  factory _JsonColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const _JsonColors(
            key: Color(0xFF82AAFF),
            string: Color(0xFFA5D6A7),
            number: Color(0xFFF78C6C),
            boolean: Color(0xFFCE93D8),
            nullColor: Color(0xFF8E8E93),
            punct: Color(0xFF9E9E9E),
            meta: Color(0xFF9E9E9E),
          )
        : const _JsonColors(
            key: Color(0xFF0B57D0),
            string: Color(0xFF1E7D32),
            number: Color(0xFFB26A00),
            boolean: Color(0xFF7B1FA2),
            nullColor: Color(0xFF6B7280),
            punct: Color(0xFF4B5563),
            meta: Color(0xFF9CA3AF),
          );
  }
}

/// 尝试将字符串解析为 Map / List；解析失败返回 null。
dynamic _tryDecodeJson(String s) {
  final t = s.trimLeft();
  if (!t.startsWith('{') && !t.startsWith('[')) return null;
  try {
    final decoded = jsonDecode(s);
    if (decoded is Map || decoded is List) return decoded;
  } catch (_) {
    // 忽略解析失败，按普通字符串处理
  }
  return null;
}

/// 字符串缩略预览：折叠状态下的 JSON 字符串展示。
String _preview(String s) {
  final oneLine = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (oneLine.length <= 60) return oneLine;
  return '${oneLine.substring(0, 60)}…';
}

/// 标量值 -> (显示文本, 颜色)
(String, Color) _scalarText(dynamic v, _JsonColors colors) {
  if (v == null) return ('null', colors.nullColor);
  if (v is bool) return (v.toString(), colors.boolean);
  if (v is num) return (v.toString(), colors.number);
  return ('"$v"', colors.string);
}
