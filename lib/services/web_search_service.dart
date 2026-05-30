import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat/web_search_models.dart';

/// 网页搜索服务
class WebSearchService {
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// 执行网页搜索
  static Future<WebSearchResults> performSearch(WebSearchQuery query) async {
    print('🚀 开始执行网页搜索: ${query.keyword}, 引擎: ${query.searchEngine}');

    final startTime = DateTime.now();
    final searchId =
        '${startTime.millisecondsSinceEpoch}_${query.keyword.hashCode}';

    try {
      // 1. 获取搜索结果
      print('🔍 正在获取搜索结果...');
      final searchResults = await _getSearchResults(query);
      print('📊 获取到 ${searchResults.length} 个搜索结果');

      // 2. 提取网页内容
      print('📄 正在提取网页内容...');
      final webContents = await _extractWebContents(searchResults);
      print('📋 提取到 ${webContents.length} 个网页内容');

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print('✅ 搜索完成，用时: ${duration.inMilliseconds}ms');

      return WebSearchResults(
        query: query,
        results: searchResults,
        contents: webContents,
        searchId: searchId,
        searchTime: startTime,
        searchDuration: duration,
        isSuccess: true,
      );
    } catch (e) {
      print('❌ 搜索失败: $e');
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      return WebSearchResults(
        query: query,
        results: [],
        contents: [],
        searchId: searchId,
        searchTime: startTime,
        searchDuration: duration,
        errorMessage: e.toString(),
        isSuccess: false,
      );
    }
  }

  /// 获取搜索结果（根据不同搜索引擎）
  static Future<List<SearchResult>> _getSearchResults(
    WebSearchQuery query,
  ) async {
    switch (query.searchEngine.toLowerCase()) {
      case 'google':
        return await _searchGoogle(query);
      case 'bing':
        return await _searchBing(query);
      case 'duckduckgo':
        return await _searchDuckDuckGo(query);
      case 'baidu':
        return await _searchBaidu(query);
      default:
        return await _searchDuckDuckGo(query); // 默认使用DuckDuckGo（免费）
    }
  }

  /// Google搜索 (使用自定义搜索API)
  // ignore: unused_element
  static Future<List<SearchResult>> _searchGoogle(WebSearchQuery query) async {
    // 这里需要配置Google Custom Search API
    // 需要在Google Cloud Console创建项目并启用Custom Search API
    const apiKey = 'YOUR_GOOGLE_API_KEY'; // 需要配置
    const searchEngineId = 'YOUR_SEARCH_ENGINE_ID'; // 需要配置

    if (apiKey == 'YOUR_GOOGLE_API_KEY') {
      print('⚠️ Google API密钥未配置，返回备用搜索结果...');
      return _getFallbackSearchResults(query);
    }

    final url = Uri.parse('https://www.googleapis.com/customsearch/v1').replace(
      queryParameters: {
        'key': apiKey,
        'cx': searchEngineId,
        'q': query.keyword,
        'num': query.maxResults.toString(),
        if (query.language != null) 'lr': 'lang_${query.language}',
        if (query.region != null) 'gl': query.region,
        'safe': query.safeSearch ? 'active' : 'off',
      },
    );

    final response = await http.get(url).timeout(_defaultTimeout);

    if (response.statusCode != 200) {
      print('⚠️ Google搜索API响应失败，状态码: ${response.statusCode}');
      print('🔄 返回备用搜索结果...');
      return _getFallbackSearchResults(query);
    }

    final data = json.decode(response.body);
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map(
          (item) => SearchResult(
            title: item['title'] ?? '',
            url: item['link'] ?? '',
            snippet: item['snippet'] ?? '',
            thumbnail: item['pagemap']?['cse_thumbnail']?[0]?['src'],
            source: _extractDomain(item['link'] ?? ''),
          ),
        )
        .toList();
  }

  /// Bing搜索 (使用Bing Search API)
  // ignore: unused_element
  static Future<List<SearchResult>> _searchBing(WebSearchQuery query) async {
    const apiKey = 'YOUR_BING_API_KEY'; // 需要配置

    if (apiKey == 'YOUR_BING_API_KEY') {
      print('⚠️ Bing API密钥未配置，返回备用搜索结果...');
      return _getFallbackSearchResults(query);
    }

    final url = Uri.parse('https://api.bing.microsoft.com/v7.0/search').replace(
      queryParameters: {
        'q': query.keyword,
        'count': query.maxResults.toString(),
        if (query.language != null) 'setLang': query.language,
        if (query.region != null) 'cc': query.region,
        'safeSearch': query.safeSearch ? 'Strict' : 'Off',
      },
    );

    final response = await http
        .get(url, headers: {'Ocp-Apim-Subscription-Key': apiKey})
        .timeout(_defaultTimeout);

    if (response.statusCode != 200) {
      print('⚠️ Bing搜索API响应失败，状态码: ${response.statusCode}');
      print('🔄 返回备用搜索结果...');
      return _getFallbackSearchResults(query);
    }

    final data = json.decode(response.body);
    final webPages = data['webPages']?['value'] as List<dynamic>? ?? [];

    return webPages
        .map(
          (item) => SearchResult(
            title: item['name'] ?? '',
            url: item['url'] ?? '',
            snippet: item['snippet'] ?? '',
            publishDate:
                item['dateLastCrawled'] != null
                    ? DateTime.tryParse(item['dateLastCrawled'])
                    : null,
            source: _extractDomain(item['url'] ?? ''),
          ),
        )
        .toList();
  }

  /// DuckDuckGo搜索 (使用免费API)
  // ignore: unused_element
  static Future<List<SearchResult>> _searchDuckDuckGo(
    WebSearchQuery query,
  ) async {
    print('🔍 开始DuckDuckGo搜索，关键词: ${query.keyword}');

    try {
      // DuckDuckGo Instant Answer API (免费但功能有限)
      final url = Uri.parse('https://api.duckduckgo.com/').replace(
        queryParameters: {
          'q': query.keyword,
          'format': 'json',
          'no_html': '1',
          'skip_disambig': '1',
        },
      );

      print('📡 请求URL: $url');

      // 减少超时时间到10秒，避免长时间等待
      final response = await http.get(url).timeout(const Duration(seconds: 1));

      print('📊 响应状态码: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('⚠️ DuckDuckGo API响应失败，状态码: ${response.statusCode}');
        print('🔄 返回备用搜索结果...');
        return _getFallbackSearchResults(query);
      }

      print('📄 原始响应内容: ${response.body}');

      final data = json.decode(response.body);
      print('🔧 解析后的数据: $data');
      final results = <SearchResult>[];

      // 处理即时答案
      print('🔍 检查Abstract字段: ${data['Abstract']}');
      if (data['Abstract'] != null && data['Abstract'].toString().isNotEmpty) {
        print('✅ 找到Abstract，添加搜索结果');
        results.add(
          SearchResult(
            title: data['Heading'] ?? '${query.keyword} - 摘要',
            url:
                data['AbstractURL'] ??
                'https://duckduckgo.com/?q=${Uri.encodeComponent(query.keyword)}',
            snippet: data['Abstract'],
            source: data['AbstractSource'] ?? 'DuckDuckGo',
          ),
        );
      }

      // 处理相关主题
      final relatedTopics = data['RelatedTopics'] as List<dynamic>? ?? [];
      print('🔍 RelatedTopics数量: ${relatedTopics.length}');
      for (final topic in relatedTopics.take(
        query.maxResults - results.length,
      )) {
        print('🔍 处理RelatedTopic: $topic');
        if (topic['Text'] != null && topic['FirstURL'] != null) {
          print('✅ 添加RelatedTopic结果');
          results.add(
            SearchResult(
              title: topic['Text']?.split(' - ')[0] ?? '',
              url: topic['FirstURL'] ?? '',
              snippet: topic['Text'] ?? '',
              source: _extractDomain(topic['FirstURL'] ?? ''),
            ),
          );
        }
      }

      // 处理答案
      print('🔍 检查Answer字段: ${data['Answer']}');
      if (data['Answer'] != null &&
          data['Answer'].toString().isNotEmpty &&
          results.length < query.maxResults) {
        print('✅ 找到Answer，添加搜索结果');
        results.add(
          SearchResult(
            title: '${query.keyword} - 答案',
            url:
                data['AnswerURL'] ??
                'https://duckduckgo.com/?q=${Uri.encodeComponent(query.keyword)}',
            snippet: data['Answer'],
            source: 'DuckDuckGo Answer',
          ),
        );
      }

      // 如果没有找到任何结果，返回一个提示性的搜索结果
      if (results.isEmpty) {
        print('⚠️ 没有找到任何搜索结果，添加默认结果');
        results.add(
          SearchResult(
            title: '搜索: ${query.keyword}',
            url:
                'https://duckduckgo.com/?q=${Uri.encodeComponent(query.keyword)}',
            snippet: '未找到具体的搜索结果，建议访问DuckDuckGo进行更详细的搜索。关键词：${query.keyword}',
            source: 'DuckDuckGo',
          ),
        );
      }

      print('🎯 最终搜索结果数量: ${results.length}');
      for (int i = 0; i < results.length; i++) {
        print('📋 结果${i + 1}: ${results[i].title} - ${results[i].snippet}');
      }

      return results;
    } catch (e) {
      print('❌ DuckDuckGo API 调用失败: $e');
      print('🔄 使用备用搜索方案...');

      // 备用方案：返回基于关键词的模拟搜索结果
      return _getFallbackSearchResults(query);
    }
  }

  /// 备用搜索结果（当API不可用时）
  static List<SearchResult> _getFallbackSearchResults(WebSearchQuery query) {
    print('🔄 生成备用搜索结果: ${query.keyword}');

    return [
      SearchResult(
        title: '${query.keyword} - 百科信息',
        url:
            'https://zh.wikipedia.org/wiki/${Uri.encodeComponent(query.keyword)}',
        snippet: '关于${query.keyword}的详细介绍和解释。点击访问维基百科获取更多信息。',
        source: 'wikipedia.org',
      ),
      SearchResult(
        title: '${query.keyword} 相关资讯',
        url: 'https://www.baidu.com/s?wd=${Uri.encodeComponent(query.keyword)}',
        snippet: '搜索${query.keyword}的最新资讯和相关内容。点击访问百度搜索获取更多结果。',
        source: 'baidu.com',
      ),
      SearchResult(
        title: '${query.keyword} - Google搜索',
        url:
            'https://www.google.com/search?q=${Uri.encodeComponent(query.keyword)}',
        snippet: '在Google上搜索${query.keyword}的相关信息。点击访问Google获取全面的搜索结果。',
        source: 'google.com',
      ),
      SearchResult(
        title: '搜索建议: ${query.keyword}',
        url: 'https://duckduckgo.com/?q=${Uri.encodeComponent(query.keyword)}',
        snippet: '由于网络搜索API暂时不可用，建议您直接访问搜索引擎网站进行搜索。关键词：${query.keyword}',
        source: 'DuckDuckGo',
      ),
    ].take(query.maxResults).toList();
  }

  /// 百度搜索 (需要配置百度搜索API)
  // ignore: unused_element
  static Future<List<SearchResult>> _searchBaidu(WebSearchQuery query) async {
    // 百度搜索API需要企业认证，这里返回备用搜索结果
    print('⚠️ 百度搜索API需要企业认证，返回备用搜索结果...');
    return _getFallbackSearchResults(query);
  }

  /// 提取多个网页内容
  static Future<List<WebContent>> _extractWebContents(
    List<SearchResult> searchResults,
  ) async {
    final contents = <WebContent>[];

    // 从搜索结果中提取基本信息，暂时不进行实际网页抓取
    for (final result in searchResults) {
      try {
        final content = WebContent(
          url: result.url,
          title: result.title,
          content: result.snippet, // 使用搜索结果的摘要作为内容
          summary: result.snippet,
          extractedAt: DateTime.now(),
          isContentTruncated: true, // 标记为截断内容，因为只是摘要
          originalLength: result.snippet.length,
        );
        contents.add(content);
      } catch (e) {
        // 忽略单个网页提取失败，继续处理其他网页
        continue;
      }
    }

    return contents;
  }

  /// 获取可用的搜索引擎列表
  static List<SearchEngineConfig> getAvailableSearchEngines() {
    return [
      const SearchEngineConfig(
        name: 'google',
        displayName: 'Google',
        apiUrl: 'https://www.googleapis.com/customsearch/v1',
        requiresAuth: true,
      ),
      const SearchEngineConfig(
        name: 'bing',
        displayName: 'Bing',
        apiUrl: 'https://api.bing.microsoft.com/v7.0/search',
        requiresAuth: true,
        isEnabled: true, // 设为默认启用
      ),
      const SearchEngineConfig(
        name: 'duckduckgo',
        displayName: 'DuckDuckGo',
        apiUrl: 'https://api.duckduckgo.com',
        requiresAuth: false,
        isEnabled: true,
      ),
      const SearchEngineConfig(
        name: 'baidu',
        displayName: '百度',
        apiUrl: 'https://api.baidu.com',
        requiresAuth: true,
        isEnabled: false,
      ),
    ];
  }

  /// 从URL中提取域名
  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }
}
