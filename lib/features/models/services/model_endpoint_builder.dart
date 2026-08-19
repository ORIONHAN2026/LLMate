class ModelEndpointBuilder {
  const ModelEndpointBuilder._();

  static String chatCompletionUrl({
    required String baseUrl,
    required String protocol,
    required String modelId,
    required String apiKey,
  }) {
    final url = baseUrl.trim();
    switch (protocol) {
      case 'anthropic':
        return _appendPathIfMissing(url, '/messages', 'messages');
      case 'gemini':
        if (url.contains('/models/')) return url;
        return _joinPath(url, 'models/$modelId:generateContent?key=$apiKey');
      default:
        return _appendPathIfMissing(
          url,
          '/chat/completions',
          'chat/completions',
        );
    }
  }

  static String _appendPathIfMissing(String url, String suffix, String path) {
    if (url.endsWith(suffix)) return url;
    return _joinPath(url, path);
  }

  static String _joinPath(String url, String path) {
    return url.endsWith('/') ? '$url$path' : '$url/$path';
  }
}
