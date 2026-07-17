import 'dart:convert';

import '../../../widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/mcp_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../models/chat/mcp.dart';
import '../../../utils/snackbar_utils.dart';

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
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildBody();

    if (widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onActionsChanged?.call(_buildActions());
      });
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
    );
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    ];
  }

  Widget _buildBody() {
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无 MCP 服务',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '点击右上角 + 添加',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 3.0,
        ),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return _McpCard(
            service: service,
            onTap: () => _showServiceDetail(service),
            onRefresh: () => _refreshService(service),
            onDelete: () => _confirmRemoveService(service),
          );
        },
      ),
    );
  }

  /// 显示添加 MCP 弹窗
  void _showAddMcpDialog() {
    final jsonCtrl = TextEditingController();
    String? parseError;
    McpParseResult? parsedResult;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加 MCP'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '支持的格式：\n• mcpServers 包装格式\n• 直接配置格式（含 command 或 url）',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: jsonCtrl,
                    maxLines: 12,
                    minLines: 8,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '{\n  "mcpServers": {\n    "server-name": {\n      "command": "...",\n      "args": ["..."]\n    }\n  }\n}',
                      hintStyle: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      border: const OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '识别到: ${parsedResult!.name}',
                          style: TextStyle(fontSize: 11, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                ],
                if (parseError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(parseError!, style: TextStyle(fontSize: 11, color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: parsedResult == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _saveNewMcp(
                        parsedResult!.name,
                        parsedResult!.serverJson,
                        parsedResult!.serverConfig,
                      );
                    },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存新添加的 MCP
  Future<void> _saveNewMcp(String name, Map<String, dynamic> serverJson, Map<String, dynamic> serverConfig) async {
    try {
      final mcpc = Get.find<McpController>();
      final mcp = Mcp(
        name: name,
        description: '',
        command: serverConfig['command'] as String?,
        args: (serverConfig['args'] as List?)?.cast<String>(),
        url: serverConfig['url'] as String?,
        headers: serverConfig['headers'] != null
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
          finalDescription = '提供 ${tools.length} 个工具: ${tools.map((t) => t.name).join(", ")}';
        }
      }

      final updatedService = service.copyWith(
        description: finalDescription,
        tools: tools,
        lastUpdated: DateTime.now(),
      );

      await Get.find<McpController>().updateService(service.name, updatedService);
      await _loadServices();

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已刷新 ${tools.length} 个工具');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '刷新失败: $e');
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
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 头部
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.widgets, size: 20, color: Theme.of(ctx).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    if (service.description != null && service.description!.isNotEmpty)
                                      Text(
                                        service.description!,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 工具列表
                                if (tools.isNotEmpty) ...[
                                  Text(
                                    '工具列表 (${tools.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(ctx).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: tools.map((tool) {
                                      final name = tool.name;
                                      final desc = tool.description;
                                      final label = desc.isNotEmpty ? '$name - $desc' : name;
                                      return Tooltip(
                                        message: desc.isNotEmpty ? desc : name,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Theme.of(ctx).colorScheme.primary.withOpacity(0.15),
                                            ),
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(ctx).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
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
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, size: 14, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Text(
                                          '暂未获取工具列表，请点击刷新按钮',
                                          style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // 脚本配置
                                Text(
                                  '脚本配置 (server.json)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: jsonCtrl,
                                    maxLines: 15,
                                    minLines: 8,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: Theme.of(ctx).colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.all(12),
                                    ),
                                    onChanged: (_) {
                                      if (parseError != null) setSheetState(() => parseError = null);
                                    },
                                  ),
                                ),
                                if (parseError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(parseError!, style: TextStyle(fontSize: 11, color: Colors.red)),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // 底部按钮
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Theme.of(ctx).dividerColor.withOpacity(0.3))),
                          ),
                          child: Row(
                            children: [
                              if (!Get.find<McpController>().isBuiltin(service.name))
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
                                    newServerJson = jsonDecode(jsonText) as Map<String, dynamic>;
                                  } catch (e) {
                                    setSheetState(() => parseError = 'JSON 格式错误');
                                    return;
                                  }

                                  await Get.find<McpController>().updateServerConfig(
                                    service.name,
                                    newServerJson,
                                  );

                                  final mcpServers = newServerJson['mcpServers'] as Map<String, dynamic>?;
                                  final serverConfig = mcpServers?.values.firstOrNull as Map<String, dynamic>?;
                                  final updatedService = service.copyWith(
                                    command: serverConfig?['command'] as String?,
                                    args: (serverConfig?['args'] as List?)?.cast<String>(),
                                  );
                                  await Get.find<McpController>().updateService(
                                    service.name,
                                    updatedService,
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    await _loadServices();
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
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('移除 ${service.name}'),
        content: const Text('确定要移除该 MCP 服务吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
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
  final VoidCallback onTap;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _McpCard({
    required this.service,
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
    final description = service.description?.isNotEmpty == true ? service.description : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.35)
                  : Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isBuiltin) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text('内置', style: TextStyle(fontSize: 8, color: Colors.blue)),
                          ),
                        ],
                      ],
                    ),
                    if (description != null)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        service.command ?? service.url ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: widget.onRefresh,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh,
                        size: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (!isBuiltin) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 10,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
