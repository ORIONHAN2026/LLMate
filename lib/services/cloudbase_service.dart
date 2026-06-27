import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../storage/storage_paths.dart';

/// 腾讯 CloudBase 配置
class CloudBaseConfig {
  final String envId;
  final String secretId;
  final String secretKey;
  final String region;

  const CloudBaseConfig({
    required this.envId,
    required this.secretId,
    required this.secretKey,
    this.region = 'ap-shanghai',
  });

  Map<String, dynamic> toJson() => {
    'envId': envId,
    'secretId': secretId,
    'secretKey': secretKey,
    'region': region,
  };

  factory CloudBaseConfig.fromJson(Map<String, dynamic> json) {
    return CloudBaseConfig(
      envId: json['envId'] as String,
      secretId: json['secretId'] as String,
      secretKey: json['secretKey'] as String,
      region: json['region'] as String? ?? 'ap-shanghai',
    );
  }
}

/// CloudBase 部署服务
class CloudBaseService {
  static CloudBaseConfig? _config;
  static bool _initialized = false;

  /// 配置文件路径: ~/.llmwork/mcps/tencentcloudbase.yaml
  static String get _configPath => p.join(StoragePaths.mcpsDir, 'tencentcloudbase.yaml');

  /// 初始化，加载配置
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final file = File(_configPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _config = CloudBaseConfig.fromJson(json);
      }
    } catch (e) {
      debugPrint('⚠️ 加载 CloudBase 配置失败: $e');
    }

    _initialized = true;
  }

  /// 获取当前配置
  static Future<CloudBaseConfig?> getConfig() async {
    await initialize();
    return _config;
  }

  /// 保存配置
  static Future<void> saveConfig(CloudBaseConfig config) async {
    await StoragePaths.ensureMcpsDir();
    final file = File(_configPath);
    await file.writeAsString(jsonEncode(config.toJson()));
    _config = config;
  }

  /// 删除配置
  static Future<void> deleteConfig() async {
    final file = File(_configPath);
    if (await file.exists()) {
      await file.delete();
    }
    _config = null;
  }

  /// 是否已配置
  static Future<bool> isConfigured() async {
    await initialize();
    return _config != null;
  }

  /// 部署 MCP 服务到 CloudBase
  ///
  /// [serverName] - 服务名称
  /// [serverPath] - Go 服务器代码目录
  ///
  /// 返回部署后的服务 URL
  static Future<String> deploy(String serverName, String serverPath) async {
    if (_config == null) {
      throw Exception('CloudBase 未配置，请先配置环境');
    }

    debugPrint('🚀 开始部署 MCP 服务: $serverName');

    // 1. 编译 Go 代码
    debugPrint('📦 编译 Go 代码...');
    final buildResult = await Process.run(
      'go',
      ['build', '-o', 'main', '.'],
      workingDirectory: serverPath,
    );

    if (buildResult.exitCode != 0) {
      throw Exception('编译失败: ${buildResult.stderr}');
    }

    // 2. 打包部署文件
    debugPrint('📁 打包部署文件...');
    final distDir = p.join(serverPath, 'dist');
    await Directory(distDir).create(recursive: true);

    // 复制可执行文件
    await Process.run(
      'cp',
      [p.join(serverPath, 'main'), p.join(distDir, 'main')],
    );

    // 创建入口脚本
    final entryScript = '''#!/bin/sh
./main
''';
    await File(p.join(distDir, 'index.sh')).writeAsString(entryScript);

    // 创建配置文件
    final config = {
      'runtime': 'custom',
      'handler': 'index.handler',
      'version': '1.0.0',
      'installDependency': false,
    };
    await File(p.join(distDir, 'cloudbaserc.json'))
        .writeAsString(jsonEncode(config));

    // 3. 部署到 CloudBase
    debugPrint('☁️ 部署到 CloudBase...');
    final deployResult = await Process.run(
      'tcb',
      [
        'fn',
        'deploy',
        serverName,
        '--envId', _config!.envId,
        '--region', _config!.region,
        '--code', distDir,
      ],
      environment: {
        'TENCENT_SECRET_ID': _config!.secretId,
        'TENCENT_SECRET_KEY': _config!.secretKey,
      },
    );

    if (deployResult.exitCode != 0) {
      throw Exception('部署失败: ${deployResult.stderr}');
    }

    // 4. 获取服务 URL
    final url = 'https://${serverName}.${_config!.envId}.service.tcloudbase.com';
    debugPrint('✅ 部署成功: $url');

    return url;
  }

  /// 删除远程 MCP 服务
  static Future<void> undeploy(String serverName) async {
    if (_config == null) {
      throw Exception('CloudBase 未配置');
    }

    debugPrint('🗑 删除远程 MCP 服务: $serverName');

    final result = await Process.run(
      'tcb',
      [
        'fn',
        'delete',
        serverName,
        '--envId', _config!.envId,
      ],
      environment: {
        'TENCENT_SECRET_ID': _config!.secretId,
        'TENCENT_SECRET_KEY': _config!.secretKey,
      },
    );

    if (result.exitCode != 0) {
      throw Exception('删除失败: ${result.stderr}');
    }

    debugPrint('✅ 删除成功: $serverName');
  }
}
