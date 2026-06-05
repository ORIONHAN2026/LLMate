import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/chat/mcp_config.dart';
import '../services/mcp_service.dart';
import '../controllers/session_controller.dart';
import '../controllers/mcp_controller.dart';
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

  Future<void> _removeService(String mcpId, String displayName) async {
    // 通过 McpController 统一移除（同步清理 configs 列表 + 存储）
    await Get.find<McpController>().removeService(mcpId);

    // 清理所有引用此 MCP 的会话：清除 mcpId、mcp 和 connectPrompt
    final sessionController = Get.find<SessionController>();
    for (final session in sessionController.sessions) {
      if (session.mcpId == mcpId) {
        await sessionController.updateSession(
          session.copyWith(clearMcp: true, clearConnectPrompt: true),
        );
      }
    }

    await _loadServices();
    if (mounted) {
      SnackBarUtils.showInfo(context, '已移除服务: $displayName');
    }
  }

  void _showAddMcpDialog() {
    final jsonCtrl = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert({
        'command': 'npx',
        'args': ['-y', 'package-name'],
        'timeout': 30,
      }),
    );
    bool isConnecting = false;
    String? errorMessage;
    // 默认超时 30 秒
    int timeoutSec = 30;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
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
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '如果 JSON 中包含 "mcpServers" 字段，会自动从中提取服务配置',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 超时设置
                          Row(
                            children: [
                              Text(
                                '连接超时',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                height: 28,
                                child: TextField(
                                  enabled: !isConnecting,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 6,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(
                                    text: '$timeoutSec',
                                  ),
                                  onChanged: (v) {
                                    final parsed = int.tryParse(v);
                                    if (parsed != null && parsed > 0)
                                      timeoutSec = parsed;
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '秒',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'JSON 配置',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '支持 command/args 或 url/headers 格式。URL 型必须在 JSON 中指定 "type" 字段（"sse" 或 "http"），否则无法添加',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: jsonCtrl,
                              maxLines: 8,
                              minLines: 5,
                              enabled: !isConnecting,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: Color(0xFFD4D4D4),
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
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
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '正在连接服务器...',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // 错误提示（内联展示，不关闭弹窗）
                          if (errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    CupertinoIcons.exclamationmark_circle,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        height: 1.4,
                                      ),
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
                      onPressed: isConnecting ? null : () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed:
                          isConnecting
                              ? null
                              : () async {
                                try {
                                  final json =
                                      jsonDecode(jsonCtrl.text)
                                          as Map<String, dynamic>;

                                  // 支持 mcpServers 包裹格式，自动提取第一个服务
                                  Map<String, dynamic> serviceJson = json;
                                  final mcpServers =
                                      json['mcpServers']
                                          as Map<String, dynamic>?;
                                  if (mcpServers != null &&
                                      mcpServers.isNotEmpty) {
                                    serviceJson =
                                        mcpServers.entries.first.value
                                            as Map<String, dynamic>;
                                  }

                                  // 先生成一个临时名称
                                  final tempName =
                                      'mcp_${DateTime.now().millisecondsSinceEpoch}';
                                  // 优先使用 JSON 中的 timeout，否则用 UI 设置的
                                  final effectiveTimeout =
                                      serviceJson['timeout'] as int? ??
                                      timeoutSec;

                                  // URL 型 MCP，type 默认为 http
                                  final hasUrl =
                                      serviceJson['url'] is String &&
                                      (serviceJson['url'] as String).isNotEmpty;
                                  if (hasUrl) {
                                    final typeVal =
                                        serviceJson['type'] as String?;
                                    if (typeVal == null || typeVal.isEmpty) {
                                      serviceJson['type'] = 'http';
                                    } else if (typeVal != 'sse' &&
                                        typeVal != 'http' &&
                                        typeVal != 'streamableHttp') {
                                      setDialogState(() {
                                        errorMessage =
                                            '❌ 不支持的传输类型: "$typeVal"\n\n'
                                            '支持的类型：\n'
                                            '  "type": "sse"  — SSE 长连接传输\n'
                                            '  "type": "http" — Streamable HTTP 传输';
                                      });
                                      return;
                                    }
                                  }

                                  final config = Mcp(
                                    mcpId:
                                        'mcp_${DateTime.now().millisecondsSinceEpoch}',
                                    name: tempName,
                                    command: serviceJson['command'] as String?,
                                    args:
                                        (serviceJson['args'] as List<dynamic>?)
                                            ?.cast<String>(),
                                    timeout: effectiveTimeout,
                                    url: serviceJson['url'] as String?,
                                    headers:
                                        serviceJson['headers'] != null
                                            ? Map<String, String>.from(
                                              serviceJson['headers'],
                                            )
                                            : null,
                                    env:
                                        serviceJson['env'] != null
                                            ? Map<String, String>.from(
                                              serviceJson['env'],
                                            )
                                            : null,
                                    workingDirectory:
                                        serviceJson['workingDirectory']
                                            as String?,
                                    type:
                                        hasUrl
                                            ? McpTransportTypeExt.fromString(
                                              serviceJson['type'] as String?,
                                            )
                                            : null,
                                  );

                                  // 清除旧错误，显示加载状态
                                  setDialogState(() {
                                    errorMessage = null;
                                    isConnecting = true;
                                  });

                                  // 连接远程获取真实名称和工具
                                  final info =
                                      await McpService.connectAndGetInfo(
                                        config,
                                      );

                                  // 用真实名称创建最终配置（prompt 已生成）
                                  final realConfig = config.copyWith(
                                    name: info.serverName,
                                    description: info.description,
                                    tools: info.tools,
                                    lastUpdated: DateTime.now(),
                                    prompt: info.prompt,
                                  );

                                  Navigator.pop(ctx);
                                  _addServiceWithInfo(
                                    realConfig,
                                    toolCount: info.tools.length,
                                  );
                                } on TimeoutException catch (e) {
                                  setDialogState(() {
                                    isConnecting = false;
                                    errorMessage =
                                        '⏱ 连接超时\n\n${e.message}\n\n请检查服务器地址是否正确，或尝试增大超时时间后重试。';
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isConnecting = false;
                                    final msg = e.toString();
                                    errorMessage =
                                        '❌ 连接失败\n\n${msg.length > 200 ? '${msg.substring(0, 200)}...' : msg}\n\n请检查配置是否正确，修改后重试。';
                                  });
                                }
                              },
                      child: Text(isConnecting ? '连接中...' : '连接并添加'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _addServiceWithInfo(Mcp config, {required int toolCount}) async {
    if (_services.any((s) => s.name == config.name)) {
      SnackBarUtils.showInfo(context, '服务 "${config.name}" 已存在');
      return;
    }
    await Get.find<McpController>().addService(config);
    await _loadServices();
    if (mounted) {
      SnackBarUtils.showSuccess(
        context,
        '已添加: ${config.name} (${toolCount} 个工具)',
      );
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
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const McpMarketplacePage()),
                ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body:
          _isLoading
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '点击右上角 + 号添加，或搜索应用市场',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.35),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const McpMarketplacePage(),
                      ),
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

  Widget _buildAddedServiceCard(Mcp service) {
    final typeLabel = _getTypeLabel(service);
    final description = service.description;
    final subtitle = _buildSubtitle(service);

    return GestureDetector(
      onTap: () => _showAddedServiceDetail(service),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 刷新按钮
            _buildRefreshButton(service),
            const SizedBox(width: 4),
            // 删除按钮
            GestureDetector(
              onTap: () => _confirmRemoveService(service),
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

  String _getTypeLabel(Mcp service) {
    if (service.url != null && service.url!.isNotEmpty) {
      switch (service.type) {
        case McpTransportType.sse:
          return 'SSE';
        case McpTransportType.http:
        case McpTransportType.streamableHttp:
          return 'HTTP';
        default:
          return 'URL';
      }
    }
    return 'Stdio';
  }

  final Set<String> _refreshingServices = {};

  Widget _buildRefreshButton(Mcp service) {
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
        child:
            isRefreshing
                ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    strokeCap: StrokeCap.round,
                  ),
                )
                : Icon(
                  CupertinoIcons.refresh,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
      ),
    );
  }

  Future<void> _refreshService(Mcp service) async {
    if (_refreshingServices.contains(service.name)) return;

    setState(() => _refreshingServices.add(service.name));

    try {
      final tools = await McpService.refreshServiceTools(service);

      final updatedService = service.copyWith(
        description: McpService.getCachedConfig(service.mcpId)?.description,
        tools: tools,
        lastUpdated: DateTime.now(),
        prompt: McpService.buildMcpPrompt(service.copyWith(tools: tools)),
      );
      await Get.find<McpController>().updateService(
        service.mcpId,
        updatedService,
      );

      // 重新加载列表以刷新 UI
      await _loadServices();

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已获取 ${tools.length} 个工具');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '获取工具失败: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingServices.remove(service.name));
      }
    }
  }

  Future<void> _confirmRemoveService(Mcp service) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('移除服务'),
            content: Text('确定要移除 "${service.name}" 吗？'),
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
      await _removeService(service.mcpId, service.name);
    }
  }

  void _showAddedServiceDetail(Mcp service) {
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
                final tools = service.tools;
                final hasTools = tools != null && tools.isNotEmpty;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 700,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                  ),
                  child: Material(
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 头部
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            service.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            _getTypeLabel(service),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      service.description?.isNotEmpty == true
                                          ? service.description!
                                          : _buildSubtitle(service),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      final newTools =
                                          await McpService.refreshServiceTools(
                                            service,
                                          );
                                      final updatedService = service.copyWith(
                                        description:
                                            McpService.getCachedConfig(
                                              service.mcpId,
                                            )?.description,
                                        tools: newTools,
                                        lastUpdated: DateTime.now(),
                                        prompt: McpService.buildMcpPrompt(
                                          service.copyWith(tools: newTools),
                                        ),
                                      );
                                      await Get.find<McpController>()
                                          .updateService(
                                            service.mcpId,
                                            updatedService,
                                          );
                                      service = updatedService;
                                      setSheetState(() {});
                                      if (ctx.mounted) {
                                        await _loadServices();
                                      }
                                      SnackBarUtils.showSuccess(
                                        ctx,
                                        '已刷新 ${newTools.length} 个工具',
                                      );
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        SnackBarUtils.showError(
                                          ctx,
                                          '刷新失败: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}',
                                        );
                                      }
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.refresh,
                                        size: 13,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '刷新',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  tools.take(50).map((t) {
                                    final label =
                                        t.description.isNotEmpty
                                            ? '${t.name} · ${t.description}'
                                            : t.name;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.15),
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
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
                                    final newTools =
                                        await McpService.refreshServiceTools(
                                          service,
                                        );
                                    final updatedService = service.copyWith(
                                      description:
                                          McpService.getCachedConfig(
                                            service.mcpId,
                                          )?.description,
                                      tools: newTools,
                                      lastUpdated: DateTime.now(),
                                      prompt: McpService.buildMcpPrompt(
                                        service.copyWith(tools: newTools),
                                      ),
                                    );
                                    await Get.find<McpController>()
                                        .updateService(
                                          service.mcpId,
                                          updatedService,
                                        );
                                    service = updatedService;
                                    setSheetState(() {});
                                    if (ctx.mounted) {
                                      await _loadServices();
                                    }
                                    SnackBarUtils.showSuccess(
                                      ctx,
                                      '已获取 ${newTools.length} 个工具',
                                    );
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      SnackBarUtils.showError(
                                        ctx,
                                        '获取失败: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}',
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(
                                  CupertinoIcons.arrow_down_to_line_alt,
                                  size: 15,
                                ),
                                label: const Text('获取工具列表'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // JSON 配置
                          Text(
                            'JSON 配置',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
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
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Color(0xFFD4D4D4),
                                height: 1.5,
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
                                _confirmRemoveService(service);
                              },
                              icon: const Icon(CupertinoIcons.delete, size: 16),
                              label: const Text('移除服务'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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

  String _buildSubtitle(Mcp service) {
    if (service.url != null && service.url!.isNotEmpty) {
      final typeLabel =
          (service.type == McpTransportType.http ||
                  service.type == McpTransportType.streamableHttp)
              ? ' [HTTP]'
              : (service.type == McpTransportType.sse ? ' [SSE]' : '');
      return '${service.url!}$typeLabel';
    }
    return '${service.command ?? ''} ${service.args?.join(' ') ?? ''}';
  }

  String _buildConfigJson(Mcp service) {
    final map = service.toJson();
    map['name'] = service.name;
    if (service.workingDirectory != null) {
      map['workingDirectory'] = service.workingDirectory;
    }
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
