import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';
import '../models/chat/scheduled_task.dart';

/// 定时任务设置对话框（每个会话仅允许一条定时任务）
class ScheduledTaskDialog extends StatefulWidget {
  const ScheduledTaskDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ScheduledTaskDialog(),
    );
  }

  @override
  State<ScheduledTaskDialog> createState() => _ScheduledTaskDialogState();
}

class _ScheduledTaskDialogState extends State<ScheduledTaskDialog> {
  final SessionController _controller = Get.find<SessionController>();

  ScheduledTask? get existingTask =>
      _controller.currentSession.value?.scheduledTask;

  late final TextEditingController _cronController;
  late final TextEditingController _messageController;
  late bool _enabled;
  String? _cronError;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    final task = existingTask;
    _isEdit = task != null;
    _cronController = TextEditingController(text: task?.cronExpression ?? '');
    _messageController = TextEditingController(text: task?.message ?? '');
    _enabled = task?.enabled ?? true;
  }

  @override
  void dispose() {
    _cronController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final session = _controller.currentSession.value;
      if (session == null) {
        return const Dialog(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('当前没有活动会话'),
        ));
      }

      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 80,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isEdit ? '编辑定时任务' : '设置定时任务',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),

                  ],
                ),
              ),

              // 内容区
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cron 表达式
                      Text(
                        'Cron 表达式',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cronController,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '例: 0 9 * * * (每天9:00)',
                          hintStyle: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          errorText: _cronError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.onSurface.withOpacity(0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setState(() => _cronError = null),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '格式: 分 时 日 月 周 (5个字段)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 快捷预设
                      _buildCronPresets(theme, (cron) {
                        _cronController.text = cron;
                        setState(() => _cronError = null);
                      }),
                      const SizedBox(height: 16),

                      // 消息内容
                      Text(
                        '消息内容',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _messageController,
                        maxLines: 3,
                        minLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '定时发送的消息内容...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.onSurface.withOpacity(0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 启用开关
                      Row(
                        children: [
                          Text(
                            '启用任务',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: _enabled,
                              onChanged: _onToggle,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _onToggle(bool v) {
    final cron = _cronController.text.trim();
    final message = _messageController.text.trim();

    if (v) {
      // 开启：需要校验 cron 和消息内容
      if (cron.isEmpty) {
        setState(() => _cronError = '请输入 cron 表达式');
        return; // 校验失败，switch 状态不变
      }
      if (!_isValidCron(cron)) {
        setState(() => _cronError = 'cron 格式错误（需要5个字段）');
        return;
      }
      if (message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入消息内容')),
        );
        return;
      }
      setState(() => _enabled = true);
      _doSave(cron, message, true);
    } else {
      // 关闭：仅当已有任务时才保存 disabled 状态
      setState(() => _enabled = false);
      if (_isEdit && existingTask != null && cron.isNotEmpty && _isValidCron(cron)) {
        _doSave(cron, message, false);
      }
    }
  }

  void _doSave(String cron, String message, bool enabled) {
    if (_isEdit && existingTask != null) {
      _controller.updateSession(
        _controller.currentSession.value!.copyWith(
          scheduledTask: existingTask!.copyWith(
            cronExpression: cron,
            message: message,
            enabled: enabled,
          ),
        ),
      );
    } else {
      _controller.updateSession(
        _controller.currentSession.value!.copyWith(
          scheduledTask: ScheduledTask(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            cronExpression: cron,
            message: message,
            enabled: enabled,
          ),
        ),
      );
    }
  }

  Widget _buildCronPresets(
    ThemeData theme,
    void Function(String cron) onSelect,
  ) {
    final presets = const [
      ('0 9 * * *', '每天 09:00'),
      ('0 12 * * *', '每天 12:00'),
      ('0 18 * * *', '每天 18:00'),
      ('0 9 * * 1-5', '工作日 09:00'),
      ('*/30 * * * *', '每 30 分钟'),
      ('0 */2 * * *', '每 2 小时'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presets.map((p) {
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minSize: 0,
          borderRadius: BorderRadius.circular(6),
          color: theme.colorScheme.primary.withOpacity(0.08),
          onPressed: () => onSelect(p.$1),
          child: Text(
            p.$2,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isValidCron(String cron) {
    final parts = cron.trim().split(RegExp(r'\s+'));
    return parts.length == 5;
  }
}
