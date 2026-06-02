import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Python 脚本执行服务。
///
/// 支持两种调用方式：
/// - 内联脚本：通过 `script` 参数直接传入 Python 代码
/// - 文件执行：通过 `filePath` 参数指定 .py 文件路径
///
/// 可选参数 `requirements` 支持自动安装 pip 依赖。
class PythonToolService {
  static const _execTimeoutSeconds = 60;
  static const _toolName = 'python_execute';

  /// 执行 Python 脚本
  static Future<Map<String, dynamic>> execute({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    final scriptContent = (arguments['script'] as String?)?.trim() ?? '';
    final filePath = (arguments['filePath'] as String?)?.trim() ?? '';
    final scriptArgs =
        (arguments['args'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final requirements =
        (arguments['requirements'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // ── 参数校验 ──
    if (scriptContent.isEmpty && filePath.isEmpty) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': '错误: 必须提供 script 或 filePath 参数。',
        'isError': true,
      };
    }

    // ── 自动安装 pip 依赖 ──
    if (requirements.isNotEmpty) {
      try {
        final pipResult = await Process.run(
          'pip3',
          ['install', ...requirements],
          runInShell: true,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('pip 安装依赖超时');
          },
        );

        if (pipResult.exitCode != 0) {
          final errMsg = (pipResult.stderr as String).trim();
          debugPrint('⚠️ pip 安装依赖失败: $errMsg');
        }
      } catch (e) {
        debugPrint('⚠️ pip 安装依赖异常: $e');
        // pip 失败不阻断执行，可能依赖已安装
      }
    }

    // ── 确定 python3 路径 ──
    final pythonPath = await _findPython();

    // ── 构建命令行参数 ──
    final List<String> cmdArgs;
    if (scriptContent.isNotEmpty) {
      // 内联脚本
      cmdArgs = ['-c', scriptContent, ...scriptArgs];
    } else {
      // 文件执行
      cmdArgs = [filePath, ...scriptArgs];
    }

    // ── 执行 ──
    try {
      final result = await Process.run(
        pythonPath,
        cmdArgs,
        runInShell: true,
      ).timeout(
        const Duration(seconds: _execTimeoutSeconds),
        onTimeout: () {
          throw TimeoutException(
            'Python 脚本执行超时 (${_execTimeoutSeconds}s)',
          );
        },
      );

      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();
      final exitCode = result.exitCode;

      final output = StringBuffer();
      if (stdout.isNotEmpty) output.writeln(stdout);
      if (stderr.isNotEmpty) output.writeln(stderr);

      final msg = output.toString().trim();
      final preview = msg.length > 500 ? '${msg.substring(0, 500)}...' : msg;

      debugPrint(
        '🐍 [$_toolName] exit=$exitCode'
        '${scriptContent.isNotEmpty ? ', script=${scriptContent.length}chars' : ', file=$filePath'}'
        ', output=$preview',
      );

      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': msg.isNotEmpty ? msg : (exitCode == 0 ? '脚本执行完成（无输出）' : '脚本执行失败 (exit $exitCode)'),
        'isError': exitCode != 0,
      };
    } on TimeoutException catch (e) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': e.message ?? 'Python 脚本执行超时',
        'isError': true,
      };
    } catch (e) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': 'Python 执行失败: $e',
        'isError': true,
      };
    }
  }

  /// 查找可用的 python3 路径
  static Future<String> _findPython() async {
    // 优先尝试 python3
    try {
      final result = await Process.run('which', ['python3']);
      if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
        return 'python3';
      }
    } catch (_) {}

    // 回退 python
    try {
      final result = await Process.run('which', ['python']);
      if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
        return 'python';
      }
    } catch (_) {}

    // 兜底
    return 'python3';
  }
}
