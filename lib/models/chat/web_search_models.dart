/// 搜索引擎配置
class SearchEngineConfig {
  final String name;
  final String displayName;
  final String apiUrl;
  final bool requiresAuth;
  final bool isEnabled;
  final String? apiKey;

  const SearchEngineConfig({
    required this.name,
    required this.displayName,
    required this.apiUrl,
    required this.requiresAuth,
    this.isEnabled = true,
    this.apiKey,
  });
}

/// 网页搜索查询参数
class WebSearchQuery {
  final String keyword;
  final String searchEngine;
  final int maxResults;
  final String? language;
  final String? region;
  final bool safeSearch;
  final DateTime timestamp;

  const WebSearchQuery({
    required this.keyword,
    required this.searchEngine,
    this.maxResults = 5,
    this.language,
    this.region,
    this.safeSearch = true,
    required this.timestamp,
  });
}

/// 单条搜索结果
class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final String? thumbnail;
  final DateTime? publishDate;
  final String? source;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.thumbnail,
    this.publishDate,
    this.source,
  });
}

/// 提取的网页内容
class WebContent {
  final String url;
  final String title;
  final String content;
  final String summary;
  final DateTime extractedAt;
  final bool isContentTruncated;
  final int originalLength;

  const WebContent({
    required this.url,
    required this.title,
    required this.content,
    required this.summary,
    required this.extractedAt,
    this.isContentTruncated = false,
    this.originalLength = 0,
  });
}

/// 网页搜索结果集合
class WebSearchResults {
  final WebSearchQuery query;
  final List<SearchResult> results;
  final List<WebContent> contents;
  final String searchId;
  final DateTime searchTime;
  final Duration searchDuration;
  final String? errorMessage;
  final bool isSuccess;

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
}
