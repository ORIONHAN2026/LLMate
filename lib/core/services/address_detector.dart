import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 地址检测工具：自动检测本机内网（局域网）地址与外网（公网）地址。
class AddressDetector {
  AddressDetector({this.httpClient});

  final http.Client? httpClient;

  /// 获取内网（局域网）IPv4 地址。
  ///
  /// 遍历本机网络接口，优先返回非回环、IPv4 的可达地址。
  /// 若无法获取，返回 null。
  static Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          // 跳过链路本地地址（169.254.x.x）
          if (ip.startsWith('169.254.')) continue;
          return ip;
        }
      }
    } catch (e) {
      // 忽略，返回 null
    }
    return null;
  }

  /// 获取外网（公网）IPv4 地址。
  ///
  /// 通过外部服务获取，若失败或超时返回 null。
  Future<String?> getExternalIp() async {
    final client = httpClient ?? http.Client();
    const endpoints = [
      'https://api.ipify.org?format=json',
      'https://ipinfo.io/json',
      'https://api.my-ip.io/v2/ip.json',
    ];
    try {
      for (final endpoint in endpoints) {
        try {
          final response = await client
              .get(Uri.parse(endpoint))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final ip = _parseIp(endpoint, response.body);
            if (ip != null && ip.isNotEmpty) {
              return ip;
            }
          }
        } catch (_) {
          // 尝试下一个端点
        }
      }
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
    return null;
  }

  String? _parseIp(String endpoint, String body) {
    try {
      final Map<String, dynamic> data = jsonDecode(body);
      if (endpoint.contains('ipify.org')) {
        return data['ip'] as String?;
      } else if (endpoint.contains('ipinfo.io')) {
        return data['ip'] as String?;
      } else if (endpoint.contains('my-ip.io')) {
        return data['ip'] as String?;
      }
    } catch (_) {
      // 部分服务直接返回纯文本 IP
      final trimmed = body.trim();
      if (trimmed.isNotEmpty && trimmed.contains('.')) {
        return trimmed;
      }
    }
    return null;
  }
}
