import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat/chat_attachment.dart';
import '../utils/snackbar_utils.dart';
import '../l10n/app_localizations.dart';

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
      onTap: onTap ?? () {
        // 如果有内容，则显示内容预览，否则显示附件详情
        if (attachment.content != null && attachment.content!.isNotEmpty) {
          _showContentPreview(context);
        } else {
          _showAttachmentDetails(context);
        }
      },
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
                    _buildStatusRow(context),
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
  Widget _buildStatusRow(BuildContext context) {
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
              AppLocalizations.of(context)!.processFailedStatus,
              style: TextStyle(fontSize: 10, color: Colors.red[600]),
            ),
          ] else if (attachment.content!.isNotEmpty) ...[
            // 处理成功状态
            Icon(Icons.check_circle, size: 11, color: Colors.green[600]),
            const SizedBox(width: 2),
            Text(
              AppLocalizations.of(context)!.processed,
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
            AppLocalizations.of(context)!.processingStatus,
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

  /// 显示文件内容预览对话框
  void _showContentPreview(BuildContext context) {
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
                  AppLocalizations.of(context)!.contentPreviewTitle(attachment.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: attachment.content ?? ''));
                  SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.contentCopiedToClipboard);
                  Navigator.of(context).pop();
                },
                tooltip: AppLocalizations.of(context)!.copyContent,
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.4,
            child: SingleChildScrollView(
              child: SelectableText(
                attachment.content ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
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
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.fileInfo,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.fileNameLabel),
                        if (attachment.size != null)
                          Text(AppLocalizations.of(context)!.fileSizeLabel),
                        Text(AppLocalizations.of(context)!.fileTypeLabel),
                        if (attachment.filePath != null)
                          Text(AppLocalizations.of(context)!.filePathLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 文件内容
                  if (attachment.content != null &&
                      attachment.content!.isNotEmpty &&
                      attachment.content != 'ERROR_PROCESSING') ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.fileContent,
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.fileProcessFailed,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.pleaseReupload,
                            style: const TextStyle(color: Colors.red),
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
                            AppLocalizations.of(context)!.processingFileStatus,
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
              child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: Colors.grey)),
            ),
            if (attachment.content != null &&
                attachment.content!.isNotEmpty &&
                attachment.content != 'ERROR_PROCESSING')
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: attachment.content!));
                  Navigator.of(context).pop();
                  SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.fileContentCopied);
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
                child: Text(AppLocalizations.of(context)!.copyContent),
              ),
          ],
        );
      },
    );
  }

  /// 获取文件类型描述
  String _getFileTypeDescription(BuildContext context, String type) {
    switch (type) {
      case 'image':
        return AppLocalizations.of(context)!.imageFile;
      case 'document':
        return AppLocalizations.of(context)!.documentFile;
      case 'text':
        return AppLocalizations.of(context)!.textFile;
      case 'code':
        return AppLocalizations.of(context)!.codeFile;
      case 'office':
        return AppLocalizations.of(context)!.officeDocument;
      case 'web':
        return AppLocalizations.of(context)!.webLink;
      case 'folder':
        return AppLocalizations.of(context)!.folderType;
      default:
        return AppLocalizations.of(context)!.otherFile;
    }
  }
}
