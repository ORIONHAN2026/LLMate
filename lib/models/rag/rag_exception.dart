/// RAG 相关操作异常
class RagException implements Exception {
  final String message;
  
  RagException(this.message);
  
  @override
  String toString() => 'RagException: $message';
}
