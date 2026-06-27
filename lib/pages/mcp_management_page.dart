import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/mcp_controller.dart';
import '../controllers/session_controller.dart';
import '../models/chat/mcp_config.dart';
import '../mcp_builtins/mcp_storage_manager.dart';
import '../services/mcp_service.dart';
import '../utils/mcp_json_parser.dart';
import '../utils/snackbar_utils.dart';

class McpManagementPage extends StatefulWidget {
  final bool embedded;
  final Function(List<Widget>)? onActionsChanged;

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
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildContent();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MCP 管理'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus, size: 18),
            onPressed: _showAddMcpDialog,
            tooltip: '添加 MCP',
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildServiceList();
  }

  Widget _buildServiceList() {
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.cube_box, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无 MCP 服务', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('点击右上角 + 添加', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
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
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.0,
        ),
        itemCount: _services.length,
        itemBuilder: (_, i) => _buildServiceCard(_services[i]),
      ),
    );
  }

  Widget _buildServiceCard(Mcp service) {
    final isBuiltin = Get.find<McpController>().isBuiltin(service.mcpId);

    return GestureDetector(
      onTap: () => _showServiceDetail(service),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(CupertinoIcons.cube_box, size: 14, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          service.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
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
                  if (service.description != null && service.description!.isNotEmpty)
                    Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _refreshService(service),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.refresh, size: 9, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                if (!isBuiltin) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _confirmRemoveService(service),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.delete, size: 9, color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ],
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
                      hintText: '''{
  "mcpServers": {
    "@negokaz/excel-mcp-server": {
      "command": "npx",
      "args": ["-y", "@mcp_hub_org/cli@latest", "run", "@negokaz/excel-mcp-server"]
    }
  }
}''',
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

                // 解析预览
                if (parsedResult != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.checkmark_circle, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '识别到: ${parsedResult!.name}',
                              style: TextStyle(fontSize: 11, color: Colors.green[700]),
                            ),
                          ],
                        ),
                        if (parsedResult!.command != null)
                          Text(
                            '命令: ${parsedResult!.command}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                        Icon(CupertinoIcons.exclamationmark_circle, size: 12, color: Colors.red),
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
      final data = McpData(
        name: name,
        server: serverJson,
        config: {
          'name': name,
          'description': serverConfig['description'] as String? ?? '',
          'tools': [],
        },
      );
      await McpStorageManager.save(data);

      // 添加到控制器 - 包含 url 和 headers
      final mcpc = Get.find<McpController>();
      final mcp = Mcp(
        mcpId: 'mcp_$name',
        name: name,
        description: serverConfig['description'] as String?,
        code: jsonEncode(serverJson),
        command: serverConfig['command'] as String?,
        args: (serverConfig['args'] as List?)?.cast<String>(),
        url: serverConfig['url'] as String?,
        headers: serverConfig['headers'] != null
            ? Map<String, String>.from(serverConfig['headers'] as Map)
            : null,
        // 不设置 type，让连接时自动检测（先 SSE 后 HTTP）
      );
      await mcpc.addService(mcp, serverJson: serverJson);

      await _loadServices();
      if (mounted) {
        SnackBarUtils.showSuccess(context, '已添加: $name');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '添加失败: $e');
      }
    }
  }

  /// 刷新服务工具列表
  Future<void> _refreshService(Mcp service) async {
    try {
      final tools = await McpService.refreshServiceTools(service);
      final updatedService = service.copyWith(
        tools: tools,
        lastUpdated: DateTime.now(),
      );
      await Get.find<McpController>().updateService(service.mcpId, updatedService);
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

  /// 显示服务详情（可编辑 server.json）
  void _showServiceDetail(Mcp service) async {
    // 加载 server.json 内容
    final mcpData = await McpStorageManager.loadAll().then(
      (list) => list.where((d) => d.name == service.name).firstOrNull,
    );

    final serverJson = mcpData?.server ?? {};
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
                              Icon(CupertinoIcons.cube_box, size: 20, color: Theme.of(ctx).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    if (service.description != null)
                                      Text(
                                        service.description!,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // 可编辑的 server.json
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                              if (!Get.find<McpController>().isBuiltin(service.mcpId))
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _confirmRemoveService(service);
                                  },
                                  icon: const Icon(CupertinoIcons.delete, size: 14),
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

                                  // 保存到 server.json
                                  await Get.find<McpController>().updateServerConfig(
                                    service.mcpId,
                                    newServerJson,
                                  );

                                  // 更新 Mcp 模型
                                  final mcpServers = newServerJson['mcpServers'] as Map<String, dynamic>?;
                                  final serverConfig = mcpServers?.values.firstOrNull as Map<String, dynamic>?;
                                  final updatedService = service.copyWith(
                                    code: jsonEncode(newServerJson),
                                    command: serverConfig?['command'] as String?,
                                    args: (serverConfig?['args'] as List?)?.cast<String>(),
                                  );
                                  await Get.find<McpController>().updateService(
                                    service.mcpId,
                                    updatedService,
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    await _loadServices();
                                    SnackBarUtils.showSuccess(context, '配置已更新');
                                  }
                                },
                                icon: const Icon(CupertinoIcons.checkmark, size: 14),
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
        await Get.find<McpController>().removeService(service.mcpId);
        // 清理会话引用
        final sessionController = Get.find<SessionController>();
        for (final session in sessionController.sessions) {
          if (session.mcpId == service.mcpId) {
            await sessionController.updateSession(
              session.copyWith(clearMcp: true, clearConnectPrompt: true),
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
