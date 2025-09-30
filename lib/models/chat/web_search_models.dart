/// 网页搜索相关的数据模型

/// 搜索查询配置
class WebSearchQuery {
  final String keyword;           // 搜索关键词
  final String searchEngine;      // 搜索引擎 (google, bing, duckduckgo, baidu)
  final int maxResults;          // 最大结果数量
  final String? language;        // 搜索语言
  final String? region;          // 搜索地区
  final bool safeSearch;         // 安全搜索
  final DateTime timestamp;      // 搜索时间

  const WebSearchQuery({
    required this.keyword,
    this.searchEngine = 'google',
    this.maxResults = 5,
    this.language,
    this.region,
    this.safeSearch = true,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'keyword': keyword,
      'searchEngine': searchEngine,
      'maxResults': maxResults,
      'language': language,
      'region': region,
      'safeSearch': safeSearch,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WebSearchQuery.fromMap(Map<String, dynamic> map) {
    return WebSearchQuery(
      keyword: map['keyword'] ?? '',
      searchEngine: map['searchEngine'] ?? 'google',
      maxResults: map['maxResults'] ?? 5,
      language: map['language'],
      region: map['region'],
      safeSearch: map['safeSearch'] ?? true,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  WebSearchQuery copyWith({
    String? keyword,
    String? searchEngine,
    int? maxResults,
    String? language,
    String? region,
    bool? safeSearch,
    DateTime? timestamp,
  }) {
    return WebSearchQuery(
      keyword: keyword ?? this.keyword,
      searchEngine: searchEngine ?? this.searchEngine,
      maxResults: maxResults ?? this.maxResults,
      language: language ?? this.language,
      region: region ?? this.region,
      safeSearch: safeSearch ?? this.safeSearch,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// 单个搜索结果
class SearchResult {
  final String title;            // 标题
  final String url;              // 链接
  final String snippet;          // 摘要
  final String? thumbnail;       // 缩略图
  final DateTime? publishDate;   // 发布时间
  final String? source;          // 来源网站
  final double? relevanceScore;  // 相关性评分

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.thumbnail,
    this.publishDate,
    this.source,
    this.relevanceScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'snippet': snippet,
      'thumbnail': thumbnail,
      'publishDate': publishDate?.toIso8601String(),
      'source': source,
      'relevanceScore': relevanceScore,
    };
  }

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      snippet: map['snippet'] ?? '',
      thumbnail: map['thumbnail'],
      publishDate: map['publishDate'] != null
          ? DateTime.parse(map['publishDate'])
          : null,
      source: map['source'],
      relevanceScore: map['relevanceScore']?.toDouble(),
    );
  }
}

/// 网页内容
class WebContent {
  final String url;              // 网页URL
  final String title;            // 网页标题
  final String content;          // 提取的文本内容
  final String? summary;         // 内容摘要
  final List<String>? images;    // 图片链接
  final List<String>? links;     // 外链
  final Map<String, String>? metadata; // 元数据
  final DateTime extractedAt;    // 提取时间
  final bool isContentTruncated; // 内容是否被截断
  final int originalLength;      // 原始内容长度

  const WebContent({
    required this.url,
    required this.title,
    required this.content,
    this.summary,
    this.images,
    this.links,
    this.metadata,
    required this.extractedAt,
    this.isContentTruncated = false,
    this.originalLength = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'content': content,
      'summary': summary,
      'images': images,
      'links': links,
      'metadata': metadata,
      'extractedAt': extractedAt.toIso8601String(),
      'isContentTruncated': isContentTruncated,
      'originalLength': originalLength,
    };
  }

  factory WebContent.fromMap(Map<String, dynamic> map) {
    return WebContent(
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      summary: map['summary'],
      images: map['images']?.cast<String>(),
      links: map['links']?.cast<String>(),
      metadata: map['metadata']?.cast<String, String>(),
      extractedAt: DateTime.parse(map['extractedAt']),
      isContentTruncated: map['isContentTruncated'] ?? false,
      originalLength: map['originalLength'] ?? 0,
    );
  }
}

/// 搜索结果集合
class WebSearchResults {
  final WebSearchQuery query;           // 搜索查询
  final List<SearchResult> results;     // 搜索结果列表
  final List<WebContent> contents;      // 提取的网页内容
  final String searchId;                // 搜索ID
  final DateTime searchTime;            // 搜索时间
  final Duration searchDuration;        // 搜索耗时
  final String? errorMessage;           // 错误信息
  final bool isSuccess;                 // 是否成功

  const WebSearchResults({
    required this.query,
    required this.results,
    required this.contents,
    required this.searchId,
    required this.searchTime,
    required this.searchDuration,
    this.errorMessage,
    this.isSuccess = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query.toMap(),
      'results': results.map((r) => r.toMap()).toList(),
      'contents': contents.map((c) => c.toMap()).toList(),
      'searchId': searchId,
      'searchTime': searchTime.toIso8601String(),
      'searchDuration': searchDuration.inMilliseconds,
      'errorMessage': errorMessage,
      'isSuccess': isSuccess,
    };
  }

  factory WebSearchResults.fromMap(Map<String, dynamic> map) {
    return WebSearchResults(
      query: WebSearchQuery.fromMap(map['query']),
      results: (map['results'] as List)
          .map((r) => SearchResult.fromMap(r))
          .toList(),
      contents: (map['contents'] as List)
          .map((c) => WebContent.fromMap(c))
          .toList(),
      searchId: map['searchId'] ?? '',
      searchTime: DateTime.parse(map['searchTime']),
      searchDuration: Duration(milliseconds: map['searchDuration'] ?? 0),
      errorMessage: map['errorMessage'],
      isSuccess: map['isSuccess'] ?? true,
    );
  }

  /// 获取格式化的搜索结果摘要
  String getFormattedSummary() {
    if (!isSuccess) {
      return '搜索失败: ${errorMessage ?? "未知错误"}';
    }

    final buffer = StringBuffer();
    buffer.writeln('🌐 网页搜索结果');
    buffer.writeln('关键词: ${query.keyword}');
    buffer.writeln('搜索引擎: ${query.searchEngine}');
    buffer.writeln('搜索时间: ${searchTime.toString().substring(0, 19)}');
    buffer.writeln('搜索耗时: ${searchDuration.inMilliseconds}ms');
    buffer.writeln('结果数量: ${results.length}');
    buffer.writeln('内容数量: ${contents.length}');
    buffer.writeln();

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   URL: ${result.url}');
      buffer.writeln('   摘要: ${result.snippet}');
      if (result.source != null) {
        buffer.writeln('   来源: ${result.source}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 获取所有网页内容的合并文本
  String getCombinedContent() {
    if (contents.isEmpty) return '';
    
    final buffer = StringBuffer();
    for (int i = 0; i < contents.length; i++) {
      final content = contents[i];
      buffer.writeln('=== 网页 ${i + 1}: ${content.title} ===');
      buffer.writeln('URL: ${content.url}');
      buffer.writeln();
      buffer.writeln(content.content);
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// 搜索引擎配置
class SearchEngineConfig {
  final String name;             // 引擎名称
  final String displayName;      // 显示名称
  final String apiUrl;           // API地址
  final String? apiKey;          // API密钥
  final bool requiresAuth;       // 是否需要认证
  final Map<String, dynamic> defaultParams; // 默认参数
  final bool isEnabled;          // 是否启用

  const SearchEngineConfig({
    required this.name,
    required this.displayName,
    required this.apiUrl,
    this.apiKey,
    this.requiresAuth = false,
    this.defaultParams = const {},
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'apiUrl': apiUrl,
      'apiKey': apiKey,
      'requiresAuth': requiresAuth,
      'defaultParams': defaultParams,
      'isEnabled': isEnabled,
    };
  }

  factory SearchEngineConfig.fromMap(Map<String, dynamic> map) {
    return SearchEngineConfig(
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? '',
      apiUrl: map['apiUrl'] ?? '',
      apiKey: map['apiKey'],
      requiresAuth: map['requiresAuth'] ?? false,
      defaultParams: Map<String, dynamic>.from(map['defaultParams'] ?? {}),
      isEnabled: map['isEnabled'] ?? true,
    );
  }
}
