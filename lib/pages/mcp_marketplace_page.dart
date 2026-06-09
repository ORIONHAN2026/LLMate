import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/session_controller.dart';
import '../controllers/mcp_controller.dart';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/mcp_config.dart';
import '../services/mcp_service.dart';
import '../controllers/model_controller.dart';
import '../storage/isar_service.dart';
import '../utils/snackbar_utils.dart';

// ────────────────────────────────────────────
// 数据模型
// ────────────────────────────────────────────

/// MCP 市场条目（从 JSON 解析）
class _MarketItem {
  final String name;
  final String description;
  /// MCP 配置 JSON 字符串，支持 ${API_KEY} 占位符
  final String content;
  final String category;
  final IconData icon;
  final Color color;
  final String vendorId;

  const _MarketItem({
    required this.name,
    required this.description,
    required this.content,
    required this.category,
    required this.icon,
    required this.color,
    required this.vendorId,
  });
}

/// 供应商信息（从 JSON 解析）
class _VendorInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool requiresAuth;
  final String authHint;
  final String authKeyName;
  final String authTarget;
  String? apiKey;

  _VendorInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiresAuth,
    this.authHint = 'API Key',
    this.authKeyName = 'Authorization',
    this.authTarget = 'header',
  });

  Future<void> loadApiKey() async {
    if (!requiresAuth) return;
    apiKey = await IsarService.getVendorKey(id);
  }

  Future<void> saveApiKey(String key) async {
    apiKey = key;
    await IsarService.saveVendorKey(id, key);
  }

  Future<void> clearApiKey() async {
    apiKey = null;
    await IsarService.deleteVendorKey(id);
  }
}

// ────────────────────────────────────────────
// 图标 & 颜色映射
// ────────────────────────────────────────────

/// 字符串 → CupertinoIcons 映射表
IconData _parseIcon(String name) {
  const map = <String, IconData>{
    'folder_fill': CupertinoIcons.folder_fill,
    'square_stack_3d_down_right_fill': CupertinoIcons.square_stack_3d_down_right_fill,
    'layers_alt_fill': CupertinoIcons.layers_alt_fill,
    'cube_box_fill': CupertinoIcons.cube_box_fill,
    'globe': CupertinoIcons.globe,
    'search_circle_fill': CupertinoIcons.search_circle_fill,
    'arrow_up_arrow_down_circle_fill': CupertinoIcons.arrow_up_arrow_down_circle_fill,
    'command': CupertinoIcons.command,
    'compass_fill': CupertinoIcons.compass_fill,
    'square_fill_on_square_fill': CupertinoIcons.square_fill_on_square_fill,
    'memories': CupertinoIcons.memories,
    'desktopcomputer': CupertinoIcons.desktopcomputer,
    'cloud_fill': CupertinoIcons.cloud_fill,
    'cube_fill': CupertinoIcons.cube_fill,
    'text_bubble_fill': CupertinoIcons.text_bubble_fill,
    'eye_fill': CupertinoIcons.eye_fill,
    'waveform': CupertinoIcons.waveform,
    'sparkles': CupertinoIcons.sparkles,
    'person_2_alt': CupertinoIcons.person_2_alt,
    'chart_bar_fill': CupertinoIcons.chart_bar_fill,
    'link': CupertinoIcons.link,
    'checkmark_alt': CupertinoIcons.checkmark_alt,
    'plus': CupertinoIcons.plus,
    'back': CupertinoIcons.back,
    'add_circled': CupertinoIcons.add_circled,
    'search': CupertinoIcons.search,
    'clear': CupertinoIcons.clear,
    'eye': CupertinoIcons.eye,
    'eye_slash': CupertinoIcons.eye_slash,
    'checkmark_seal_fill': CupertinoIcons.checkmark_seal_fill,
    'exclamationmark_triangle_fill': CupertinoIcons.exclamationmark_triangle_fill,
    'chevron_right': CupertinoIcons.chevron_right,
    'cube_box': CupertinoIcons.cube_box,
    'exclamationmark_circle': CupertinoIcons.exclamationmark_circle,
  };
  return map[name] ?? CupertinoIcons.cube_box;
}

/// 十六进制颜色字符串 → Color
Color _parseColor(String hex) {
  final s = hex.replaceFirst('#', '');
  if (s.length == 6) {
    return Color(int.parse('FF$s', radix: 16));
  } else if (s.length == 8) {
    return Color(int.parse(s, radix: 16));
  }
  return const Color(0xFF607D8B);
}

/// 分类 → (icon, color) 映射（JSON 未指定 icon/color 时使用）
const Map<String, _IconColor> _categoryStyle = {
  '文件系统': _IconColor(CupertinoIcons.folder_fill, Color(0xFFFF9800)),
  '数据库': _IconColor(CupertinoIcons.square_stack_3d_down_right_fill, Color(0xFF4CAF50)),
  '网络工具': _IconColor(CupertinoIcons.globe, Color(0xFF2196F3)),
  '开发工具': _IconColor(CupertinoIcons.command, Color(0xFF9C27B0)),
  'AI助手': _IconColor(CupertinoIcons.person_2_alt, Color(0xFF6C4AB6)),
  '搜索工具': _IconColor(CupertinoIcons.search_circle_fill, Color(0xFF2196F3)),
  '内容生成': _IconColor(CupertinoIcons.sparkles, Color(0xFFE91E63)),
  '语音服务': _IconColor(CupertinoIcons.waveform, Color(0xFF00BCD4)),
  '生活服务': _IconColor(CupertinoIcons.globe, Color(0xFF4CAF50)),
  '企业服务': _IconColor(CupertinoIcons.chart_bar_fill, Color(0xFFFF9800)),
  '其他': _IconColor(CupertinoIcons.cube_box, Color(0xFF607D8B)),
};

class _IconColor {
  final IconData icon;
  final Color color;
  const _IconColor(this.icon, this.color);
}

// ────────────────────────────────────────────
// JSON 加载
// ────────────────────────────────────────────

/// 供应商 JSON 文件名列表（加载顺序决定 Tab 顺序）
const _vendorFiles = [
  'assets/mcp_marketplace/local.json',
  'assets/mcp_marketplace/aliyun.json',
  'assets/mcp_marketplace/modelscope.json',
  'assets/mcp_marketplace/tencent.json',
];

Future<_VendorInfo> _parseVendor(Map<String, dynamic> json) async {
  return _VendorInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    icon: _parseIcon(json['icon'] as String? ?? 'cube_box'),
    color: _parseColor(json['color'] as String? ?? '#607D8B'),
    requiresAuth: json['requiresAuth'] as bool? ?? false,
    authHint: json['authHint'] as String? ?? 'API Key',
    authKeyName: json['authKeyName'] as String? ?? 'Authorization',
    authTarget: json['authTarget'] as String? ?? 'header',
  );
}

List<_MarketItem> _parseItems(List<dynamic> items, String vendorId) {
  return items.map((item) {
    final m = item as Map<String, dynamic>;
    final category = m['category'] as String? ?? '其他';
    final style = _categoryStyle[category] ?? _categoryStyle['其他']!;
    return _MarketItem(
      name: m['name'] as String,
      description: m['description'] as String? ?? '',
      content: m['content'] as String,
      category: category,
      icon: m.containsKey('icon') ? _parseIcon(m['icon'] as String) : style.icon,
      color: m.containsKey('color') ? _parseColor(m['color'] as String) : style.color,
      vendorId: vendorId,
    );
  }).toList();
}

/// 从 assets 加载所有供应商数据
Future<List<Map<String, dynamic>>> _loadAllVendorData() async {
  final results = <Map<String, dynamic>>[];
  for (final path in _vendorFiles) {
    try {
      final content = await rootBundle.loadString(path);
      final json = jsonDecode(content) as Map<String, dynamic>;
      results.add(json);
    } catch (_) {
      // 文件不存在则跳过
    }
  }
  return results;
}

// ────────────────────────────────────────────
// 页面组件
// ────────────────────────────────────────────

// ── 自定义添加 MCP 服务（顶层函数，支持跨页面调用） ──

/// 显示自定义添加 MCP 弹窗
void showCustomAddMcpDialog(
  BuildContext context, {
  required void Function(Mcp config) onConfigReady,
}) {
  final jsonCtrl = TextEditingController();
  String? parseError;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, setDialogState) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
                elevation: 8,
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      Text(
                        '添加 MCP 服务',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // JSON 编辑器
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: jsonCtrl,
                          maxLines: 8,
                          minLines: 5,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: Theme.of(ctx).colorScheme.onSurface,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '请粘贴 MCP 代码',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.multiline,
                          onChanged: (_) {
                            if (parseError != null) {
                              setDialogState(() => parseError = null);
                            }
                          },
                        ),
                      ),
                      if (parseError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
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
                                  parseError!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.error,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // 操作按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              '取消',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final jsonText = jsonCtrl.text.trim();
                              try {
                                jsonDecode(jsonText);
                              } on FormatException catch (e) {
                                setDialogState(() {
                                  parseError = 'JSON 格式错误: ${e.message}';
                                });
                                return;
                              }

                              final config = _McpMarketplacePageState._parseMcpFromJson(jsonText);
                              if (config == null) {
                                setDialogState(() {
                                  parseError = _McpMarketplacePageState._unsupportedTransportHint;
                                });
                                return;
                              }

                              Navigator.pop(ctx);
                              onConfigReady(config);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('连接并添加'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ),
  );
}

/// 显示自定义添加进度弹窗
void showCustomAddProgressDialog(
  BuildContext context,
  Mcp config, {
  required void Function(Mcp finalConfig, int toolCount) onSuccess,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CustomAddProgressDialog(
      config: config,
      onSuccess: onSuccess,
    ),
  );
}

class McpMarketplacePage extends StatefulWidget {
  const McpMarketplacePage({super.key});

  @override
  State<McpMarketplacePage> createState() => _McpMarketplacePageState();
}

class _McpMarketplacePageState extends State<McpMarketplacePage> {
  final sessionController = Get.find<SessionController>();
  final modelController = Get.find<ModelController>();
  final _searchController = TextEditingController();

  // 数据
  List<_VendorInfo> _vendors = [];
  List<_MarketItem> _allItems = [];
  bool _loading = true;

  // 选中状态
  _VendorInfo? _selectedVendor;
  String _selectedCategory = '全部';

  // 筛选结果
  List<_MarketItem> _filteredItems = [];

  ChatModel? get _currentModel =>
      sessionController.currentSession.value?.chatModel;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    // 提前加载全局 MCP 配置，用于判断已添加状态
    final mcpc = Get.find<McpController>();
    await mcpc.ensureLoaded();

    // 加载 JSON 数据
    final allData = await _loadAllVendorData();
    final vendors = <_VendorInfo>[];
    final items = <_MarketItem>[];

    for (final data in allData) {
      final vendorJson = data['vendor'] as Map<String, dynamic>;
      final vendor = await _parseVendor(vendorJson);
      await vendor.loadApiKey();
      vendors.add(vendor);

      final itemList = data['items'] as List<dynamic>? ?? [];
      items.addAll(_parseItems(itemList, vendor.id));
    }

    if (mounted) {
      setState(() {
        _vendors = vendors;
        _allItems = items;
        _selectedVendor = vendors.isNotEmpty ? vendors.first : null;
        _loading = false;
        _filter();
      });
    }
  }

  void _filter() {
    final vendorId = _selectedVendor?.id;
    setState(() {
      _filteredItems =
          _allItems.where((item) {
            if (vendorId != null && item.vendorId != vendorId) return false;
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

  void _selectVendor(_VendorInfo vendor) {
    setState(() {
      _selectedVendor = vendor;
      _selectedCategory = '全部';
    });
    _filter();
  }

  List<String> get _vendorCategories {
    final vendorId = _selectedVendor?.id;
    if (vendorId == null) return ['全部'];
    final cats =
        _allItems
            .where((i) => i.vendorId == vendorId)
            .map((i) => i.category)
            .toSet()
            .toList()
          ..sort();
    return ['全部', ...cats];
  }

  List<String> get _addedNames {
    final modelNames = _currentModel?.mcpServices?.map((s) => s.name).toList() ?? [];
    final globalNames = Get.find<McpController>().configs.map((s) => s.name).toList();
    return {...modelNames, ...globalNames}.toList();
  }

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

  /// 根据 item 构建 Mcp 配置，从 content 解析并替换 ${API_KEY}
  Mcp _buildMcpConfig(_MarketItem item) {
    final vendor = _vendors.firstWhere(
      (v) => v.id == item.vendorId,
      orElse: () => _vendors.first,
    );
    final apiKey = vendor.apiKey;

    String contentStr = item.content;
    if (apiKey != null && apiKey.isNotEmpty) {
      contentStr = contentStr.replaceAll(r'${API_KEY}', apiKey);
    }
    var parsed = jsonDecode(contentStr) as Map<String, dynamic>;

    // 如果 content 包含 mcpServers 包装，解包到顶层
    if (parsed.containsKey('mcpServers')) {
      parsed = parsed['mcpServers'] as Map<String, dynamic>;
    }

    final hasUrl = parsed['url'] is String && (parsed['url'] as String).isNotEmpty;

    return Mcp(
      mcpId: 'mcp_${DateTime.now().millisecondsSinceEpoch}',
      name: item.name,
      description: item.description,
      command: parsed['command'] as String?,
      args: (parsed['args'] as List<dynamic>?)?.cast<String>(),
      url: parsed['url'] as String?,
      headers: parsed['headers'] != null
          ? Map<String, String>.from(parsed['headers'] as Map)
          : null,
      env: parsed['env'] != null
          ? Map<String, String>.from(parsed['env'] as Map)
          : null,
      type: hasUrl
          ? McpTransportTypeExt.fromString(parsed['type'] as String? ?? 'http')
          : null,
    );
  }

  /// 从应用市场添加 MCP 服务（带进度弹窗）
  Future<void> _addMarketplaceService(_MarketItem item) async {
    final vendorName = _vendors
        .firstWhere((v) => v.id == item.vendorId, orElse: () => _vendors.first)
        .name;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MarketplaceAddDialog(
        item: item,
        vendorName: vendorName,
        buildConfig: (item) => _buildMcpConfig(item),
        onSuccess: (config, toolCount) {
          _onAddSuccess(config, toolCount);
        },
      ),
    );
  }

  /// 添加成功后持久化保存并刷新 UI
  Future<void> _onAddSuccess(Mcp config, int toolCount) async {
    final mcpc = Get.find<McpController>();
    await mcpc.ensureLoaded();
    if (!mcpc.configs.any((s) => s.name == config.name)) {
      await mcpc.addService(config);
    }

    final model = _currentModel;
    if (model != null) {
      await _saveModel(model.addMcpService(config));
    }

    if (mounted) {
      setState(() {});
      SnackBarUtils.showSuccess(context, '已添加: ${config.name} ($toolCount 个工具)');
    }
  }

  Future<void> _removeService(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除 MCP 服务'),
        content: Text('确定要移除 "$name" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 从全局移除
    final mcpc = Get.find<McpController>();
    final global = mcpc.configs.firstWhereOrNull((s) => s.name == name);
    if (global != null) {
      await mcpc.removeService(global.mcpId);
    }

    // 从当前模型移除
    final model = _currentModel;
    if (model != null) {
      await _saveModel(model.removeMcpService(name));
    }

    if (mounted) {
      setState(() {});
      SnackBarUtils.showInfo(context, '已移除: $name');
    }
  }

  // ── 供应商密钥配置弹窗 ──

  void _showVendorKeyDialog(_VendorInfo vendor) {
    final keyCtrl = TextEditingController(text: vendor.apiKey ?? '');
    bool obscure = true;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDlg) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(vendor.icon, size: 20, color: vendor.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${vendor.name} 密钥',
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '配置后，该供应商下所有 MCP 服务将自动使用此密钥。\n密钥以 "Bearer {key}" 格式注入到 Authorization 请求头。',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          vendor.authHint,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: keyCtrl,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            hintText: '请输入 ${vendor.authHint}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                                size: 20,
                              ),
                              onPressed: () => setDlg(() => obscure = !obscure),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    if (vendor.apiKey != null && vendor.apiKey!.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          await vendor.clearApiKey();
                          if (mounted) setState(() {});
                          Navigator.pop(ctx);
                          SnackBarUtils.showInfo(context, '已清除 ${vendor.name} 密钥');
                        },
                        child: const Text('清除密钥', style: TextStyle(color: Colors.red)),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final val = keyCtrl.text.trim();
                        if (val.isNotEmpty) {
                          await vendor.saveApiKey(val);
                          if (mounted) setState(() {});
                          Navigator.pop(ctx);
                          SnackBarUtils.showSuccess(context, '${vendor.name} 密钥已保存');
                        } else {
                          await vendor.clearApiKey();
                          if (mounted) setState(() {});
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ),
    );
  }

  // ── 构建 ──

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
          TextButton(
            onPressed: _showAddMcpDialog,
            child: const Text('添加自定义连接器', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : modelController.models.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.cube_box, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '请先添加一个大模型',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // 搜索框
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _filter(),
                      decoration: InputDecoration(
                        hintText: '搜索 MCP 服务...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        prefixIcon: Icon(CupertinoIcons.search, size: 18, color: Colors.grey[400]),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(CupertinoIcons.clear, size: 18, color: Colors.grey[400]),
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
                          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 一级：供应商标签
                  _buildVendorTabs(),

                  const SizedBox(height: 4),

                  // 供应商密钥状态栏
                  if (_selectedVendor != null) _buildVendorKeyBar(_selectedVendor!),

                  // 二级：分类标签
                  if (_vendorCategories.length > 1) ...[
                    const SizedBox(height: 4),
                    _buildCategoryChips(),
                  ],

                  const SizedBox(height: 10),

                  // 服务列表（2列网格）
                  Expanded(
                    child:
                        _filteredItems.isEmpty
                            ? Center(
                              child: Text(
                                '没有找到相关服务',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 6.0,
                                  ),
                              itemCount: _filteredItems.length,
                              itemBuilder: (_, i) => _buildItemCard(_filteredItems[i]),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildVendorTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _vendors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = _vendors[i];
          final sel = _selectedVendor?.id == v.id;
          return FilterChip(
            avatar: Icon(v.icon, size: 16, color: sel ? Colors.white : v.color),
            label: Text(
              v.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                color: sel ? Colors.white : Colors.grey[700],
              ),
            ),
            selected: sel,
            onSelected: (_) => _selectVendor(v),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            selectedColor: v.color,
            checkmarkColor: Colors.transparent,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildVendorKeyBar(_VendorInfo vendor) {
    if (!vendor.requiresAuth) return const SizedBox.shrink();

    final hasKey = vendor.apiKey != null && vendor.apiKey!.isNotEmpty;
    return GestureDetector(
      onTap: () => _showVendorKeyDialog(vendor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasKey ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasKey ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasKey
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.exclamationmark_triangle_fill,
              size: 14,
              color: hasKey ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasKey ? '${vendor.authHint} 已配置' : '点击配置 ${vendor.authHint}',
                style: TextStyle(
                  fontSize: 11,
                  color: hasKey ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _vendorCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _vendorCategories[i];
          final sel = c == _selectedCategory;
          return FilterChip(
            label: Text(
              c,
              style: TextStyle(
                fontSize: 12,
                color: sel ? Colors.white : Colors.grey[600],
              ),
            ),
            selected: sel,
            onSelected: (_) {
              _selectedCategory = c;
              _filter();
            },
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            selectedColor: Theme.of(context).colorScheme.primary,
            checkmarkColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact,
          );
        },
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
            GestureDetector(
              onTap: () {
                if (isAdded) {
                  _removeService(item.name);
                } else {
                  _addMarketplaceService(item);
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
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                  ),
                  color:
                      isAdded
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : null,
                ),
                child: Icon(
                  isAdded ? CupertinoIcons.checkmark_alt : CupertinoIcons.plus,
                  size: 13,
                  color:
                      isAdded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 自定义添加 MCP 服务 ──

  /// 从用户输入的 JSON 文本解析并构建 Mcp 配置。
  /// 返回 null 表示解析失败，需要就地显示错误提示。
  static Mcp? _parseMcpFromJson(String jsonText) {
    try {
      final json = jsonDecode(jsonText) as Map<String, dynamic>;

      Map<String, dynamic> serviceJson = json;
      final mcpServers = json['mcpServers'] as Map<String, dynamic>?;
      if (mcpServers != null && mcpServers.isNotEmpty) {
        // 兼容两种格式：
        // 1. 直接配置: {"mcpServers": {"type":"http", "url":"...", ...}}
        // 2. 命名配置: {"mcpServers": {"server-name": {"type":"http", ...}}}
        if (mcpServers.containsKey('url') ||
            mcpServers.containsKey('type') ||
            mcpServers.containsKey('command')) {
          serviceJson = mcpServers;
        } else {
          serviceJson = mcpServers.entries.first.value as Map<String, dynamic>;
        }
      }

      final hasUrl =
          serviceJson['url'] is String && (serviceJson['url'] as String).isNotEmpty;
      if (hasUrl) {
        final typeVal = serviceJson['type'] as String?;
        if (typeVal == null || typeVal.isEmpty) {
          serviceJson['type'] = 'http';
        } else if (typeVal != 'sse' &&
            typeVal != 'http' &&
            typeVal != 'streamableHttp') {
          return null; // 不支持的传输类型，由调用方处理
        }
      }

      return Mcp(
        mcpId: 'mcp_${DateTime.now().millisecondsSinceEpoch}',
        name: 'mcp_${DateTime.now().millisecondsSinceEpoch}',
        command: serviceJson['command'] as String?,
        args: (serviceJson['args'] as List<dynamic>?)?.cast<String>(),
        url: serviceJson['url'] as String?,
        headers: serviceJson['headers'] != null
            ? Map<String, String>.from(serviceJson['headers'])
            : null,
        env: serviceJson['env'] != null
            ? Map<String, String>.from(serviceJson['env'])
            : null,
        workingDirectory: serviceJson['workingDirectory'] as String?,
        type: hasUrl
            ? McpTransportTypeExt.fromString(serviceJson['type'] as String?)
            : null,
      );
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 解析失败时的不支持传输类型提示
  static const _unsupportedTransportHint = '不支持的传输类型，仅支持 sse / http / streamableHttp';

  void _showAddMcpDialog() {
    showCustomAddMcpDialog(
      context,
      onConfigReady: (config) {
        _showCustomAddProgressDialog(config);
      },
    );
  }

  void _showCustomAddProgressDialog(Mcp config) {
    showCustomAddProgressDialog(
      context,
      config,
      onSuccess: (finalConfig, toolCount) {
        _addServiceWithInfo(finalConfig, toolCount: toolCount);
      },
    );
  }

  Future<void> _addServiceWithInfo(Mcp config, {required int toolCount}) async {
    final mcpc = Get.find<McpController>();
    await mcpc.ensureLoaded();
    if (mcpc.configs.any((s) => s.name == config.name)) {
      SnackBarUtils.showInfo(context, '服务 "${config.name}" 已存在');
      return;
    }
    await mcpc.addService(config);
    final model = _currentModel;
    if (model != null) {
      await _saveModel(model.addMcpService(config));
    }
    if (mounted) {
      setState(() {});
      SnackBarUtils.showSuccess(context, '已添加: ${config.name} (${toolCount} 个工具)');
    }
  }
}

// ── 应用市场添加进度弹窗 ──

class _MarketplaceAddDialog extends StatefulWidget {
  final _MarketItem item;
  final String vendorName;
  final Mcp Function(_MarketItem) buildConfig;
  final void Function(Mcp config, int toolCount) onSuccess;

  const _MarketplaceAddDialog({
    required this.item,
    required this.vendorName,
    required this.buildConfig,
    required this.onSuccess,
  });

  @override
  State<_MarketplaceAddDialog> createState() => _MarketplaceAddDialogState();
}

class _MarketplaceAddDialogState extends State<_MarketplaceAddDialog> {
  String _statusText = '正在准备...';
  String _detailText = '';
  String _errorMessage = '';
  bool _isError = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _startAdd();
  }

  Future<void> _startAdd() async {
    try {
      // 步骤1: 构建配置
      _updateStatus('正在构建 MCP 配置...', widget.item.name);
      final config = widget.buildConfig(widget.item);

      // 步骤2: 发送初始化请求
      _updateStatus('正在连接 MCP 服务...', widget.item.name);

      McpConnectionInfo info;
      try {
        info = await McpService.connectAndGetInfo(
          config,
          preDefinedName: widget.item.name,
          preDefinedDescription: widget.item.description,
        );
      } on TimeoutException catch (e) {
        final isAliyun = widget.item.vendorId == 'aliyun';
        setState(() {
          _isError = true;
          _statusText = '连接超时';
          _errorMessage = (e.message ?? '请检查网络连接和 API 密钥配置') +
              (isAliyun ? '\n\n请确认已经在阿里云百炼上开通此服务' : '');
          _detailText = '';
        });
        return;
      } catch (connectError) {
        // MCP 连接错误：显示详细错误信息供排查
        final msg = connectError.toString();
        final detail = msg.length > 500 ? '${msg.substring(0, 500)}...' : msg;
        setState(() {
          _isError = true;
          _statusText = '连接失败';
          _errorMessage = detail;
          _detailText = '服务: ${widget.item.name}\n端点: ${config.url ?? config.command ?? "未知"}';
        });
        return;
      }

      // 步骤3: 工具列表
      _updateStatus(
        '获取到 ${info.tools.length} 个工具，正在保存...',
        info.tools.isEmpty
            ? '该服务未返回可用工具'
            : info.tools.map((t) => '  • ${t.name}').join('\n'),
      );

      final finalConfig = config.copyWith(
        name: info.serverName,
        description: info.description,
        tools: info.tools,
        lastUpdated: DateTime.now(),
      );

      // 步骤4: 持久化
      _updateStatus('正在保存...', '');
      try {
        widget.onSuccess(finalConfig, info.tools.length);
      } catch (saveError) {
        setState(() {
          _isError = true;
          _statusText = '保存失败';
          _errorMessage = saveError.toString();
          _detailText = '工具已获取成功，但保存到本地数据库时出错';
        });
        return;
      }

      setState(() {
        _statusText = '添加成功';
        _detailText = '${info.serverName}\n${info.tools.length} 个工具';
        _isDone = true;
      });
    } on TimeoutException catch (e) {
      final isAliyun = widget.item.vendorId == 'aliyun';
      setState(() {
        _isError = true;
        _statusText = '连接超时';
        _errorMessage = (e.message ?? '请检查网络连接和 API 密钥配置') +
            (isAliyun ? '\n\n请确认已经在阿里云百炼上开通此服务' : '');
        _detailText = '';
      });
    } catch (e) {
      // 捕获所有其他异常
      final msg = e.toString();
      setState(() {
        _isError = true;
        _statusText = '错误';
        _errorMessage = msg.length > 500 ? '${msg.substring(0, 500)}...' : msg;
        _detailText = '';
      });
    }
  }

  void _updateStatus(String status, String detail) {
    if (mounted) {
      setState(() {
        _statusText = status;
        _detailText = detail;
        _isError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isError
                ? CupertinoIcons.exclamationmark_circle
                : _isDone
                    ? CupertinoIcons.checkmark_alt_circle
                    : CupertinoIcons.arrow_down_circle,
            color: _isError
                ? Colors.redAccent
                : _isDone
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            _isError ? '添加失败' : _isDone ? '完成' : '添加 MCP 服务',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '供应商: ${widget.vendorName}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!_isDone && !_isError)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isError ? Colors.redAccent : null,
                    ),
                  ),
                ),
              ],
            ),
            if (_detailText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isDone
                      ? Colors.green.withOpacity(0.06)
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _detailText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    height: 1.4,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_isError) ...[
          if (widget.item.vendorId == 'aliyun')
            TextButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://bailian.console.aliyun.com/#/mcp-market');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(CupertinoIcons.globe, size: 16),
              label: const Text('去阿里云开通'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isError = false;
                _errorMessage = '';
                _detailText = '';
              });
              _startAdd();
            },
            child: const Text('重试'),
          ),
        ] else if (!_isDone) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
        ],
      ],
    );
  }
}

// ── 自定义添加进度弹窗 ──

class _CustomAddProgressDialog extends StatefulWidget {
  final Mcp config;
  final void Function(Mcp config, int toolCount) onSuccess;

  const _CustomAddProgressDialog({
    required this.config,
    required this.onSuccess,
  });

  @override
  State<_CustomAddProgressDialog> createState() => _CustomAddProgressDialogState();
}

class _CustomAddProgressDialogState extends State<_CustomAddProgressDialog> {
  String _statusText = '正在准备...';
  String _detailText = '';
  String _errorMessage = '';
  bool _isError = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _startAdd();
  }

  Future<void> _startAdd() async {
    try {
      // 步骤1: 连接 MCP 服务
      _updateStatus('正在连接 MCP 服务...', '');
      final info = await McpService.connectAndGetInfo(widget.config);

      // 步骤2: 获取工具
      _updateStatus(
        '获取到 ${info.tools.length} 个工具，正在保存...',
        info.tools.isEmpty
            ? '该服务未返回可用工具'
            : info.tools.map((t) => '  • ${t.name}').join('\n'),
      );

      final finalConfig = widget.config.copyWith(
        name: info.serverName,
        description: info.description,
        tools: info.tools,
        lastUpdated: DateTime.now(),
      );

      // 步骤3: 持久化
      _updateStatus('正在保存...', '');
      try {
        widget.onSuccess(finalConfig, info.tools.length);
      } catch (saveError) {
        setState(() {
          _isError = true;
          _statusText = '保存失败';
          _errorMessage = saveError.toString();
          _detailText = '工具已获取成功，但保存到本地数据库时出错';
        });
        return;
      }

      setState(() {
        _statusText = '添加成功';
        _detailText = '${info.serverName}\n${info.tools.length} 个工具';
        _isDone = true;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _isError = true;
        _statusText = '连接超时';
        _errorMessage = (e.message ?? '请检查网络连接和 API 密钥配置');
        _detailText = '';
      });
    } catch (e) {
      final msg = e.toString();
      setState(() {
        _isError = true;
        _statusText = '错误';
        _errorMessage = msg.length > 500 ? '${msg.substring(0, 500)}...' : msg;
        _detailText = '';
      });
    }
  }

  void _updateStatus(String status, String detail) {
    if (mounted) {
      setState(() {
        _statusText = status;
        _detailText = detail;
        _isError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isError
                ? CupertinoIcons.exclamationmark_circle
                : _isDone
                    ? CupertinoIcons.checkmark_alt_circle
                    : CupertinoIcons.cube_box,
            color: _isError
                ? Colors.redAccent
                : _isDone
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            _isError ? '添加失败' : _isDone ? '完成' : '添加 MCP 服务',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!_isDone && !_isError)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isError ? Colors.redAccent : null,
                    ),
                  ),
                ),
              ],
            ),
            if (_detailText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isDone
                      ? Colors.green.withOpacity(0.06)
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _detailText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    height: 1.4,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_isError) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isError = false;
                _errorMessage = '';
                _detailText = '';
              });
              _startAdd();
            },
            child: const Text('重试'),
          ),
        ] else if (!_isDone) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
        ],
      ],
    );
  }
}