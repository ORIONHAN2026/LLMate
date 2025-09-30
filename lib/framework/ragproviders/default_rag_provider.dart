import 'base_rag_provider.dart';
import '../../models/bigmodel/chat_model.dart';

/// 默认RAG提供商实现
/// 提供基础的RAG功能实现
class DefaultRagProvider extends BaseRagProvider {
  
  @override
  void onConfigure(ChatModel model) {
    // 可以在这里添加特定的配置逻辑
    super.onConfigure(model);
  }
}
