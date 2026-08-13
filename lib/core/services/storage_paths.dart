import 'dart:io';
import 'package:path/path.dart' as p;

/// 集中管理 ~/.llmate/ 下的所有文件路径
class StoragePaths {
  StoragePaths._();

  static String? _home;

  static String get home =>
      _home ??
      (Platform.environment['HOME'] ??
              Platform.environment['USERPROFILE'] ??
              '.')
          .replaceAll('\\', '/');

  /// ~/.llmate/
  static String get root => p.join(home, '.llmate');

  /// ~/.llmate/ssl/
  static String get sslDir => p.join(root, 'ssl');

  /// ~/.llmate/chats/
  static String get chatsDir => p.join(root, 'chats');

  /// ~/.llmate/chats/{sessionId}/
  static String sessionDir(String sessionId) => p.join(chatsDir, sessionId);

  /// 获取工作模式目录
  ///
  /// - 如果设置了 workDirectory → `{workDirectory}/.llmate/{workMode}/`
  /// - 否则 → `{sessionDir}/.llmate/{workMode}/`
  static String modeDir({
    required String sessionId,
    required String workMode,
    String? workDirectory,
  }) {
    final base = (workDirectory != null && workDirectory.isNotEmpty)
        ? workDirectory
        : sessionDir(sessionId);
    return p.join(base, '.llmate', workMode);
  }

  /// 聊天室模式 - 角色目录
  static String rolesDir({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(
      sessionId: sessionId,
      workMode: 'chatroom',
      workDirectory: workDirectory,
    ),
    'roles',
  );

  /// 确保根目录存在
  static Future<void> ensureRoot() async {
    await Directory(root).create(recursive: true);
  }

  /// 确保 SSL 目录存在
  static Future<void> ensureSslDir() async {
    await Directory(sslDir).create(recursive: true);
  }
}
