import 'package:flutter/material.dart';

/// 自定义 TextEditingController，将附件标记 【📎filename】 渲染为带背景色的富文本样式。
///
/// 标记格式：【📎filename】，在文本中作为普通字符存在，可以被正常编辑/删除。
/// buildTextSpan 会识别这些标记并应用蓝色背景 + 加粗样式。
class InlineAttachmentEditingController extends TextEditingController {
  /// 匹配附件标记的正则：支持 【📎xxx】或 [📎xxx] 两种格式
  static final RegExp markerPattern = RegExp(r'[【\[]📎(.+?)[】\]]');

  InlineAttachmentEditingController({super.text});

  /// 文本中是否包含附件标记
  bool hasAttachmentMarkers() {
    return markerPattern.hasMatch(text);
  }

  /// 获取文本中所有附件的文件名列表
  List<String> getMarkedFilenames() {
    return markerPattern.allMatches(text).map((m) => m.group(1)!).toList();
  }

  /// 在光标位置插入附件标记
  void insertAttachmentMarker(String filename) {
    final marker = '【📎$filename】';
    final pos = selection.isValid ? selection.start : text.length;
    final newText = text.substring(0, pos) + marker + text.substring(pos);
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + marker.length),
    );
  }

  /// 从文本中移除指定文件名的附件标记
  void removeAttachmentMarker(String filename) {
    final marker = '【📎$filename】';
    final newText = text.replaceAll(marker, '');
    if (newText != text) {
      final pos = selection.isValid ? selection.start : text.length;
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: pos.clamp(0, newText.length),
        ),
      );
    }
  }

  /// 获取去除所有标记后的纯文本
  String getCleanText() {
    return text.replaceAll(markerPattern, '').trim();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!hasAttachmentMarkers()) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final effectiveStyle = style ?? const TextStyle(fontSize: 14);
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in markerPattern.allMatches(text)) {
      // 标记前的普通文本
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: effectiveStyle,
        ));
      }

      // 附件标记 — 带蓝色背景和深蓝色文字
      spans.add(TextSpan(
        text: match.group(0),
        style: effectiveStyle.copyWith(
          color: const Color(0xFF1565C0),
          backgroundColor: const Color(0x1A1565C0),
          fontWeight: FontWeight.w600,
        ),
      ));

      lastEnd = match.end;
    }

    // 剩余文本
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: effectiveStyle,
      ));
    }

    return TextSpan(style: effectiveStyle, children: spans);
  }
}
