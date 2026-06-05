import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/session_controller.dart';
import '../controllers/mcp_controller.dart';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/mcp_config.dart';
import '../services/mcp_service.dart';
import '../controllers/model_controller.dart';
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
  final modelController = Get.find<ModelController>();
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
      description:
          '文件系统访问服务，读取、写入和管理本地文件，支持目录浏览文件系统访问服务，读取、写入和管理本地文件，支持目录浏览文件系统访问服务，读取、写入和管理本地文件，支持目录浏览文件系统访问服务，读取、写入和管理本地文件，支持目录浏览文件系统访问服务，读取、写入和管理本地文件，支持目录浏览文件系统访问服务，读取、写入和管理本地文件，支持目录浏览',
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
    final models = await modelController.loadModels();
    final updatedModels =
        models.map((m) {
          final cm = ChatModel.fromMap(m);
          if (cm.modelId == updatedModel.modelId) return updatedModel.toMap();
          return m;
        }).toList();
    await modelController.saveModelsData(updatedModels);
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
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled, size: 22),
            tooltip: '自定义添加 MCP 服务',
            onPressed: _showAddMcpDialog,
          ),
          const SizedBox(width: 4),
        ],
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
                  // 列表（2列网格）
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
                            : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 6,
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            // 中间：名称 + 描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 右侧按钮
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
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isAdded
                            ? Colors.transparent
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.15),
                  ),
                  color:
                      isAdded
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1)
                          : null,
                ),
                child: Icon(
                  isAdded ? CupertinoIcons.checkmark_alt : CupertinoIcons.plus,
                  size: 13,
                  color:
                      isAdded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 自定义添加 MCP 服务 ──

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
                            '支持 command/args 或 url/headers 格式。URL 型默认使用 HTTP 传输',
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

                                  final tempName =
                                      'mcp_${DateTime.now().millisecondsSinceEpoch}';
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

                                  setDialogState(() {
                                    errorMessage = null;
                                    isConnecting = true;
                                  });

                                  final info =
                                      await McpService.connectAndGetInfo(
                                        config,
                                      );

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
    // 添加到全局 MCP 列表
    final mcpc = Get.find<McpController>();
    await mcpc.ensureLoaded();

    if (mcpc.configs.any((s) => s.name == config.name)) {
      SnackBarUtils.showInfo(context, '服务 "${config.name}" 已存在');
      return;
    }
    await mcpc.addService(config);

    // 同时添加到当前模型（如果有）
    final model = _currentModel;
    if (model != null) {
      await _saveModel(model.addMcpService(config));
    }

    if (mounted) {
      setState(() {});
      SnackBarUtils.showSuccess(
        context,
        '已添加: ${config.name} (${toolCount} 个工具)',
      );
    }
  }
}
