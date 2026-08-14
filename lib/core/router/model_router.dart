import '../../models/chat/session.dart';
import '../../models/model.dart';
import '../../models/model_catalog.dart';

/// 省钱路由判断器（MVP：仅按最后一条用户消息字数）
///
/// 决策逻辑：
/// - 关闭费用优化开关（routingEnabled=false）→ 强制使用 [ChatModel.model] 指定模型
/// - 开启开关但便宜/复杂模型未配齐 → 兜底使用 [ChatModel.model]（绝不空发）
/// - 开启且配齐 → 最后一条 user 消息字数 > threshold 用复杂模型，否则用便宜模型
class ModelRouter {
  /// 字数阈值：大于该值送复杂模型
  static const int complexityThreshold = 200;

  /// 决策本次请求用哪个模型（返回模型 id，写入 body['model']）
  static String decide({
    required ChatModel model,
    required Map<String, dynamic> body,
  }) {
    // ① 关闭费用优化开关 → 强制使用指定模型（等价老行为）
    if (!model.routingEnabled) {
      return model.model;
    }

    // ② 开启开关但便宜/复杂模型未配齐 → 兜底用指定模型（绝不空发）
    final cheap = model.cheapModel;
    final complex = model.complexModel;
    if (cheap == null ||
        cheap.isEmpty ||
        complex == null ||
        complex.isEmpty) {
      return model.model;
    }

    // ③ 正常路由：最后一条 user 消息字数判断
    final textLen = _lastUserText(body).runes.length;
    return textLen > complexityThreshold ? complex : cheap;
  }

  /// 决策本次请求用哪个模型（会话级模型设置）。
  ///
  /// - [ChatSession.autoSelectModel] 为 false：使用 [ChatSession.model]
  ///   （手动选定），为空则回退 [ChatModel.model]。
  /// - 开启自动选择：从 [ChatModel.availableModels] 里自动挑「便宜/复杂」
  ///   模型，并按最后一条 user 消息字数路由（等价原来的省钱路由，候选池
  ///   改为可用模型清单）。
  static String decideForSession({
    required ChatSession session,
    required Map<String, dynamic> body,
  }) {
    final chatModel = session.chatModel;
    if (chatModel == null) return session.model ?? '';

    final available = chatModel.availableModels.isNotEmpty
        ? chatModel.availableModels
        : (chatModel.model.isNotEmpty ? [chatModel.model] : const <String>[]);

    // 手动模式：使用会话选定模型，为空回退 chatModel.model
    if (!session.autoSelectModel) {
      final selected = session.model;
      if (selected != null && selected.isNotEmpty) return selected;
      return chatModel.model;
    }

    // 自动模式：从候选池自动挑便宜/复杂（绝不空发）
    if (available.isEmpty) return chatModel.model;
    if (available.length < 2) return available.first;

    final cheap = ModelCatalog.pickCheap(available);
    final complex = ModelCatalog.pickComplex(available);
    if (cheap == null || complex == null) return available.first;

    final textLen = _lastUserText(body).runes.length;
    return textLen > complexityThreshold ? complex : cheap;
  }

  /// 提取最后一条 role=user 的文本内容（兼容纯文本与多模态 content 数组）
  static String _lastUserText(Map<String, dynamic> body) {
    final messages = body['messages'];
    if (messages is! List) return '';
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m is! Map || m['role'] != 'user') continue;
      final content = m['content'];
      if (content is String) return content;
      if (content is List) {
        final sb = StringBuffer();
        for (final part in content) {
          if (part is Map && part['type'] == 'text') {
            sb.write(part['text'] ?? '');
          }
        }
        return sb.toString();
      }
    }
    return '';
  }
}
