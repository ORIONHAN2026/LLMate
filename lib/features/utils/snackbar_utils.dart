import 'package:flutter/material.dart';

/// 自定义 SnackBar 工具类
/// 提供统一样式的提示消息功能
class SnackBarUtils {
  static OverlayEntry? _overlayEntry;

  /// 显示自定义提示 - 使用 Overlay 实现顶部显示
  static void _showCustomOverlay(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    // 移除之前的提示
    _removeOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 80, // 距离顶部的距离
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 32,
                  minWidth: 120,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IntrinsicWidth(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSuccess)
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                          else if (isError)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                          else
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue[500],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(_overlayEntry!);

    // 3秒后自动移除
    Future.delayed(const Duration(seconds: 3), () {
      _removeOverlay();
    });
  }

  /// 移除 Overlay
  static void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 显示成功提示
  ///
  /// [context] - 当前的 BuildContext
  /// [message] - 要显示的消息内容
  static void showSuccess(BuildContext context, String message) {
    _showCustomOverlay(context, message, isSuccess: true);
  }

  /// 显示错误提示
  ///
  /// [context] - 当前的 BuildContext
  /// [message] - 要显示的消息内容
  static void showError(BuildContext context, String message) {
    _showCustomOverlay(context, message, isError: true);
  }

  /// 显示信息提示
  ///
  /// [context] - 当前的 BuildContext
  /// [message] - 要显示的消息内容
  static void showInfo(BuildContext context, String message) {
    _showCustomOverlay(context, message);
  }

  /// 显示警告提示
  ///
  /// [context] - 当前的 BuildContext
  /// [message] - 要显示的消息内容
  static void showWarning(BuildContext context, String message) {
    // 移除之前的提示
    _removeOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 80, // 距离顶部的距离
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 32,
                  minWidth: 120,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IntrinsicWidth(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(_overlayEntry!);

    // 3秒后自动移除
    Future.delayed(const Duration(seconds: 3), () {
      _removeOverlay();
    });
  }
}
