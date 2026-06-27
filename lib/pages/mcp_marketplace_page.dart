import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../mcp_builtins/builtin_mcp_registry.dart';
import '../services/cloudbase_service.dart';
import '../utils/snackbar_utils.dart';

/// MCP 市场页面
///
/// 显示需要远程部署的工具
class McpMarketplacePage extends StatefulWidget {
  final bool embedded;
  const McpMarketplacePage({super.key, this.embedded = false});

  @override
  State<McpMarketplacePage> createState() => _McpMarketplacePageState();
}

class _McpMarketplacePageState extends State<McpMarketplacePage> {
  final _searchController = TextEditingController();
  String _selectedCategory = '全部';
  bool _loading = true;
  List<BuiltinMcpTool> _items = [];
  CloudBaseConfig? _cloudConfig;

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
    _cloudConfig = await CloudBaseService.getConfig();
    final tools = BuiltinMcpRegistry.remoteTools;

    if (mounted) {
      setState(() {
        _items = tools;
        _loading = false;
      });
    }
  }

  List<BuiltinMcpTool> get _filteredItems {
    return _items.where((item) {
      final matchSearch =
          _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchCategory = _selectedCategory == '全部' || item.category == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  List<String> get _categories {
    final cats = _items.map((i) => i.category).toSet().toList()..sort();
    return ['全部', ...cats];
  }

  void _showCloudBaseConfigDialog() {
    final envIdCtrl = TextEditingController(text: _cloudConfig?.envId ?? '');
    final secretIdCtrl = TextEditingController(text: _cloudConfig?.secretId ?? '');
    final secretKeyCtrl = TextEditingController(text: _cloudConfig?.secretKey ?? '');
    final regionCtrl = TextEditingController(text: _cloudConfig?.region ?? 'ap-shanghai');
    bool obscureKey = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(CupertinoIcons.cloud, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('CloudBase 配置'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: envIdCtrl, decoration: InputDecoration(labelText: '环境 ID', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 12),
                TextField(controller: secretIdCtrl, decoration: InputDecoration(labelText: 'SecretId', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 12),
                TextField(
                  controller: secretKeyCtrl,
                  obscureText: obscureKey,
                  decoration: InputDecoration(
                    labelText: 'SecretKey',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: Icon(obscureKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 18),
                      onPressed: () => setDialogState(() => obscureKey = !obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: regionCtrl, decoration: InputDecoration(labelText: '区域', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
              ],
            ),
          ),
          actions: [
            if (_cloudConfig != null)
              TextButton(
                onPressed: () async {
                  await CloudBaseService.deleteConfig();
                  Navigator.pop(ctx);
                  setState(() => _cloudConfig = null);
                  SnackBarUtils.showInfo(context, '已清除配置');
                },
                child: const Text('清除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                final config = CloudBaseConfig(
                  envId: envIdCtrl.text.trim(),
                  secretId: secretIdCtrl.text.trim(),
                  secretKey: secretKeyCtrl.text.trim(),
                  region: regionCtrl.text.trim(),
                );
                await CloudBaseService.saveConfig(config);
                setState(() => _cloudConfig = config);
                Navigator.pop(ctx);
                SnackBarUtils.showSuccess(context, '配置已保存');
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deployRemoteTool(BuiltinMcpTool tool) async {
    if (_cloudConfig == null) {
      _showCloudBaseConfigDialog();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('部署 ${tool.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tool.description, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(CupertinoIcons.cloud, size: 14, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text('将部署到: ${_cloudConfig!.envId}', style: TextStyle(fontSize: 12, color: Colors.blue[700]))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认部署')),
        ],
      ),
    );

    if (confirmed != true) return;

    // TODO: 实际部署逻辑
    SnackBarUtils.showInfo(context, '部署功能开发中...');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(CupertinoIcons.back), onPressed: () => Navigator.pop(context)),
        title: const Text('MCP 市场'),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.cloud, size: 18, color: _cloudConfig != null ? Colors.green : Colors.grey),
            onPressed: _showCloudBaseConfigDialog,
            tooltip: 'CloudBase 配置',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.checkmark_seal, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无远程工具', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜索工具...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              prefixIcon: Icon(CupertinoIcons.search, size: 18, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: Icon(CupertinoIcons.clear, size: 18, color: Colors.grey[400]), onPressed: () { _searchController.clear(); setState(() {}); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        if (_categories.length > 1)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _categories[i];
                final sel = c == _selectedCategory;
                return FilterChip(
                  label: Text(c, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[600])),
                  selected: sel,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(child: Text('没有找到相关工具', style: TextStyle(fontSize: 14, color: Colors.grey[500])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredItems.length,
                  itemBuilder: (_, i) => _buildItemCard(_filteredItems[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuiltinMcpTool tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tool.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(tool.icon, size: 22, color: tool.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tool.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('远程', style: TextStyle(fontSize: 9, color: Colors.purple)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tool.description, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: () => _deployRemoteTool(tool),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
            child: const Text('部署', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
