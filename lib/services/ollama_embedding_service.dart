import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Ollama 向量化服务
class OllamaEmbeddingService {
  static const String _defaultHost = 'http://localhost:11434';
  static const String _embedModel = 'nomic-embed-text';
  
  final String _baseUrl;
  
  OllamaEmbeddingService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultHost;
  
  /// 获取文本的向量化表示
  Future<List<double>?> getEmbedding(String text) async {
    try {
      final url = Uri.parse('$_baseUrl/api/embeddings');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _embedModel,
          'prompt': text,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['embedding'] != null) {
          return List<double>.from(data['embedding']);
        }
      } else {
        if (kDebugMode) {
          print('向量化请求失败: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('向量化服务错误: $e');
      }
    }
    
    return null;
  }
  
  /// 批量获取文本的向量化表示
  Future<List<List<double>?>> getBatchEmbeddings(List<String> texts) async {
    final results = <List<double>?>[];
    
    // 为了避免过载服务器，我们一个一个处理
    // 在生产环境中，可以考虑并发处理或批量API
    for (final text in texts) {
      final embedding = await getEmbedding(text);
      results.add(embedding);
      
      // 添加小延迟避免过于频繁的请求
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }
  
  /// 检查 Ollama 服务是否可用
  Future<bool> isServiceAvailable() async {
    try {
      final url = Uri.parse('$_baseUrl/api/tags');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['models'] != null) {
          final models = data['models'] as List;
          return models.any((model) => model['name']?.toString().contains(_embedModel) == true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('检查 Ollama 服务可用性失败: $e');
      }
    }
    
    return false;
  }
  
  /// 下载并安装 nomic-embed-text 模型
  Future<bool> installEmbeddingModel() async {
    try {
      final url = Uri.parse('$_baseUrl/api/pull');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _embedModel,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('安装向量化模型失败: $e');
      }
      return false;
    }
  }
}
