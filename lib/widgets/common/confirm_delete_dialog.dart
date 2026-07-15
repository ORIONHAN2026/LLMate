import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String itemName;
  final String description;
  final String? warningMessage;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;
  final String confirmText;
  final String cancelText;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.itemName,
    required this.description,
    required this.onConfirm,
    this.warningMessage,
    this.onCancel,
    this.icon,
    this.iconColor,
    this.confirmText = '删除',
    this.cancelText = '取消',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Icon(
            icon ?? Icons.warning_amber_rounded,
            size: 14,
            color: iconColor ?? Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: iconColor ?? Colors.red,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$description "$itemName" 吗？',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (warningMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (iconColor ?? Colors.red).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: iconColor ?? Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warningMessage!,
                      style: TextStyle(
                        fontSize: 11,
                        color: iconColor ?? Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // 直接返回false，关闭对话框
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(60, 28),
            textStyle: const TextStyle(fontSize: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            cancelText,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true); // 直接返回true，关闭对话框
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor ?? Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(60, 28),
            textStyle: const TextStyle(fontSize: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.delete_outline, size: 10),
              const SizedBox(width: 4),
              Text(confirmText),
            ],
          ),
        ),
      ],
    );
  }

  /// 显示确认删除对话框的静态方法
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String itemName,
    required String description,
    String? warningMessage,
    IconData? icon,
    Color? iconColor,
    String confirmText = '删除',
    String cancelText = '取消',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ConfirmDeleteDialog(
          title: title,
          itemName: itemName,
          description: description,
          warningMessage: warningMessage,
          icon: icon,
          iconColor: iconColor,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: () {}, // 空回调，因为会在按钮的onPressed中处理
          onCancel: () {}, // 空回调，因为会在按钮的onPressed中处理
        );
      },
    );
  }
}
