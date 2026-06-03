import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:chathub/models/chat/mcp_config.dart';

/// MCP服务市场数据模型
class McpMarketService {
  final String name;
  final String description;
  final String command;
  final List<String> args;
  final String category;
  final List<String> tags;
  final String author;
  final String? iconUrl;
  final bool isPopular;
  final int downloads;

  const McpMarketService({
    required this.name,
    required this.description,
    required this.command,
    required this.args,
    required this.category,
    required this.tags,
    required this.author,
    this.iconUrl,
    this.isPopular = false,
    this.downloads = 0,
  });

  /// 转换为Mcp
  Mcp toMcp() {
    return Mcp(
      mcpId: 'mcp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      command: command,
      args: args,
    );
  }
}

class McpMarketPage extends StatefulWidget {
  final Function(Mcp) onServiceSelected;

  const McpMarketPage({super.key, required this.onServiceSelected});

  @override
  State<McpMarketPage> createState() => _McpMarketPageState();
}

class _McpMarketPageState extends State<McpMarketPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '全部';
  List<McpMarketService> _filteredServices = [];

  static const List<String> _categories = [
    '全部',
    '文件系统',
    '数据库',
    '网络工具',
    '开发工具',
    'AI助手',
    '其他',
  ];

  // 模拟的MCP服务市场数据
  static const List<McpMarketService> _marketServices = [
    McpMarketService(
      name: 'filesystem',
      description: '文件系统访问服务，可以读取、写入和管理本地文件',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-filesystem', '/Users'],
      category: '文件系统',
      tags: ['文件', '本地', '读写'],
      author: 'ModelContext Protocol',
      isPopular: true,
      downloads: 15420,
    ),
    McpMarketService(
      name: 'sqlite',
      description: 'SQLite数据库连接服务，支持查询和操作SQLite数据库',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-sqlite',
        '--db-path',
        './database.sqlite',
      ],
      category: '数据库',
      tags: ['数据库', 'SQL', 'SQLite'],
      author: 'ModelContext Protocol',
      isPopular: true,
      downloads: 8932,
    ),
    McpMarketService(
      name: 'web-search',
      description: '网络搜索服务，提供实时的网络搜索功能',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-web-search'],
      category: '网络工具',
      tags: ['搜索', '网络', '实时'],
      author: 'ModelContext Protocol',
      isPopular: false,
      downloads: 5643,
    ),
    McpMarketService(
      name: 'github',
      description: 'GitHub集成服务，可以访问和操作GitHub仓库',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-github',
        '--token',
        'YOUR_TOKEN',
      ],
      category: '开发工具',
      tags: ['GitHub', 'Git', '代码'],
      author: 'ModelContext Protocol',
      isPopular: true,
      downloads: 12156,
    ),
    McpMarketService(
      name: 'postgres',
      description: 'PostgreSQL数据库连接服务，支持复杂的SQL查询',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-postgres',
        '--connection-string',
        'postgresql://user:password@localhost/db',
      ],
      category: '数据库',
      tags: ['数据库', 'PostgreSQL', 'SQL'],
      author: 'ModelContext Protocol',
      isPopular: false,
      downloads: 6789,
    ),
    McpMarketService(
      name: 'memory',
      description: '内存存储服务，提供临时数据存储和检索功能',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-memory'],
      category: 'AI助手',
      tags: ['内存', '存储', '临时'],
      author: 'ModelContext Protocol',
      isPopular: false,
      downloads: 4321,
    ),
    McpMarketService(
      name: 'brave-search',
      description: 'Brave搜索引擎集成，提供隐私友好的搜索功能',
      command: 'npx',
      args: [
        '-y',
        '@modelcontextprotocol/server-brave-search',
        '--api-key',
        'YOUR_API_KEY',
      ],
      category: '网络工具',
      tags: ['搜索', '隐私', 'Brave'],
      author: 'ModelContext Protocol',
      isPopular: false,
      downloads: 3456,
    ),
    McpMarketService(
      name: 'puppeteer',
      description: '网页自动化服务，可以控制浏览器进行网页操作',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-puppeteer'],
      category: '开发工具',
      tags: ['自动化', '浏览器', '网页'],
      author: 'ModelContext Protocol',
      isPopular: false,
      downloads: 7890,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredServices = List.from(_marketServices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterServices() {
    setState(() {
      _filteredServices =
          _marketServices.where((service) {
            final matchesSearch =
                _searchController.text.isEmpty ||
                service.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                service.description.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                service.tags.any(
                  (tag) => tag.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ),
                );

            final matchesCategory =
                _selectedCategory == '全部' ||
                service.category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

      // 按热门程度和下载量排序
      _filteredServices.sort((a, b) {
        if (a.isPopular && !b.isPopular) return -1;
        if (!a.isPopular && b.isPopular) return 1;
        return b.downloads.compareTo(a.downloads);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MCP 服务市场',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: Column(
        children: [
          // 搜索和筛选区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 搜索框
                TextField(
                  controller: _searchController,
                  onChanged: (value) => _filterServices(),
                  decoration: InputDecoration(
                    hintText: '搜索 MCP 服务...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color: Colors.grey[500],
                      size: 18,
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                CupertinoIcons.clear,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterServices();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 分类筛选
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _filterServices();
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: Colors.blue,
                          checkmarkColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 服务列表
          Expanded(
            child:
                _filteredServices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredServices.length,
                      itemBuilder: (context, index) {
                        return _buildServiceCard(_filteredServices[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '没有找到相关服务',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试调整搜索关键词或选择其他分类',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(McpMarketService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showServiceDetail(service),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 服务标题行
              Row(
                children: [
                  // 服务图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(service.category),
                      color: Colors.blue[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 服务信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (service.isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '会员',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              service.author,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.download_circle,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${service.downloads}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 分类标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 服务描述
              Text(
                service.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 标签
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    service.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceDetail(McpMarketService service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCategoryIcon(service.category),
                  color: Colors.blue[600],
                  size: 16,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      service.author,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 描述
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 配置信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '配置信息:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Command: ${service.command}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Args: ${service.args.join(' ')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 标签和统计
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '标签:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children:
                                service.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.download_circle,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${service.downloads}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            service.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭详情对话框
                widget.onServiceSelected(service.toMcp());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('添加服务'),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '文件系统':
        return CupertinoIcons.folder;
      case '数据库':
        return CupertinoIcons.square_stack_3d_down_right;
      case '网络工具':
        return CupertinoIcons.globe;
      case '开发工具':
        return CupertinoIcons.hammer;
      case 'AI助手':
        return CupertinoIcons.memories;
      default:
        return CupertinoIcons.app;
    }
  }
}
