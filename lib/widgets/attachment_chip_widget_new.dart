import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat/chat_attachment.dart';
import '../utils/snackbar_utils.dart';

class AttachmentChipWidget extends StatelessWidget {
  final ChatAttachment attachment;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const AttachmentChipWidget({
    super.key,
    required this.attachment,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getAttachmentIcon();
    final iconColor = _getAttachmentIconColor();

    // 所有附件类型使用统一的布局
    return _buildRegularAttachmentChip(context, iconData, iconColor);
  }

  /// 构建普通附件卡片
  Widget _buildRegularAttachmentChip(
    BuildContext context,
    IconData icon,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: onTap ?? () => _showAttachmentDetails(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220, minWidth: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 8),
              // 文件信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attachment.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildStatusRow(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态行（文件大小和处理状态）
  Widget _buildStatusRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 显示文件大小
        if (attachment.size != null)
          Text(
            _formatFileSize(attachment.size!),
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        // 根据附件状态显示不同的状态指示器
        if (attachment.content != null) ...[
          if (attachment.size != null)
            Text(
              ' • ',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          if (attachment.content == 'ERROR_PROCESSING') ...[
            // 处理失败状态
            Icon(Icons.error_outline, size: 11, color: Colors.red[600]),
            const SizedBox(width: 2),
            Text(
              '处理失败',
              style: TextStyle(fontSize: 10, color: Colors.red[600]),
            ),
          ] else if (attachment.content!.isNotEmpty) ...[
            // 处理成功状态
            Icon(Icons.check_circle, size: 11, color: Colors.green[600]),
            const SizedBox(width: 2),
            Text(
              '已处理',
              style: TextStyle(fontSize: 10, color: Colors.green[600]),
            ),
          ],
        ] else ...[
          // 正在处理状态（content 为 null）
          if (attachment.size != null)
            Text(
              ' • ',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '正在处理',
            style: TextStyle(fontSize: 10, color: Colors.orange[600]),
          ),
        ],
      ],
    );
  }

  /// 根据附件类型获取图标
  IconData _getAttachmentIcon() {
    switch (attachment.type) {
      case 'image':
        return CupertinoIcons.photo;
      case 'document':
      case 'text':
        return CupertinoIcons.doc_text;
      case 'code':
        return CupertinoIcons.textformat;
      case 'office':
        return CupertinoIcons.doc;
      case 'web':
        return CupertinoIcons.globe;
      case 'web_search':
        return CupertinoIcons.search;
      case 'folder':
        return CupertinoIcons.folder;
      default:
        return CupertinoIcons.doc;
    }
  }

  /// 根据附件类型获取图标颜色
  Color _getAttachmentIconColor() {
    switch (attachment.type) {
      case 'image':
        return Colors.blue;
      case 'document':
      case 'text':
        return Colors.green;
      case 'code':
        return Colors.purple;
      case 'office':
        return Colors.indigo;
      case 'web':
        return Colors.orange;
      case 'web_search':
        return Colors.deepOrange;
      case 'folder':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 显示附件详情对话框
  void _showAttachmentDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                _getAttachmentIcon(),
                size: 18,
                color: _getAttachmentIconColor(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件信息
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '文件信息',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('文件名: ${attachment.name}'),
                        if (attachment.size != null)
                          Text('大小: ${_formatFileSize(attachment.size!)}'),
                        Text('类型: ${_getFileTypeDescription(attachment.type)}'),
                        if (attachment.filePath != null)
                          Text('路径: ${attachment.filePath}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 文件内容
                  if (attachment.content != null &&
                      attachment.content!.isNotEmpty &&
                      attachment.content != 'ERROR_PROCESSING') ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '文件内容',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SelectableText(
                        attachment.content!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ] else if (attachment.content == 'ERROR_PROCESSING') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '文件处理失败',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '请重新上传文件或联系技术支持',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            '正在处理文件...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('关闭', style: TextStyle(color: Colors.grey)),
            ),
            if (attachment.content != null &&
                attachment.content!.isNotEmpty &&
                attachment.content != 'ERROR_PROCESSING')
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: attachment.content!));
                  Navigator.of(context).pop();
                  SnackBarUtils.showSuccess(context, '文件内容已复制到剪贴板');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('复制内容'),
              ),
          ],
        );
      },
    );
  }

  /// 获取文件类型描述
  String _getFileTypeDescription(String type) {
    switch (type) {
      case 'image':
        return '图片文件';
      case 'document':
        return '文档文件';
      case 'text':
        return '文本文件';
      case 'code':
        return '代码文件';
      case 'office':
        return '办公文档';
      case 'web':
        return '网页链接';
      case 'folder':
        return '文件夹';
      default:
        return '其他文件';
    }
  }
}
