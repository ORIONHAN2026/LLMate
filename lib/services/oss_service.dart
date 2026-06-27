import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// OSS 配置
class OssConfig {
  final String endpoint;
  final String bucket;
  final String accessKeyId;
  final String accessKeySecret;
  final String? region;
  final String?stsToken;

  const OssConfig({
    required this.endpoint,
    required this.bucket,
    required this.accessKeyId,
    required this.accessKeySecret,
    this.region,
    this.stsToken,
  });

  /// 从 JSON 构建
  factory OssConfig.fromJson(Map<String, dynamic> json) {
    return OssConfig(
      endpoint: json['endpoint'] ?? '',
      bucket: json['bucket'] ?? '',
      accessKeyId: json['accessKeyId'] ?? '',
      accessKeySecret: json['accessKeySecret'] ?? '',
      region: json['region'],
      stsToken: json['stsToken'],
    );
  }

  Map<String, dynamic> toJson() => {
        'endpoint': endpoint,
        'bucket': bucket,
        'accessKeyId': accessKeyId,
        'accessKeySecret': accessKeySecret,
        if (region != null) 'region': region,
        if (stsToken != null) 'stsToken': stsToken,
      };

  bool get isValid => endpoint.isNotEmpty && bucket.isNotEmpty && accessKeyId.isNotEmpty;
}

/// OSS 上传结果
class OssUploadResult {
  final String url;
  final String key;
  final int size;

  const OssUploadResult({
    required this.url,
    required this.key,
    required this.size,
  });
}

/// OSS 服务 - 支持阿里云 OSS
///
/// 使用直传方式上传文件，生成可访问的 URL
class OssService {
  static OssService? _instance;
  static OssService get instance => _instance ??= OssService._();
  OssService._();

  OssConfig? _config;
  final Dio _dio = Dio();

  /// 初始化 OSS 配置
  void configure(OssConfig config) {
    _config = config;
  }

  /// 获取当前配置
  OssConfig? get config => _config;

  /// 是否已配置
  bool get isConfigured => _config?.isValid == true;

  /// 上传文件到 OSS
  ///
  /// [file] - 要上传的文件
  /// [keyPrefix] - 可选的 key 前缀（如 'attachments/'）
  /// [onProgress] - 上传进度回调 (0.0 - 1.0)
  Future<OssUploadResult> uploadFile(
    File file, {
    String keyPrefix = 'attachments/',
    Function(double progress)? onProgress,
  }) async {
    if (!isConfigured) {
      throw Exception('OSS 未配置，请先配置 OSS 信息');
    }

    final config = _config!;
    final fileName = file.path.split('/').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final key = '$keyPrefix${timestamp}_$fileName';

    // 生成签名 URL
    final url = _generatePutUrl(config, key);

    // 读取文件
    final bytes = await file.readAsBytes();

    // 上传
    final response = await _dio.put(
      url,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': _getContentType(fileName),
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final accessUrl = _generateGetUrl(config, key);
      return OssUploadResult(
        url: accessUrl,
        key: key,
        size: bytes.length,
      );
    } else {
      throw Exception('OSS 上传失败: ${response.statusCode}');
    }
  }

  /// 上传数据到 OSS
  Future<OssUploadResult> uploadData(
    List<int> bytes, {
    required String fileName,
    String keyPrefix = 'attachments/',
    String? contentType,
    Function(double progress)? onProgress,
  }) async {
    if (!isConfigured) {
      throw Exception('OSS 未配置');
    }

    final config = _config!;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final key = '$keyPrefix${timestamp}_$fileName';

    final url = _generatePutUrl(config, key);

    final response = await _dio.put(
      url,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType ?? _getContentType(fileName),
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final accessUrl = _generateGetUrl(config, key);
      return OssUploadResult(
        url: accessUrl,
        key: key,
        size: bytes.length,
      );
    } else {
      throw Exception('OSS 上传失败: ${response.statusCode}');
    }
  }

  /// 生成 PUT 签名 URL
  String _generatePutUrl(OssConfig config, String key) {
    final host = '${config.bucket}.${config.endpoint}';
    final date = HttpDate.format(DateTime.now().toUtc());

    // 签名字符串
    final stringToSign = 'PUT\n\n\n$date\n/$key';
    final signature = _sign(config.accessKeySecret, stringToSign);

    return 'https://$host/$key?Expires=${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 3600}&OSSAccessKeyId=${config.accessKeyId}&Signature=${Uri.encodeComponent(signature)}';
  }

  /// 生成 GET 签名 URL（用于访问）
  String _generateGetUrl(OssConfig config, String key) {
    final host = '${config.bucket}.${config.endpoint}';
    return 'https://$host/$key';
  }

  /// HMAC-SHA1 签名
  String _sign(String key, String data) {
    final hmac = Hmac(sha1, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return base64Encode(digest.bytes);
  }

  /// 获取 Content-Type
  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'json': 'application/json',
      'xml': 'application/xml',
      'zip': 'application/zip',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}
