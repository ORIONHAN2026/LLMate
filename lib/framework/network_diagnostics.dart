import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// 网络诊断工具
/// 用于检测网络连接和API配置问题
class NetworkDiagnostics {
  static final Dio _dio = Dio();

  /// 测试网络连接
  static Future<Map<String, dynamic>> testConnection({
    required String url,
    String? apiKey,
    Map<String, String>? headers,
  }) async {
    try {
      if (kDebugMode) {
        print('=== 网络诊断开始 ===');
        print('测试URL: $url');
        print('API Key: ${apiKey?.substring(0, 10)}...');
        print('==================');
      }

      // 1. 基本网络连接测试
      final connectionResult = await _testBasicConnection(url);

      // 2. API 端点测试
      final apiResult = await _testApiEndpoint(url, apiKey, headers);

      // 3. 生成诊断报告
      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'url': url,
        'basicConnection': connectionResult,
        'apiEndpoint': apiResult,
        'overall': _evaluateOverall(connectionResult, apiResult),
      };

      if (kDebugMode) {
        print('=== 诊断报告 ===');
        print('基本连接: ${connectionResult['success'] ? '成功' : '失败'}');
        print('API端点: ${apiResult['success'] ? '成功' : '失败'}');
        final overall = report['overall'] as Map<String, dynamic>?;
        print('整体评估: ${overall?['status'] ?? '未知'}');
        print('=============');
      }

      return report;
    } catch (e) {
      if (kDebugMode) {
        print('诊断过程出错: $e');
      }
      return {
        'error': e.toString(),
        'success': false,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 测试基本网络连接
  static Future<Map<String, dynamic>> _testBasicConnection(String url) async {
    try {
      final uri = Uri.parse(url);

      // 测试 DNS 解析
      final addresses = await InternetAddress.lookup(uri.host);
      if (addresses.isEmpty) {
        return {
          'success': false,
          'error': 'DNS解析失败',
          'details': 'Unable to resolve host: ${uri.host}',
        };
      }

      // 测试端口连接
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: Duration(seconds: 10),
      );
      socket.destroy();

      return {
        'success': true,
        'host': uri.host,
        'port': uri.port,
        'addresses': addresses.map((addr) => addr.address).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'type': e.runtimeType.toString(),
      };
    }
  }

  /// 测试API端点
  static Future<Map<String, dynamic>> _testApiEndpoint(
    String url,
    String? apiKey,
    Map<String, String>? headers,
  ) async {
    try {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      };

      if (apiKey != null) {
        requestHeaders['Authorization'] = 'Bearer $apiKey';
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: requestHeaders,
          sendTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
          validateStatus: (status) => true, // 接受所有状态码
        ),
      );

      return {
        'success': response.statusCode != null && response.statusCode! < 500,
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
        'headers': response.headers.map,
        'hasResponse': response.data != null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'type': e.runtimeType.toString(),
      };
    }
  }

  /// 评估整体状态
  static Map<String, dynamic> _evaluateOverall(
    Map<String, dynamic> connectionResult,
    Map<String, dynamic> apiResult,
  ) {
    final connectionOk = connectionResult['success'] == true;
    final apiOk = apiResult['success'] == true;

    if (connectionOk && apiOk) {
      return {'status': 'healthy', 'message': '网络连接和API配置正常'};
    } else if (connectionOk && !apiOk) {
      return {
        'status': 'api_issue',
        'message': '网络连接正常，但API配置有问题',
        'suggestion': '请检查API密钥、URL路径和权限设置',
      };
    } else if (!connectionOk) {
      return {
        'status': 'connection_issue',
        'message': '网络连接有问题',
        'suggestion': '请检查网络连接、防火墙设置和DNS配置',
      };
    } else {
      return {
        'status': 'unknown',
        'message': '状态未知',
        'suggestion': '请检查所有网络和API设置',
      };
    }
  }

  /// 生成人类可读的诊断报告
  static String generateReadableReport(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    buffer.writeln('📡 网络诊断报告');
    buffer.writeln('🕐 时间: ${report['timestamp']}');
    buffer.writeln('🌐 URL: ${report['url']}');
    buffer.writeln('');

    if (report.containsKey('error')) {
      buffer.writeln('❌ 诊断失败: ${report['error']}');
      return buffer.toString();
    }

    final connection = report['basicConnection'];
    final api = report['apiEndpoint'];
    final overall = report['overall'];

    buffer.writeln('🔌 基本连接: ${connection['success'] ? '✅ 成功' : '❌ 失败'}');
    if (!connection['success']) {
      buffer.writeln('   错误: ${connection['error']}');
    }

    buffer.writeln('🔗 API端点: ${api['success'] ? '✅ 成功' : '❌ 失败'}');
    if (!api['success']) {
      buffer.writeln('   错误: ${api['error']}');
    } else {
      buffer.writeln('   状态码: ${api['statusCode']}');
    }

    buffer.writeln('');
    buffer.writeln('📊 整体评估: ${overall['status']}');
    buffer.writeln('💡 ${overall['message']}');
    if (overall.containsKey('suggestion')) {
      buffer.writeln('🔧 建议: ${overall['suggestion']}');
    }

    return buffer.toString();
  }
}
