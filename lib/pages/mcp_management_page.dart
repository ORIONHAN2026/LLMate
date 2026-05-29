import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/bigmodel/mcp_config.dart';
import '../services/mcp_service.dart';
import '../services/mcp_storage_service.dart';
import '../utils/snackbar_utils.dart';
import 'mcp_marketplace_page.dart';

/// MCP 管理页面
///
/// MCP 服务与会话/模型解耦，全局独立管理。
/// - 列表显示已添加服务，支持查看详情和删除
/// - 右上角 + 号自定义添加
/// - 右上角搜索按钮进入应用市场
class McpManagementPage extends StatefulWidget {
  const McpManagementPage({super.key});

  @override
  State<McpManagementPage> createState() => _McpManagementPageState();
}

class _McpManagementPageState extends State<McpManagementPage> {
  List<McpServerConfig> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final services = await McpStorageService.loadMcpServices();
    if (mounted) {
      setState(() {
        _services = services;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeService(String serviceName) async {
    await McpStorageService.removeMcpService(serviceName);
    await _loadServices();
    if (mounted) {
      SnackBarUtils.showInfo(context, '已移除服务: $serviceName');
    }
  }

  void _showAddMcpDialog() {

    // 默认提供两个示例模板
    final jsonCtrl = TextEditingController(text: const JsonEncoder.withIndent('  ').convert({
      'command': 'npx',
      'args': ['-y', 'package-name'],
      'timeout': 60,
    }));
    bool isConnecting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加 MCP 服务'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'name 和描述将从 MCP 服务器远程获取',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '如果 JSON 中包含 "mcpServers" 字段，会自动从中提取服务配置',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 10),
                  Text('JSON 配置', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
                  const SizedBox(height: 4),
                  Text(
                    '支持 command/args 或 url/headers 两种格式',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: jsonCtrl,
                      maxLines: 8, minLines: 5,
                      enabled: !isConnecting,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFFD4D4D4), height: 1.5),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(12),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  if (isConnecting) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, strokeCap: StrokeCap.round),
                          ),
                          SizedBox(width: 8),
                          Text('正在连接服务器...', style: TextStyle(fontSize: 12)),
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
              onPressed: isConnecting ? null : () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: isConnecting
                  ? null
                  : () async {
                      try {
                        final json = jsonDecode(jsonCtrl.text) as Map<String, dynamic>;

                        // 支持 mcpServers 包裹格式，自动提取第一个服务
                        Map<String, dynamic> serviceJson = json;
                        final mcpServers = json['mcpServers'] as Map<String, dynamic>?;
                        if (mcpServers != null && mcpServers.isNotEmpty) {
                          serviceJson = mcpServers.entries.first.value as Map<String, dynamic>;
                        }

                        // 先生成一个临时名称
                        final tempName = 'mcp_${DateTime.now().millisecondsSinceEpoch}';
                        final config = McpServerConfig(
                          name: tempName,
                          command: serviceJson['command'] as String? ?? '',
                          args: (serviceJson['args'] as List<dynamic>?)?.cast<String>() ?? [],
                          timeout: serviceJson['timeout'] as int?,
                          url: serviceJson['url'] as String?,
                          headers: serviceJson['headers'] != null
                              ? Map<String, String>.from(serviceJson['headers'])
                              : null,
                          env: serviceJson['env'] != null
                              ? Map<String, String>.from(serviceJson['env'])
                              : null,
                          workingDirectory: serviceJson['workingDirectory'] as String?,
                        );

                        // 显示加载状态
                        setDialogState(() => isConnecting = true);

                        // 连接远程获取真实名称和工具
                        final info = await McpService.connectAndGetInfo(config);

                        // 用真实名称创建最终配置
                        final realConfig = config.copyWith(
                          name: info.serverName,
                          tools: info.tools,
                          lastUpdated: DateTime.now(),
                        );

                        Navigator.pop(ctx);
                        _addServiceWithInfo(realConfig, toolCount: info.tools.length);
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => isConnecting = false);
                          SnackBarUtils.showError(context, '连接失败: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e}');
                        }
                      }
                    },
              child: const Text('连接并添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addServiceWithInfo(McpServerConfig config, {required int toolCount}) async {
    if (_services.any((s) => s.name == config.name)) {
      SnackBarUtils.showInfo(context, '服务 "${config.name}" 已存在');
      return;
    }
    await McpStorageService.addMcpService(config);
    await _loadServices();
    if (mounted) {
      SnackBarUtils.showSuccess(context, '已添加: ${config.name} (${toolCount} 个工具)');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('MCP 工具管理'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled, size: 22),
            tooltip: '添加 MCP 服务',
            onPressed: _showAddMcpDialog,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.search, size: 22),
            tooltip: 'MCP 应用市场',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const McpMarketplacePage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildServiceGrid(),
    );
  }

  Widget _buildServiceGrid() {
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.tray,
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
              '点击右上角 + 号添加，或搜索应用市场',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '已添加 ${_services.length} 个服务',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const McpMarketplacePage()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '应用市场',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final service = _services[index];
              return _buildAddedServiceCard(service);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddedServiceCard(McpServerConfig service) {
    final hasTools = service.tools != null && service.tools!.isNotEmpty;
    final toolCount = service.tools?.length ?? 0;

    return GestureDetector(
      onTap: () => _showAddedServiceDetail(service),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasTools
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                service.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (hasTools) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$toolCount 个工具',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildSubtitle(service),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 工具标签区域
                  if (hasTools) ...[
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: service.tools!.map((tool) {
                        final label = tool.description.isNotEmpty
                            ? '${tool.name} · ${tool.description}'
                            : tool.name;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 刷新按钮
            _buildRefreshButton(service),
            const SizedBox(width: 4),
            // 删除按钮
            GestureDetector(
              onTap: () => _confirmRemoveService(service.name),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.delete,
                  size: 14,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final Set<String> _refreshingServices = {};

  Widget _buildRefreshButton(McpServerConfig service) {
    final isRefreshing = _refreshingServices.contains(service.name);
    return GestureDetector(
      onTap: isRefreshing ? null : () => _refreshService(service),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: isRefreshing
            ? const Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(strokeWidth: 2, strokeCap: StrokeCap.round),
              )
            : Icon(
                CupertinoIcons.refresh,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }

  Future<void> _refreshService(McpServerConfig service) async {
    if (_refreshingServices.contains(service.name)) return;

    setState(() => _refreshingServices.add(service.name));

    try {
      final tools = await McpService.refreshServiceTools(service);

      final updatedService = service.copyWith(
        tools: tools,
        lastUpdated: DateTime.now(),
      );
      await McpStorageService.updateMcpService(service.name, updatedService);

      // 重新加载列表以刷新 UI
      await _loadServices();

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已获取 ${tools.length} 个工具');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '获取工具失败: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e}');
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingServices.remove(service.name));
      }
    }
  }

  Future<void> _confirmRemoveService(String serviceName) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除服务'),
        content: Text('确定要移除 "$serviceName" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      await _removeService(serviceName);
    }
  }

  void _showAddedServiceDetail(McpServerConfig service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final tools = service.tools;
          final hasTools = tools != null && tools.isNotEmpty;

          return DraggableScrollableSheet(
            initialChildSize: hasTools ? 0.6 : 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (ctx, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部拖动条
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // 头部
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.gear,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _buildSubtitle(service),
                                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 工具列表
                    if (hasTools) ...[
                      Row(
                        children: [
                          Text(
                            '工具列表 (${tools.length})',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              try {
                                final newTools = await McpService.refreshServiceTools(service);
                                final updatedService = service.copyWith(tools: newTools, lastUpdated: DateTime.now());
                                await McpStorageService.updateMcpService(service.name, updatedService);
                                service = updatedService;
                                setSheetState(() {});
                                if (ctx.mounted) {
                                  await _loadServices();
                                }
                                SnackBarUtils.showSuccess(ctx, '已刷新 ${newTools.length} 个工具');
                              } catch (e) {
                                if (ctx.mounted) {
                                  SnackBarUtils.showError(ctx, '刷新失败: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}');
                                }
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.refresh, size: 13, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 4),
                                Text('刷新', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tools.take(50).map((t) {
                          final label = t.description.isNotEmpty
                              ? '${t.name} · ${t.description}'
                              : t.name;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (tools.length > 50)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '... 还有 ${tools.length - 50} 个工具',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ),
                      const SizedBox(height: 6),
                      const Divider(),
                      const SizedBox(height: 12),
                    ],

                    // 未获取工具时的获取按钮
                    if (!hasTools) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final newTools = await McpService.refreshServiceTools(service);
                              final updatedService = service.copyWith(tools: newTools, lastUpdated: DateTime.now());
                              await McpStorageService.updateMcpService(service.name, updatedService);
                              service = updatedService;
                              setSheetState(() {});
                              if (ctx.mounted) {
                                await _loadServices();
                              }
                              SnackBarUtils.showSuccess(ctx, '已获取 ${newTools.length} 个工具');
                            } catch (e) {
                              if (ctx.mounted) {
                                SnackBarUtils.showError(ctx, '获取失败: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}');
                              }
                            }
                          },
                          icon: const Icon(CupertinoIcons.arrow_down_to_line_alt, size: 15),
                          label: const Text('获取工具列表'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // JSON 配置
                    Text('JSON 配置', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _buildConfigJson(service),
                        style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace',
                          color: Color(0xFFD4D4D4), height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 删除按钮
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmRemoveService(service.name);
                        },
                        icon: const Icon(CupertinoIcons.delete, size: 16),
                        label: const Text('移除服务'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _buildSubtitle(McpServerConfig service) {
    if (service.url != null && service.url!.isNotEmpty) {
      return service.url!;
    }
    return '${service.command} ${service.args.join(' ')}';
  }

  String _buildConfigJson(McpServerConfig service) {
    final map = <String, dynamic>{
      'name': service.name,
    };
    // URL 型配置
    if (service.url != null && service.url!.isNotEmpty) {
      map['url'] = service.url;
      if (service.headers != null && service.headers!.isNotEmpty) {
        map['headers'] = service.headers;
      }
      if (service.timeout != null) map['timeout'] = service.timeout;
    } else {
      // command 型配置
      map['command'] = service.command;
      map['args'] = service.args;
      if (service.env != null && service.env!.isNotEmpty) map['env'] = service.env;
      if (service.workingDirectory != null) map['workingDirectory'] = service.workingDirectory;
      if (service.timeout != null) map['timeout'] = service.timeout;
    }
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
