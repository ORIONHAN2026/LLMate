import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../models/chat/message.dart';

/// 工具消息组件
class ToolMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onUpdate;

  const ToolMessageWidget({super.key, required this.message, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 工具图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.build, size: 18, color: Colors.orange.shade700),
          ),
          const SizedBox(width: 12),

          // 工具消息内容
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 工具名称标题
                  if (message.toolName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '工具: ${message.toolName}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 工具执行结果
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      h1: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                      h2: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                      h3: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade600,
                      ),
                      code: TextStyle(
                        backgroundColor: Colors.grey.shade100,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border(
                          left: BorderSide(
                            color: Colors.orange.shade300,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 错误状态显示
                  if (message.isError)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '工具执行失败',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
