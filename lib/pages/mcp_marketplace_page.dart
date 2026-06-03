import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/session_controller.dart';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/mcp_config.dart';
import '../services/mcp_service.dart';
import '../services/model_storage_service.dart';
import '../utils/snackbar_utils.dart';

/// MCP 服务市场条目
class _MarketItem {
  final String name;
  final String description;
  final String command;
  final List<String> args;
  final String category;
  final IconData icon;
  final Color color;

  const _MarketItem({
    required this.name,
    required this.description,
    required this.command,
    required this.args,
    required this.category,
    required this.icon,
    required this.color,
  });
}

/// MCP 应用市场页面
///
/// 展示可用的 MCP 服务，支持按分类筛选和搜索，
/// 点击可查看详情并添加到当前模型。
class McpMarketplacePage extends StatefulWidget {
  const McpMarketplacePage({super.key});

  @override
  State<McpMarketplacePage> createState() => _McpMarketplacePageState();
}

class _McpMarketplacePageState extends State<McpMarketplacePage> {
  final sessionController = Get.find<SessionController>();
  final _searchController = TextEditingController();
  String _selectedCategory = '全部';
  List<_MarketItem> _filteredItems = [];

  static const List<String> _categories = [
    '全部',
    '文件系统',
    '数据库',
    '网络工具',
    '开发工具',
    'AI助手',
    '其他',
  ];

  static const List<_MarketItem> _allItems = [
    _MarketItem(
      name: 'filesystem',
      description: '文件系统访问服务，读取、写入和管理本地文件，支持目录浏览',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-filesystem', '/Users'],
      category: '文件系统',
      icon: CupertinoIcons.folder_fill,
      color: Color(0xFFFF9800),
    ),
    _MarketItem(
      name: 'sqlite',
      description: 'SQLite 数据库连接，执行查询和数据操作',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-sqlite', './database.sqlite'],
      category: '数据库',
      icon: CupertinoIcons.square_stack_3d_down_right_fill,
      color: Color(0xFF4CAF50),
    ),
    _MarketItem(
      name: 'postgres',
      description: 'PostgreSQL 连接，支持复杂 SQL 查询和数据管理',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-postgres',
        '--connection-string',
        'postgresql://localhost/db',
      ],
      category: '数据库',
      icon: CupertinoIcons.layers_alt_fill,
      color: Color(0xFF00BCD4),
    ),
    _MarketItem(
      name: 'redis',
      description: 'Redis 缓存服务，键值操作和数据管理',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-redis',
        '--uri',
        'redis://localhost:6379',
      ],
      category: '数据库',
      icon: CupertinoIcons.cube_box_fill,
      color: Color(0xFFFF5722),
    ),
    _MarketItem(
      name: 'web-search',
      description: '实时网络搜索，获取最新信息和网页摘要',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-web-search'],
      category: '网络工具',
      icon: CupertinoIcons.globe,
      color: Color(0xFF2196F3),
    ),
    _MarketItem(
      name: 'brave-search',
      description: '隐私友好的 Brave 搜索引擎集成',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-brave-search',
        '--api-key',
        'YOUR_KEY',
      ],
      category: '网络工具',
      icon: CupertinoIcons.search_circle_fill,
      color: Color(0xFF3F51B5),
    ),
    _MarketItem(
      name: 'fetch',
      description: 'HTTP 请求工具，获取网页内容和调用 API',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-fetch'],
      category: '网络工具',
      icon: CupertinoIcons.arrow_up_arrow_down_circle_fill,
      color: Color(0xFF009688),
    ),
    _MarketItem(
      name: 'github',
      description: 'GitHub 集成，管理 Issue、PR 和代码仓库',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-github',
        '--token',
        'YOUR_TOKEN',
      ],
      category: '开发工具',
      icon: CupertinoIcons.command,
      color: Color(0xFF9C27B0),
    ),
    _MarketItem(
      name: 'puppeteer',
      description: '浏览器自动化，网页操作、截图和数据抓取',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-puppeteer'],
      category: '开发工具',
      icon: CupertinoIcons.compass_fill,
      color: Color(0xFFE91E63),
    ),
    _MarketItem(
      name: 'docker',
      description: 'Docker 容器管理，镜像操作和容器控制',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-docker'],
      category: '开发工具',
      icon: CupertinoIcons.square_fill_on_square_fill,
      color: Color(0xFF0D47A1),
    ),
    _MarketItem(
      name: 'memory',
      description: '记忆存储服务，跨会话保持上下文信息',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-memory'],
      category: 'AI助手',
      icon: CupertinoIcons.memories,
      color: Color(0xFFFFC107),
    ),
  ];

  ChatModel? get _currentModel =>
      sessionController.currentSession.value?.chatModel;

  @override
  void initState() {
    super.initState();
    _filter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    setState(() {
      _filteredItems =
          _allItems.where((item) {
            final matchSearch =
                _searchController.text.isEmpty ||
                item.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                item.description.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
            final matchCategory =
                _selectedCategory == '全部' || item.category == _selectedCategory;
            return matchSearch && matchCategory;
          }).toList();
    });
  }

  List<String> get _addedNames =>
      _currentModel?.mcpServices?.map((s) => s.name).toList() ?? [];

  Future<void> _saveModel(ChatModel updatedModel) async {
    final session = sessionController.currentSession.value;
    if (session != null) {
      sessionController.updateSession(
        session.copyWith(chatModel: updatedModel),
      );
    }
    final models = await ModelStorageService.loadModels();
    final updatedModels =
        models.map((m) {
          final cm = ChatModel.fromMap(m);
          if (cm.modelId == updatedModel.modelId) return updatedModel.toMap();
          return m;
        }).toList();
    await ModelStorageService.saveModels(updatedModels);
  }

  void _showDetailSheet(_MarketItem item) {
    final isAdded = _addedNames.contains(item.name);
    final initialJson = const JsonEncoder.withIndent(
      '  ',
    ).convert({'command': item.command, 'args': item.args, 'timeout': 30});
    final jsonCtrl = TextEditingController(text: initialJson);
    int timeoutSec = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              bool isSheetConnecting = false;
              String? sheetError;

              return DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.3,
                maxChildSize: 0.85,
                expand: false,
                builder:
                    (ctx, sc) => SingleChildScrollView(
                      controller: sc,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                  enabled: !isSheetConnecting,
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
                              enabled: !isSheetConnecting,
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
                          if (isSheetConnecting) ...[
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
                          // 错误提示
                          if (sheetError != null) ...[
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
                                      sheetError!,
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
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child:
                                isAdded
                                    ? OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _removeService(item.name);
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.delete,
                                        size: 16,
                                      ),
                                      label: const Text('移除服务'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(context).colorScheme.error,
                                        side: BorderSide(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    )
                                    : FilledButton.icon(
                                      onPressed:
                                          isSheetConnecting
                                              ? null
                                              : () async {
                                                try {
                                                  final json =
                                                      jsonDecode(jsonCtrl.text)
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final effectiveTimeout =
                                                      json['timeout'] as int? ??
                                                      timeoutSec;
                                                  final config = Mcp(
                                                    mcpId:
                                                        'mcp_${DateTime.now().millisecondsSinceEpoch}',
                                                    name: item.name,
                                                    command:
                                                        json['command']
                                                            as String?,
                                                    args:
                                                        (json['args']
                                                                as List<
                                                                  dynamic
                                                                >?)
                                                            ?.cast<String>(),
                                                    timeout: effectiveTimeout,
                                                  );

                                                  setSheetState(() {
                                                    sheetError = null;
                                                    isSheetConnecting = true;
                                                  });

                                                  // 连接远程获取工具
                                                  try {
                                                    final info =
                                                        await McpService.connectAndGetInfo(
                                                          config,
                                                        );
                                                    final realConfig = config
                                                        .copyWith(
                                                          name: info.serverName,
                                                          tools: info.tools,
                                                          lastUpdated:
                                                              DateTime.now(),
                                                        );
                                                    final model = _currentModel;
                                                    if (model != null &&
                                                        ctx.mounted) {
                                                      await _saveModel(
                                                        model.addMcpService(
                                                          realConfig,
                                                        ),
                                                      );
                                                      if (mounted)
                                                        setState(() {});
                                                      Navigator.pop(ctx);
                                                      SnackBarUtils.showSuccess(
                                                        context,
                                                        '已添加: ${info.serverName} (${info.tools.length} 个工具)',
                                                      );
                                                    }
                                                  } on TimeoutException catch (
                                                    e
                                                  ) {
                                                    setSheetState(() {
                                                      isSheetConnecting = false;
                                                      sheetError =
                                                          '⏱ 连接超时\n\n${e.message}\n\n请增大超时时间后重试。';
                                                    });
                                                  } catch (_) {
                                                    // 连接失败，用预定义名称直接添加
                                                    final model = _currentModel;
                                                    if (model != null &&
                                                        ctx.mounted) {
                                                      await _saveModel(
                                                        model.addMcpService(
                                                          config,
                                                        ),
                                                      );
                                                      if (mounted)
                                                        setState(() {});
                                                      Navigator.pop(ctx);
                                                      SnackBarUtils.showInfo(
                                                        context,
                                                        '已添加: ${config.name}（工具信息获取失败，可稍后手动刷新）',
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  setSheetState(() {
                                                    isSheetConnecting = false;
                                                    sheetError =
                                                        '❌ JSON 格式错误: $e';
                                                  });
                                                }
                                              },
                                      icon: const Icon(
                                        CupertinoIcons.plus,
                                        size: 16,
                                      ),
                                      label: Text(
                                        isSheetConnecting ? '连接中...' : '连接并添加',
                                      ),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
              );
            },
          ),
    );
  }

  Future<void> _addService(Mcp config) async {
    final model = _currentModel;
    if (model == null) {
      SnackBarUtils.showInfo(context, '请先选择一个会话并绑定模型');
      return;
    }
    if (_addedNames.contains(config.name)) {
      SnackBarUtils.showInfo(context, '服务 "${config.name}" 已添加');
      return;
    }
    // 先添加到模型（使用预定义名称）
    await _saveModel(model.addMcpService(config));
    if (mounted) {
      setState(() {});
    }

    // 连接远程获取工具
    try {
      final info = await McpService.connectAndGetInfo(config);
      // 用获取到的信息更新服务
      final updatedConfig = config.copyWith(
        name: info.serverName,
        tools: info.tools,
        lastUpdated: DateTime.now(),
      );
      final newModel = _currentModel;
      if (newModel != null && mounted) {
        await _saveModel(newModel.updateMcpService(config.name, updatedConfig));
        setState(() {});
        SnackBarUtils.showSuccess(
          context,
          '已添加: ${info.serverName} (${info.tools.length} 个工具)',
        );
        return;
      }
    } catch (_) {
      // 连接失败不影响基础添加，工具可以后续手动刷新
    }

    if (mounted) {
      SnackBarUtils.showInfo(context, '已添加: ${config.name}');
    }
  }

  Future<void> _removeService(String name) async {
    final model = _currentModel;
    if (model == null) return;
    await _saveModel(model.removeMcpService(name));
    if (mounted) {
      setState(() {});
      SnackBarUtils.showInfo(context, '已移除: $name');
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
        title: const Text('MCP 应用市场'),
      ),
      body:
          _currentModel == null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.cube_box,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '请先选择会话并绑定模型',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // 搜索和分类
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => _filter(),
                          decoration: InputDecoration(
                            hintText: '搜索 MCP 服务...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: Icon(
                                        CupertinoIcons.clear,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filter();
                                      },
                                    )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final c = _categories[i];
                              final sel = c == _selectedCategory;
                              return FilterChip(
                                label: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        sel ? Colors.white : Colors.grey[600],
                                  ),
                                ),
                                selected: sel,
                                onSelected: (_) {
                                  _selectedCategory = c;
                                  _filter();
                                },
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                selectedColor:
                                    Theme.of(context).colorScheme.primary,
                                checkmarkColor: Colors.white,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 列表
                  Expanded(
                    child:
                        _filteredItems.isEmpty
                            ? Center(
                              child: Text(
                                '没有找到相关服务',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredItems.length,
                              itemBuilder:
                                  (_, i) => _buildItemCard(_filteredItems[i]),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildItemCard(_MarketItem item) {
    final isAdded = _addedNames.contains(item.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailSheet(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (isAdded) {
                    _removeService(item.name);
                  } else {
                    _addService(
                      Mcp(
                        mcpId: 'mcp_${DateTime.now().millisecondsSinceEpoch}',
                        name: item.name,
                        command: item.command,
                        args: item.args,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color:
                        isAdded
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAdded
                        ? CupertinoIcons.checkmark_alt
                        : CupertinoIcons.plus,
                    size: 14,
                    color:
                        isAdded
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
