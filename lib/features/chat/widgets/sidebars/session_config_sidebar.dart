import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import '../../../../controllers/domain_controller.dart';
import '../../../../models/chat/chat_session.dart';
import '../../../../utils/snackbar_utils.dart';

/// 会话配置侧边栏内容
class SessionConfigSidebar {
  /// 构建会话配置 Tab 的内容
  static Widget buildTabContent(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    
    return Obx(() {
      final session = sessionController.currentSession.value;
      if (session == null) {
        return _buildEmptyState(context);
      }
      
      return _buildConfigContent(context, session);
    });
  }

  /// 构建空状态
  static Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.settings,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无会话配置',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '请先选择或创建一个会话',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建配置内容 - 使用 TabBar 切换
  static Widget _buildConfigContent(BuildContext context, ChatSession session) {
    return _SessionConfigTabs(session: session);
  }

  /// 构建可双击编辑的配置项
  static Widget _buildEditableConfigItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return _EditableConfigItem(
      icon: icon,
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }

  /// 构建可点击切换的 Emoji 配置项
  static Widget _buildEmojiPickerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String currentEmoji,
    required ValueChanged<String> onEmojiSelected,
  }) {
    return InkWell(
      onTap: () => _showEmojiPickerDialog(context, currentEmoji, onEmojiSelected),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示 Emoji 选择器对话框
  static void _showEmojiPickerDialog(
    BuildContext context,
    String currentEmoji,
    ValueChanged<String> onEmojiSelected,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '选择会话图标',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: kSessionEmojis.map((emoji) {
                        final isSelected = currentEmoji == emoji;
                        return GestureDetector(
                          onTap: () {
                            onEmojiSelected(emoji);
                            Navigator.of(ctx).pop();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建配置项
  static Widget _buildConfigItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可复制的配置项（点击复制到剪贴板）
  static Widget _buildCopyableConfigItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        SnackBarUtils.showSuccess(context, '已复制到剪贴板');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.doc_on_doc,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建提示词卡片
  static Widget _buildPromptCard(BuildContext context, String prompt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 12,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                '连接器和技能的关联描述',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prompt,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建区域标题
  static Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        letterSpacing: 0.3,
      ),
    );
  }

  /// 格式化日期时间
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化Token数量
  static String _formatTokenCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(2)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  /// 供同文件其他类使用的格式化方法
  static String sFormatTokenCount(int count) => _formatTokenCount(count);

  /// 构建服务地址（根据域名配置动态拼接）
  static String _buildServiceUrl(String sessionId) {
    try {
      final domainController = Get.find<DomainController>();
      if (domainController.isConfigured) {
        final config = domainController.domainConfig.value;
        final scheme = config.httpsEnabled ? 'https' : 'http';
        final port = config.httpsEnabled ? 443 : 80;
        // 默认端口不显示
        final host = '$scheme://${config.domain}${(scheme == 'http' && port != 80) || (scheme == 'https' && port != 443) ? ':$port' : ''}';
        return '$host/$sessionId/llmwork';
      }
    } catch (_) {
      // DomainController 未初始化，使用默认地址
    }
    return 'http://127.0.0.1:8899/$sessionId/llmwork';
  }

  /// 构建价格卡片
  static Widget _buildPriceCard(
    BuildContext context, {
    double? inputPrice,
    double? outputPrice,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 12,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                '模型定价（美元/百万Token）',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (inputPrice != null)
            Text(
              '输入: \$${inputPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (inputPrice != null && outputPrice != null)
            const SizedBox(height: 4),
          if (outputPrice != null)
            Text(
              '输出: \$${outputPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

/// 可双击编辑的配置项组件
class _EditableConfigItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _EditableConfigItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_EditableConfigItem> createState() => _EditableConfigItemState();
}

class _EditableConfigItemState extends State<_EditableConfigItem> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _EditableConfigItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.value;
    });
    _focusNode.requestFocus();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _finishEditing() {
    final newValue = _controller.text.trim();
    setState(() => _isEditing = false);

    if (newValue.isNotEmpty && newValue != widget.value) {
      widget.onChanged(newValue);
    } else {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_isEditing)
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      maxLines: 1,
                      onSubmitted: (_) => _finishEditing(),
                      onTapOutside: (_) => _finishEditing(),
                    )
                  else
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 用量配额配置区域
class _QuotaConfigSection extends StatefulWidget {
  final ChatSession session;

  const _QuotaConfigSection({required this.session});

  @override
  State<_QuotaConfigSection> createState() => _QuotaConfigSectionState();
}

class _QuotaConfigSectionState extends State<_QuotaConfigSection> {
  late ChatSession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  @override
  void didUpdateWidget(covariant _QuotaConfigSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session != oldWidget.session) {
      _session = widget.session;
    }
  }

  void _updateSession(ChatSession updated) {
    _session = updated;
    final sessionController = Get.find<SessionController>();
    sessionController.updateSession(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 启用开关
        _buildToggleRow(context),

        if (_session.quotaEnabled) ...[
          const SizedBox(height: 8),

          // Token 用量上限
          _buildNumberField(
            context,
            icon: CupertinoIcons.text_bubble,
            label: 'Token 用量上限',
            value: _session.quotaTokenLimit,
            hint: '不限制',
            onChanged: (val) {
              _updateSession(_session.copyWith(
                quotaTokenLimit: val as int?,
                clearQuotaTokenLimit: val == null,
              ));
            },
          ),
          const SizedBox(height: 8),

          // 费用预算上限
          _buildNumberField(
            context,
            icon: CupertinoIcons.money_dollar_circle,
            label: '费用预算上限（美元）',
            value: _session.quotaCostLimit,
            hint: '不限制',
            isDouble: true,
            onChanged: (val) {
              _updateSession(_session.copyWith(
                quotaCostLimit: val as double?,
                clearQuotaCostLimit: val == null,
              ));
            },
          ),
          const SizedBox(height: 8),

          // 请求次数上限
          _buildNumberField(
            context,
            icon: CupertinoIcons.repeat,
            label: '请求次数上限',
            value: _session.quotaRequestLimit,
            hint: '不限制',
            onChanged: (val) {
              _updateSession(_session.copyWith(
                quotaRequestLimit: val as int?,
                clearQuotaRequestLimit: val == null,
              ));
            },
          ),
          const SizedBox(height: 8),

          // 重置周期选择
          _buildResetPeriodPicker(context),

          const SizedBox(height: 8),

          // 当前用量状态
          _buildQuotaStatusCard(context),
        ],
      ],
    );
  }

  Widget _buildToggleRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _session.quotaEnabled
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: _session.quotaEnabled
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            _session.quotaEnabled
                ? CupertinoIcons.gauge
                : CupertinoIcons.gauge_badge_minus,
            size: 16,
            color: _session.quotaEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '启用用量限制',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _session.quotaEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '达到上限后将拒绝新的请求',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _session.quotaEnabled,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              final updated = _session.copyWith(quotaEnabled: val);
              if (val && _session.quotaPeriodStart == null) {
                // 开启时按自然时间边界初始化
                final now = DateTime.now();
                final periodStart = _session.quotaResetPeriod == 'daily'
                    ? DateTime(now.year, now.month, now.day)
                    : _session.quotaResetPeriod == 'monthly'
                        ? DateTime(now.year, now.month, 1)
                        : now;
                _updateSession(updated.copyWith(quotaPeriodStart: periodStart));
              } else {
                _updateSession(updated);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required num? value,
    required String hint,
    required ValueChanged<num?> onChanged,
    bool isDouble = false,
  }) {
    final controller = TextEditingController(
      text: value != null ? (isDouble ? value.toString() : value.toInt().toString()) : '',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: isDouble
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    if (text.isEmpty) {
                      onChanged(null);
                    } else {
                      final parsed = isDouble
                          ? double.tryParse(text)
                          : int.tryParse(text);
                      if (parsed != null && parsed >= 0) {
                        onChanged(parsed);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          if (value != null)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged(null);
              },
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResetPeriodPicker(BuildContext context) {
    final periods = {
      null: '不自动重置',
      'daily': '每天重置',
      'monthly': '每月重置',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.arrow_clockwise_circle,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '重置周期',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _session.quotaResetPeriod,
                    isDense: true,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    items: periods.entries.map((entry) {
                      return DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final updated = _session.copyWith(
                        quotaResetPeriod: val,
                        clearQuotaResetPeriod: val == null,
                      );
                      if (val != null && _session.quotaPeriodStart == null) {
                        final now = DateTime.now();
                        final periodStart = val == 'daily'
                            ? DateTime(now.year, now.month, now.day)
                            : DateTime(now.year, now.month, 1);
                        _updateSession(updated.copyWith(quotaPeriodStart: periodStart));
                      } else {
                        _updateSession(updated);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaStatusCard(BuildContext context) {
    final periodBilling = _session.getPeriodBilling();
    final hasPeriod = _session.quotaPeriodStart != null;
    final effectiveTokens = hasPeriod
        ? periodBilling.inputTokens + periodBilling.outputTokens
        : _session.totalInputTokens + _session.totalOutputTokens;
    final effectiveCost = hasPeriod ? periodBilling.cost : _session.totalCost;
    final quotaResult = _session.checkQuota();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quotaResult.exceeded
            ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: quotaResult.exceeded
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                quotaResult.exceeded
                    ? CupertinoIcons.exclamationmark_triangle
                    : CupertinoIcons.checkmark_seal,
                size: 12,
                color: quotaResult.exceeded
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                quotaResult.exceeded ? '配额已用尽' : '当前用量状态',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: quotaResult.exceeded
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_session.quotaTokenLimit != null)
            _buildQuotaProgress(
              context,
              label: 'Token',
              used: effectiveTokens,
              limit: _session.quotaTokenLimit!,
            ),
          if (_session.quotaCostLimit != null) ...[
            if (_session.quotaTokenLimit != null) const SizedBox(height: 6),
            _buildQuotaProgress(
              context,
              label: '费用',
              used: effectiveCost,
              limit: _session.quotaCostLimit!,
              isDouble: true,
              suffix: '\$',
            ),
          ],
          if (_session.quotaRequestLimit != null) ...[
            if (_session.quotaTokenLimit != null || _session.quotaCostLimit != null)
              const SizedBox(height: 6),
            _buildQuotaProgress(
              context,
              label: '请求',
              used: _session.quotaRequestCount,
              limit: _session.quotaRequestLimit!,
            ),
          ],
          if (quotaResult.exceeded) ...[
            const SizedBox(height: 8),
            Text(
              quotaResult.detail ?? '',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaProgress(
    BuildContext context, {
    required String label,
    required num used,
    required num limit,
    bool isDouble = false,
    String suffix = '',
  }) {
    final progress = limit > 0 ? (used.toDouble() / limit.toDouble()).clamp(0.0, 1.0) : 0.0;
    final usedStr = isDouble
        ? '${used.toStringAsFixed(4)}'
        : SessionConfigSidebar.sFormatTokenCount(used.toInt());
    final limitStr = isDouble
        ? '${limit.toStringAsFixed(2)}'
        : SessionConfigSidebar.sFormatTokenCount(limit.toInt());
    final progressColor = progress >= 0.9
        ? Theme.of(context).colorScheme.error
        : progress >= 0.7
            ? Colors.orange
            : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '$suffix$usedStr / $suffix$limitStr',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}

/// 会话配置 Tab 切换组件
class _SessionConfigTabs extends StatefulWidget {
  final ChatSession session;

  const _SessionConfigTabs({required this.session});

  @override
  State<_SessionConfigTabs> createState() => _SessionConfigTabsState();
}

class _SessionConfigTabsState extends State<_SessionConfigTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '基础信息'),
            Tab(text: '服务配置'),
            Tab(text: '用量配额'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: 基础信息
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SessionConfigSidebar._buildEditableConfigItem(
                      context,
                      icon: CupertinoIcons.chat_bubble,
                      label: '会话名称',
                      value: session.name,
                      onChanged: (newName) {
                        if (newName.trim().isNotEmpty &&
                            newName.trim() != session.name) {
                          final sessionController =
                              Get.find<SessionController>();
                          sessionController.updateSession(
                            session.copyWith(title: newName.trim()),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildEmojiPickerItem(
                      context,
                      icon: CupertinoIcons.smiley,
                      label: '会话图标',
                      currentEmoji: session.emoji,
                      onEmojiSelected: (emoji) {
                        final sessionController =
                            Get.find<SessionController>();
                        sessionController.updateSession(
                          session.copyWith(emoji: emoji),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.calendar,
                      label: '创建时间',
                      value: SessionConfigSidebar._formatDateTime(
                        session.createdAt,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.globe,
                      label: '绑定模型',
                      value: session.chatModel?.name ?? '未设置',
                      valueColor: session.chatModel != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.lightbulb,
                      label: '深度思考',
                      value: session.deepThink ? '已开启' : '已关闭',
                      valueColor: session.deepThink
                          ? Colors.green
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.folder,
                      label: '工作目录',
                      value: session.workDirectory ?? '未设置',
                      maxLines: 2,
                      valueColor: session.workDirectory != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.link,
                      label: 'MCP连接器',
                      value: session.mcp?.name ?? '未绑定',
                      valueColor: session.mcp != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    // 关联提示词
                    if (session.connectPrompt != null &&
                        session.connectPrompt!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SessionConfigSidebar._buildSectionTitle(
                        context,
                        '关联提示词',
                      ),
                      const SizedBox(height: 8),
                      SessionConfigSidebar._buildPromptCard(
                        context,
                        session.connectPrompt!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.chat_bubble_2,
                      label: '消息数量',
                      value: '${session.messages.length}条',
                    ),
                    const SizedBox(height: 12),
                    SessionConfigSidebar._buildSectionTitle(context, '计费信息'),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.arrow_down_circle,
                      label: '累计输入Token',
                      value: SessionConfigSidebar._formatTokenCount(
                        session.totalInputTokens,
                      ),
                      valueColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.arrow_up_circle,
                      label: '累计输出Token',
                      value: SessionConfigSidebar._formatTokenCount(
                        session.totalOutputTokens,
                      ),
                      valueColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildConfigItem(
                      context,
                      icon: CupertinoIcons.money_dollar_circle,
                      label: '累计费用',
                      value: '\$${session.totalCost.toStringAsFixed(6)}',
                      valueColor: session.totalCost > 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    if (session.chatModel?.inputPrice != null ||
                        session.chatModel?.outputPrice != null) ...[
                      const SizedBox(height: 8),
                      SessionConfigSidebar._buildPriceCard(
                        context,
                        inputPrice: session.chatModel?.inputPrice,
                        outputPrice: session.chatModel?.outputPrice,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Tab 2: 服务配置
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SessionConfigSidebar._buildCopyableConfigItem(
                      context,
                      icon: CupertinoIcons.link,
                      label: '服务地址',
                      value: SessionConfigSidebar._buildServiceUrl(
                        session.sessionId,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SessionConfigSidebar._buildCopyableConfigItem(
                      context,
                      icon: CupertinoIcons.lock_shield,
                      label: 'API 密钥',
                      value: session.apiKey,
                    ),
                  ],
                ),
              ),

              // Tab 3: 用量配额
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _QuotaConfigSection(session: session),
              ),
            ],
          ),
        ),
      ],
    );
  }
}