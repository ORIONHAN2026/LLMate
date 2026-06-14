import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/chat/mcp_config.dart';
import '../services/mcp_service.dart';
import '../widgets/common/confirm_delete_dialog.dart';
import '../controllers/session_controller.dart';
import 'mcp_marketplace_page.dart';
import '../controllers/mcp_controller.dart';
import '../utils/snackbar_utils.dart';
import '../l10n/app_localizations.dart';

/// MCP 管理页面
///
/// MCP 服务与会话/模型解耦，全局独立管理。
/// - 列表显示已添加服务，支持查看详情和删除
/// - 右上角 + 号进入应用市场
String getTypeLabel(Mcp service) {
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

String buildSubtitle(Mcp service) {
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
  final GlobalKey _marketplaceButtonKey = GlobalKey();

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
      SnackBarUtils.showInfo(
        context,
        AppLocalizations.of(context)!.serviceRemoved(displayName),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildServiceGrid();

    if (widget.embedded) {
      // 通知父页面 AppBar actions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onActionsChanged?.call(_buildActions());
      });
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 44,
        leadingWidth: Platform.isMacOS ? 70 + 20 + 15 : 44,
        leading: Padding(
          padding: EdgeInsets.only(left: Platform.isMacOS ? 70 : 0),
          child: Transform.translate(
            offset: const Offset(0, -5),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              icon: const Icon(CupertinoIcons.back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Transform.translate(
          offset: const Offset(0, -5),
          child: Text(
            AppLocalizations.of(context)!.connectorManagementTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.addCustomConnector,
            onPressed: () {
              showCustomAddMcpDialog(
                context,
                onConfigReady: (config) {
                  showCustomAddProgressDialog(
                    context,
                    config,
                    onSuccess: (finalConfig, toolCount) async {
                      final mcpc = Get.find<McpController>();
                      await mcpc.ensureLoaded();
                      if (!mcpc.configs.any(
                        (s) => s.name == finalConfig.name,
                      )) {
                        await mcpc.addService(finalConfig);
                      }
                      _loadServices();
                    },
                  );
                },
              );
            },
            icon: Icon(
              CupertinoIcons.add,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          IconButton(
            key: _marketplaceButtonKey,
            tooltip: AppLocalizations.of(context)!.marketplace,
            onPressed: () => _showMarketplaceDialog(),
            icon: Icon(
              CupertinoIcons.bag,
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
          tooltip: AppLocalizations.of(context)!.addCustomConnector,
          onPressed: () {
            showCustomAddMcpDialog(
              context,
              onConfigReady: (config) {
                showCustomAddProgressDialog(
                  context,
                  config,
                  onSuccess: (finalConfig, toolCount) async {
                    final mcpc = Get.find<McpController>();
                    await mcpc.ensureLoaded();
                    if (!mcpc.configs.any(
                      (s) => s.name == finalConfig.name,
                    )) {
                      await mcpc.addService(finalConfig);
                    }
                    _loadServices();
                  },
                );
              },
            );
          },
          icon: Icon(
            CupertinoIcons.add,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -5),
        child: IconButton(
          visualDensity: VisualDensity.compact,
          key: _marketplaceButtonKey,
          tooltip: AppLocalizations.of(context)!.marketplace,
          onPressed: () => _showMarketplaceDialog(),
          icon: Icon(
            CupertinoIcons.bag,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    ];
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
              AppLocalizations.of(context)!.noMcpServices,
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
              AppLocalizations.of(context)!.clickToEnterMarketplace,
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
          GridView.builder(
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
              return _McpServiceCard(
                service: service,
                isRefreshing: _refreshingServices.contains(service.name),
                onTap: () => _showAddedServiceDetail(service),
                onRefresh: () => _refreshService(service),
                onDelete: () => _confirmRemoveService(service),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(Mcp service) => getTypeLabel(service);

  final Set<String> _refreshingServices = {};

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
        SnackBarUtils.showSuccess(
          context,
          AppLocalizations.of(context)!.toolsFetched(tools.length),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.fetchToolsFailed(
            e.toString().length > 80
                ? '${e.toString().substring(0, 80)}...'
                : e.toString(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingServices.remove(service.name));
      }
    }
  }

  Future<void> _confirmRemoveService(Mcp service) async {
    final shouldRemove = await ConfirmDeleteDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.removeServiceLabel,
      itemName: service.name,
      description: AppLocalizations.of(context)!.removeServiceConfirm,
      warningMessage: AppLocalizations.of(context)!.removeServiceWarning,
      icon: CupertinoIcons.delete,
      iconColor: Theme.of(context).colorScheme.error,
      confirmText: AppLocalizations.of(context)!.remove,
    );

    if (shouldRemove == true) {
      await _removeService(service.mcpId, service.name);
    }
  }

  void _showAddedServiceDetail(Mcp service) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.mcpDetail,
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
                                  AppLocalizations.of(
                                    context,
                                  )!.toolList(tools.length),
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
                                        AppLocalizations.of(
                                          context,
                                        )!.toolsRefreshed(newTools.length),
                                      );
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        SnackBarUtils.showError(
                                          ctx,
                                          AppLocalizations.of(
                                            context,
                                          )!.refreshFailed(
                                            e.toString().substring(
                                              0,
                                              e.toString().length.clamp(0, 80),
                                            ),
                                          ),
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
                                        AppLocalizations.of(
                                          context,
                                        )!.refreshAction,
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
                                            ? AppLocalizations.of(
                                              context,
                                            )!.toolNameDesc(
                                              t.name,
                                              t.description,
                                            )
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
                                  AppLocalizations.of(
                                    context,
                                  )!.moreXTools(tools.length - 50),
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
                                label: Text(
                                  AppLocalizations.of(context)!.fetchTools,
                                ),
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
                            AppLocalizations.of(context)!.jsonConfig,
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
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.removeServiceLabel,
                              ),
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

  String _buildSubtitle(Mcp service) => buildSubtitle(service);

  String _buildConfigJson(Mcp service) {
    final map = service.toJson();
    map['name'] = service.name;
    if (service.workingDirectory != null) {
      map['workingDirectory'] = service.workingDirectory;
    }
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  void _showMarketplaceDialog() {
    final RenderBox? button =
        _marketplaceButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(
        buttonPosition.dx - 60,
        buttonPosition.dy + kToolbarHeight,
        140,
        0,
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      items: [
        // PopupMenuItem(
        //   height: 48,
        //   onTap: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (_) => const McpMarketplacePage()),
        //     ).then((_) => _loadServices());
        //   },
        //   child: Row(
        //     children: [
        //       const Text('内置市场', style: TextStyle(fontSize: 12)),
        //     ],
        //   ),
        // ),
        PopupMenuItem(
          height: 48,
          onTap: () {
            launchUrl(Uri.parse('https://bailian.console.aliyun.com/'));
          },
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.aliyun,
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          height: 48,
          onTap: () {
            launchUrl(Uri.parse('https://console.cloud.tencent.com/mcp'));
          },
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.tencentCloud,
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          height: 48,
          onTap: () {
            launchUrl(Uri.parse('https://modelscope.cn/mcp'));
          },
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.modelscope,
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _McpServiceCard extends StatefulWidget {
  final Mcp service;
  final bool isRefreshing;
  final VoidCallback onTap;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _McpServiceCard({
    required this.service,
    required this.isRefreshing,
    required this.onTap,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  State<_McpServiceCard> createState() => _McpServiceCardState();
}

class _McpServiceCardState extends State<_McpServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final description = service.description;
    final subtitle = buildSubtitle(service);

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
            color:
                _isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                    : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _isHovered
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
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            getTypeLabel(service),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.65),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
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
                    onTap: widget.isRefreshing ? null : widget.onRefresh,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child:
                          widget.isRefreshing
                              ? const Padding(
                                padding: EdgeInsets.all(5),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  strokeCap: StrokeCap.round,
                                ),
                              )
                              : Icon(
                                CupertinoIcons.refresh,
                                size: 10,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.delete,
                        size: 10,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
