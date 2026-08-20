import 'dart:convert';

import 'package:llmate/features/widgets/standard_app_bar.dart';
import 'package:llmate/features/widgets/confirm_delete_dialog.dart';
import 'package:llmate/features/widgets/json_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/mcp_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../models/chat/mcp.dart';
import '../../utils/snackbar_utils.dart';

class McpManagementPage extends StatefulWidget {
  final bool embedded;
  final void Function(List<Widget>)? onActionsChanged;

  const McpManagementPage({
    super.key,
    this.embedded = false,
    this.onActionsChanged,
  });

  @override
  State<McpManagementPage> createState() => _McpManagementPageState();
}

class _McpManagementPageState extends State<McpManagementPage> {
  List<Mcp> _services = [];
  bool _isLoading = true;
  final Set<String> _loadingServices = {};
  bool _embeddedActionsSynced = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final mcpc = Get.find<McpController>();
    await mcpc.ensureLoaded();
    if (mounted) {
      setState(() {
        _services = mcpc.configs.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content =
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody();

    if (widget.embedded) {
      _syncEmbeddedActionsOnce();
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: StandardAppBar(
        title: 'MCP 管理',
        actions: [
          IconButton(
            tooltip: '添加 MCP',
            onPressed: () => _showAddMcpDialog(),
            icon: Icon(
              Icons.add,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
    );
  }

  void _syncEmbeddedActionsOnce() {
    if (_embeddedActionsSynced) return;
    _embeddedActionsSynced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onActionsChanged?.call(_buildActions());
    });
  }

  List<Widget> _buildActions() {
    return [
      Transform.translate(
        offset: const Offset(0, -5),
        child: IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '添加 MCP',
          onPressed: () => _showAddMcpDialog(),
          icon: Icon(
            Icons.add,
            size: 16,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    ];
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    if (_services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            Expanded(child: _buildEmptyState(theme)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns =
                    width >= 1180
                        ? 6
                        : width >= 900
                        ? 4
                        : width >= 640
                        ? 3
                        : 1;
                final spacing = 8.0;
                final itemWidth = (width - spacing * (columns - 1)) / columns;
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children:
                        _services.map((service) {
                          return SizedBox(
                            width: itemWidth,
                            child: _McpCard(
                              service: service,
                              loading: _loadingServices.contains(service.name),
                              onTap: () => _showServiceDetail(service),
                              onRefresh: () => _refreshService(service),
                              onDelete: () => _confirmRemoveService(service),
                            ),
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MCP 管理',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '管理全局 MCP 服务、连接配置和可用工具',
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        );
        final action = FilledButton.icon(
          onPressed: _showAddMcpDialog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加 MCP'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF111827),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), action],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: title), const SizedBox(width: 20), action],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE1E4E8),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_outlined,
              size: 42,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 14),
            Text(
              '暂无 MCP 服务',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添加一个 MCP 服务后，可在会话中绑定使用',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加 MCP 弹窗
  void _showAddMcpDialog() {
    final jsonCtrl = TextEditingController();
    String? parseError;
    McpParseResult? parsedResult;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '添加 MCP',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Material(
                      color: Theme.of(ctx).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 头部
                            Row(
                              children: [
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '添加 MCP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(ctx).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: '关闭',
                                  onPressed: () => Navigator.pop(ctx),
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Theme.of(ctx).colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      ctx,
                                    ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    ctx,
                                  ).dividerColor.withValues(alpha: 0.6),
                                ),
                              ),
                              child: TextField(
                                controller: jsonCtrl,
                                maxLines: 12,
                                minLines: 8,
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Theme.of(ctx).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      '{\n  "mcpServers": {\n    "server-name": {\n      "command": "...",\n      "args": ["..."]\n    }\n  }\n}',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                                onChanged: (text) {
                                  setDialogState(() {
                                    parseError = null;
                                    parsedResult = null;
                                    if (text.trim().isNotEmpty) {
                                      parsedResult = McpJsonParser.parse(text);
                                    }
                                  });
                                },
                              ),
                            ),
                            if (parsedResult != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '识别到: ${parsedResult!.name}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (parseError != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 14,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        parseError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            ctx,
                                          ).textTheme.labelLarge?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed:
                                      parsedResult == null
                                          ? null
                                          : () async {
                                            Navigator.pop(ctx);
                                            await _saveNewMcp(
                                              parsedResult!.name,
                                              parsedResult!.serverJson,
                                              parsedResult!.serverConfig,
                                            );
                                          },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.black
                                        .withValues(alpha: 0.25),
                                    disabledForegroundColor: Colors.white
                                        .withValues(alpha: 0.6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('添加'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 保存新添加的 MCP
  Future<void> _saveNewMcp(
    String name,
    Map<String, dynamic> serverJson,
    Map<String, dynamic> serverConfig,
  ) async {
    try {
      final mcpc = Get.find<McpController>();
      final mcp = Mcp(
        name: name,
        description: '',
        command: serverConfig['command'] as String?,
        args: (serverConfig['args'] as List?)?.cast<String>(),
        url: serverConfig['url'] as String?,
        headers:
            serverConfig['headers'] != null
                ? Map<String, String>.from(serverConfig['headers'] as Map)
                : null,
      );
      await mcpc.addService(mcp, serverJson: serverJson);

      await _loadServices();
      if (mounted) {
        SnackBarUtils.showSuccess(context, '已添加: $name');
      }

      // 自动刷新获取工具列表
      _refreshService(mcp);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '添加失败: $e');
      }
    }
  }

  /// 刷新服务工具列表
  Future<void> _refreshService(Mcp service) async {
    if (!mounted) return;
    setState(() => _loadingServices.add(service.name));
    try {
      final tools = await McpController.instance.refreshServiceTools(service);

      String finalDescription = service.description ?? '';
      if (tools.isNotEmpty) {
        final summary = await McpController.instance.summarizeWithLLM(
          serverName: service.name,
          tools: tools,
        );
        if (summary != null) {
          finalDescription = summary['description'] ?? '';
        } else {
          finalDescription =
              '提供 ${tools.length} 个工具: ${tools.map((t) => t.name).join(", ")}';
        }
      }

      final updatedService = service.copyWith(
        description: finalDescription,
        tools: tools,
        lastUpdated: DateTime.now(),
      );

      await Get.find<McpController>().updateService(
        service.name,
        updatedService,
      );
      await _loadServices();

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已刷新 ${tools.length} 个工具');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '刷新失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingServices.remove(service.name));
      }
    }
  }

  /// 显示服务详情
  void _showServiceDetail(Mcp service) async {
    final mcpObj = Get.find<McpController>().getMcp(service.name) ?? service;

    final serverJson = mcpObj.toJson();
    final tools = mcpObj.tools ?? [];
    final jsonCtrl = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(serverJson),
    );
    dynamic previewJson = serverJson;
    bool isEditingJson = false;
    String? parseError;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MCP 详情',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: FadeTransition(
            opacity: anim1,
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 700,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                  ),
                  child: Material(
                    color:
                        Theme.of(ctx).brightness == Brightness.dark
                            ? const Color(0xFF111827)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 头部
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF111827,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.extension_outlined,
                                  size: 22,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (service.description != null &&
                                        service.description!.isNotEmpty)
                                      Text(
                                        service.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // 可编辑内容区
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 工具列表
                                if (tools.isNotEmpty) ...[
                                  Text(
                                    '工具列表 (${tools.length})',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          Theme.of(ctx).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children:
                                        tools.map((tool) {
                                          final name = tool.name;
                                          final desc = tool.description;
                                          final label =
                                              desc.isNotEmpty
                                                  ? '$name - $desc'
                                                  : name;
                                          return Tooltip(
                                            message:
                                                desc.isNotEmpty ? desc : name,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF111827,
                                                ).withValues(alpha: 0.06),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Theme.of(ctx)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.08),
                                                ),
                                              ),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      Theme.of(
                                                        ctx,
                                                      ).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 14,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '暂未获取工具列表，请点击刷新按钮',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '脚本配置',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              Theme.of(
                                                ctx,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: '复制 JSON',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: jsonCtrl.text),
                                        );
                                        if (ctx.mounted) {
                                          SnackBarUtils.showSuccess(ctx, '已复制');
                                        }
                                      },
                                      icon: const Icon(Icons.copy, size: 16),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        if (isEditingJson) {
                                          try {
                                            previewJson =
                                                jsonDecode(jsonCtrl.text.trim())
                                                    as Map<String, dynamic>;
                                            setSheetState(() {
                                              parseError = null;
                                              isEditingJson = false;
                                            });
                                          } catch (_) {
                                            setSheetState(
                                              () => parseError = 'JSON 格式错误',
                                            );
                                          }
                                          return;
                                        }
                                        setSheetState(() {
                                          isEditingJson = true;
                                          parseError = null;
                                        });
                                      },
                                      icon: Icon(
                                        isEditingJson
                                            ? Icons.visibility
                                            : Icons.edit,
                                        size: 14,
                                      ),
                                      label: Text(isEditingJson ? '预览' : '编辑'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Theme.of(ctx).colorScheme.onSurface
                                          .withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child:
                                      isEditingJson
                                          ? TextField(
                                            controller: jsonCtrl,
                                            maxLines: 15,
                                            minLines: 8,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              color:
                                                  Theme.of(
                                                    ctx,
                                                  ).colorScheme.onSurface,
                                            ),
                                            decoration: InputDecoration(
                                              border: const OutlineInputBorder(
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.all(12),
                                            ),
                                            onChanged: (_) {
                                              if (parseError != null) {
                                                setSheetState(
                                                  () => parseError = null,
                                                );
                                              }
                                            },
                                          )
                                          : ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: 180,
                                              maxHeight: 320,
                                            ),
                                            child: SingleChildScrollView(
                                              padding: const EdgeInsets.all(12),
                                              child: JsonView(
                                                previewJson,
                                                initialExpandDepth: 4,
                                              ),
                                            ),
                                          ),
                                ),
                                if (!isEditingJson) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_tree_outlined,
                                        size: 13,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '点击箭头可展开或收起节点',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (parseError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    parseError!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // 底部按钮
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(
                                  ctx,
                                ).dividerColor.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (!Get.find<McpController>().isBuiltin(
                                service.name,
                              ))
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _confirmRemoveService(service);
                                  },
                                  icon: const Icon(Icons.delete, size: 14),
                                  label: const Text('移除'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () async {
                                  final jsonText = jsonCtrl.text.trim();
                                  Map<String, dynamic> newServerJson;
                                  try {
                                    newServerJson =
                                        jsonDecode(jsonText)
                                            as Map<String, dynamic>;
                                  } catch (e) {
                                    setSheetState(
                                      () => parseError = 'JSON 格式错误',
                                    );
                                    return;
                                  }

                                  await Get.find<McpController>()
                                      .updateServerConfig(
                                        service.name,
                                        newServerJson,
                                      );

                                  final mcpServers =
                                      newServerJson['mcpServers']
                                          as Map<String, dynamic>?;
                                  final serverConfig =
                                      mcpServers?.values.firstOrNull
                                          as Map<String, dynamic>?;
                                  final updatedService = service.copyWith(
                                    command:
                                        serverConfig?['command'] as String?,
                                    args:
                                        (serverConfig?['args'] as List?)
                                            ?.cast<String>(),
                                  );
                                  await Get.find<McpController>().updateService(
                                    service.name,
                                    updatedService,
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  await _loadServices();
                                  if (mounted) {
                                    SnackBarUtils.showSuccess(context, '配置已更新');
                                  }
                                },
                                icon: const Icon(Icons.check, size: 14),
                                label: const Text('保存'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 确认移除服务
  void _confirmRemoveService(Mcp service) {
    ConfirmDeleteDialog.show(
      context: context,
      title: '移除 MCP',
      itemName: service.name,
      description: '确定要移除该 MCP 服务',
      confirmText: '移除',
    ).then((confirmed) async {
      if (confirmed == true) {
        await Get.find<McpController>().removeService(service.name);
        final sessionController = Get.find<SessionController>();
        for (final session in sessionController.sessions) {
          if (session.mcps != null && session.mcps!.contains(service.name)) {
            final newMcps = List<String>.from(session.mcps!)
              ..remove(service.name);
            await sessionController.updateSession(
              session.copyWith(
                mcps: newMcps.isNotEmpty ? newMcps : null,
                clearMcp: newMcps.isEmpty,
                clearConnectPrompt: true,
              ),
            );
          }
        }
        await _loadServices();
        if (mounted) {
          SnackBarUtils.showInfo(context, '已移除: ${service.name}');
        }
      }
    });
  }
}

/// MCP 卡片组件
class _McpCard extends StatefulWidget {
  final Mcp service;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _McpCard({
    required this.service,
    this.loading = false,
    required this.onTap,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  State<_McpCard> createState() => _McpCardState();
}

class _McpCardState extends State<_McpCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final isBuiltin = Get.find<McpController>().isBuiltin(service.name);
    final description =
        service.description?.isNotEmpty == true ? service.description : null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final toolsCount = service.tools?.length ?? 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color:
                _isHovered
                    ? (isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFFAFAFA))
                    : (isDark ? const Color(0xFF111827) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _isHovered
                      ? const Color(0xFF111827).withValues(alpha: 0.45)
                      : (isDark
                          ? const Color(0xFF2D2F3A)
                          : const Color(0xFFE1E4E8)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            service.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isBuiltin) ...[
                          const SizedBox(width: 4),
                          _McpPill(label: '内置', color: const Color(0xFF3B82F6)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description ?? service.command ?? service.url ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: description == null ? 10 : 10.5,
                        height: 1.1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                        fontFamily: description == null ? 'monospace' : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _McpMeta(
                      icon: Icons.build_outlined,
                      label: '$toolsCount 个工具',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _McpIconButton(
                tooltip: '刷新工具',
                onTap: widget.loading ? null : widget.onRefresh,
                compact: true,
                child:
                    widget.loading
                        ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.7,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                        : const Icon(Icons.refresh, size: 14),
              ),
              const SizedBox(width: 4),
              if (!isBuiltin)
                _McpIconButton(
                  tooltip: '删除',
                  onTap: widget.onDelete,
                  danger: true,
                  compact: true,
                  child: const Icon(Icons.delete_outline, size: 14),
                ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _McpPill extends StatelessWidget {
  final String label;
  final Color color;

  const _McpPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _McpIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;
  final bool danger;
  final bool compact;

  const _McpIconButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.danger = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        danger ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: compact ? 24 : 32,
          height: compact ? 24 : 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconTheme(
            data: IconThemeData(
              color: color.withValues(alpha: onTap == null ? 0.35 : 0.75),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _McpMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _McpMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 1.1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
          ),
        ),
      ],
    );
  }
}
