import 'package:flutter/material.dart';
import '../models/chat/web_search_models.dart';
import '../services/web_search_service.dart';
import '../utils/snackbar_utils.dart';

/// 网页搜索配置对话框
class WebSearchDialog extends StatefulWidget {
  final Function(WebSearchResults) onSearchComplete;

  const WebSearchDialog({super.key, required this.onSearchComplete});

  @override
  State<WebSearchDialog> createState() => _WebSearchDialogState();
}

class _WebSearchDialogState extends State<WebSearchDialog> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedEngine = 'duckduckgo';
  int _maxResults = 5;
  String _language = 'zh';
  String _region = 'CN';
  bool _safeSearch = true;
  bool _isSearching = false;

  late List<SearchEngineConfig> _availableEngines;

  @override
  void initState() {
    super.initState();
    _availableEngines =
        WebSearchService.getAvailableSearchEngines()
            .where((engine) => engine.isEnabled)
            .toList();

    if (_availableEngines.isNotEmpty) {
      _selectedEngine = _availableEngines.first.name;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 执行搜索
  Future<void> _performSearch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final query = WebSearchQuery(
        keyword: _searchController.text.trim(),
        searchEngine: _selectedEngine,
        maxResults: _maxResults,
        language: _language,
        region: _region,
        safeSearch: _safeSearch,
        timestamp: DateTime.now(),
      );

      final results = await WebSearchService.performSearch(query);

      if (results.isSuccess) {
        widget.onSearchComplete(results);
        Navigator.of(context).pop();
        SnackBarUtils.showSuccess(
          context,
          '搜索完成，找到 ${results.results.length} 个结果',
        );
      } else {
        SnackBarUtils.showError(context, '搜索失败: ${results.errorMessage}');
      }
    } catch (e) {
      SnackBarUtils.showError(context, '搜索出错: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Icon(Icons.search, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    '网页搜索',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 搜索关键词输入框
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: '搜索关键词',
                  hintText: '请输入要搜索的内容...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入搜索关键词';
                  }
                  return null;
                },
                onFieldSubmitted: _isSearching ? null : (_) => _performSearch(),
              ),
              const SizedBox(height: 16),

              // 搜索引擎选择
              Row(
                children: [
                  const Text(
                    '搜索引擎: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEngine,
                      items:
                          _availableEngines.map((engine) {
                            return DropdownMenuItem(
                              value: engine.name,
                              child: Row(
                                children: [
                                  _getEngineIcon(engine.name),
                                  const SizedBox(width: 8),
                                  Text(engine.displayName),
                                  if (engine.requiresAuth &&
                                      engine.apiKey == null)
                                    const Text(
                                      ' (需配置)',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedEngine = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 高级设置
              ExpansionTile(
                title: const Text(
                  '高级设置',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                children: [
                  const SizedBox(height: 8),

                  // 结果数量
                  Row(
                    children: [
                      const Text('结果数量: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _maxResults.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _maxResults.toString(),
                          onChanged: (value) {
                            setState(() {
                              _maxResults = value.round();
                            });
                          },
                        ),
                      ),
                      Text('$_maxResults'),
                    ],
                  ),

                  // 语言设置
                  Row(
                    children: [
                      const Text('语言: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _language,
                          items: const [
                            DropdownMenuItem(value: 'zh', child: Text('中文')),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(value: 'ja', child: Text('日本語')),
                            DropdownMenuItem(value: 'ko', child: Text('한국어')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _language = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 地区设置
                  Row(
                    children: [
                      const Text('地区: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _region,
                          items: const [
                            DropdownMenuItem(value: 'CN', child: Text('中国')),
                            DropdownMenuItem(value: 'US', child: Text('美国')),
                            DropdownMenuItem(value: 'JP', child: Text('日本')),
                            DropdownMenuItem(value: 'KR', child: Text('韩国')),
                            DropdownMenuItem(value: 'GB', child: Text('英国')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _region = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 安全搜索
                  Row(
                    children: [
                      const Text('安全搜索: '),
                      const SizedBox(width: 8),
                      Switch(
                        value: _safeSearch,
                        onChanged: (value) {
                          setState(() {
                            _safeSearch = value;
                          });
                        },
                      ),
                      Text(_safeSearch ? '开启' : '关闭'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 底部按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSearching ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child:
                        _isSearching
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('搜索'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取搜索引擎图标
  Widget _getEngineIcon(String engine) {
    switch (engine) {
      case 'google':
        return const Icon(Icons.search, color: Colors.blue, size: 16);
      case 'bing':
        return const Icon(Icons.search, color: Colors.green, size: 16);
      case 'duckduckgo':
        return const Icon(Icons.security, color: Colors.orange, size: 16);
      case 'baidu':
        return const Icon(Icons.search, color: Colors.red, size: 16);
      default:
        return const Icon(Icons.search, color: Colors.grey, size: 16);
    }
  }
}

/// 搜索结果预览对话框
class SearchResultsPreviewDialog extends StatelessWidget {
  final WebSearchResults results;

  const SearchResultsPreviewDialog({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.web, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  '搜索结果预览',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 搜索信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关键词: ${results.query.keyword}'),
                  Text('搜索引擎: ${results.query.searchEngine}'),
                  Text('结果数量: ${results.results.length}'),
                  Text('搜索耗时: ${results.searchDuration.inMilliseconds}ms'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 搜索结果列表
            Expanded(
              child: ListView.builder(
                itemCount: results.results.length,
                itemBuilder: (context, index) {
                  final result = results.results[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        result.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            result.url,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.snippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      leading: const Icon(Icons.web_asset),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          // 这里可以添加打开链接的功能
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
