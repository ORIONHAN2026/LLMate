import 'dart:io';
import 'package:path/path.dart' as p;

/// 集中管理 ~/.llmwork/ 下的所有文件路径
class StoragePaths {
  StoragePaths._();

  static String? _home;

  static String get home =>
      _home ??
      (Platform.environment['HOME'] ??
              Platform.environment['USERPROFILE'] ??
              '.')
          .replaceAll('\\', '/');

  /// ~/.llmwork/
  static String get root => p.join(home, '.llmwork');

  /// ~/.llmwork/mcps/
  static String get mcpsDir => p.join(root, 'mcps');

  /// ~/.llmwork/ssl/
  static String get sslDir => p.join(root, 'ssl');

  /// ~/.llmwork/models.json
  static String get modelsFile => p.join(root, 'models.json');

  /// ~/.llmwork/settings.json
  static String get settingsFile => p.join(root, 'settings.json');

  /// ~/.llmwork/vendor_keys.json
  static String get vendorKeysFile => p.join(root, 'vendor_keys.json');

  /// ~/.llmwork/chats/
  static String get chatsDir => p.join(root, 'chats');

  /// ~/.llmwork/chats/{sessionId}/
  static String sessionDir(String sessionId) => p.join(chatsDir, sessionId);

  /// ~/.llmwork/chats/{sessionId}/session.json
  static String sessionFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'session.json');

  /// ~/.llmwork/chats/{sessionId}/message.json
  static String messageFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'message.json');

  /// ~/.llmwork/chats/{sessionId}/memory.md
  static String memoryFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'memory.md');

  /// ~/.llmwork/chats/{sessionId}/mcp.json
  static String sessionMcpFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'mcp.json');

  /// ~/.llmwork/chats/{sessionId}/business.md
  static String businessFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'business.md');

  // ═══════════════════════════════════════════════════
  // 工作模式文件路径（按模式名隐藏文件夹存储）
  // ═══════════════════════════════════════════════════

  /// 获取工作模式目录
  ///
  /// - 如果设置了 workDirectory → `{workDirectory}/.llmwork/{workMode}/`
  /// - 否则 → `{sessionDir}/.llmwork/{workMode}/`
  static String modeDir({
    required String sessionId,
    required String workMode,
    String? workDirectory,
  }) {
    final base = (workDirectory != null && workDirectory.isNotEmpty)
        ? workDirectory
        : sessionDir(sessionId);
    return p.join(base, '.llmwork', workMode);
  }

  /// 获取 .llmwork 根目录
  static String llmworkDir({
    required String sessionId,
    String? workDirectory,
  }) {
    final base = (workDirectory != null && workDirectory.isNotEmpty)
        ? workDirectory
        : sessionDir(sessionId);
    return p.join(base, '.llmwork');
  }

  /// 确保工作模式目录存在
  static Future<void> ensureModeDir({
    required String sessionId,
    required String workMode,
    String? workDirectory,
  }) async {
    final dir = modeDir(
      sessionId: sessionId,
      workMode: workMode,
      workDirectory: workDirectory,
    );
    await Directory(dir).create(recursive: true);
  }

  /// 合同模式文件
  static String contractContentFile({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'contract', workDirectory: workDirectory),
    'contract_content.md',
  );

  static String contractProcessFile({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'contract', workDirectory: workDirectory),
    'contract_process.md',
  );

  static String contractDisgussFile({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'contract', workDirectory: workDirectory),
    'contract_disguss.md',
  );

  /// 发票模式文件
  static String invoiceSummaryFile({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'invoice', workDirectory: workDirectory),
    'invoice_summary.md',
  );

  static String invoiceDetailFile({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'invoice', workDirectory: workDirectory),
    'invoice_detail.md',
  );

  static String reimbursementFile({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'invoice', workDirectory: workDirectory),
    'reimbursement.md',
  );

  /// 通用文件（备忘录、脑图等，各模式独立）
  static String noteFile({
    required String sessionId,
    required String workMode,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: workMode, workDirectory: workDirectory),
    'note.md',
  );

  static String mindmapFile({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'creative', workDirectory: workDirectory),
    'mindmap.md',
  );

  /// 聊天室模式 - 角色目录
  static String rolesDir({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'chatroom', workDirectory: workDirectory),
    'roles',
  );

  static String roleFile({
    required String sessionId,
    required String roleName,
    String? workDirectory,
  }) => p.join(
    rolesDir(sessionId: sessionId, workDirectory: workDirectory),
    '$roleName.md',
  );

  /// 创意模式 - 草稿目录
  static String draftsDir({
    required String sessionId,
    String? workDirectory,
  }) => p.join(
    modeDir(sessionId: sessionId, workMode: 'creative', workDirectory: workDirectory),
    'drafts',
  );

  // ═══════════════════════════════════════════════════
  // 旧接口兼容（标记为 deprecated）
  // ═══════════════════════════════════════════════════

  /// @deprecated 使用 contractContentFile(sessionId:, workDirectory:) 代替
  static String contractContentFileLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'contract_content.md');

  /// @deprecated 使用 contractProcessFile(sessionId:, workDirectory:) 代替
  static String contractProcessFileLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'contract_process.md');

  /// @deprecated 使用 contractDisgussFile(sessionId:, workDirectory:) 代替
  static String contractDisgussFileLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'contract_disguss.md');

  /// @deprecated 使用 noteFile(sessionId:, workMode:, workDirectory:) 代替
  static String noteFileLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'note.md');

  /// @deprecated 使用 invoiceSummaryFile(sessionId:, workDirectory:) 代替
  static String invoiceSummaryFileLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'invoice_summary.md');

  /// @deprecated 使用 invoiceDetailFile(sessionId:, workDirectory:) 代替
  static String invoiceDetailFileLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'invoice_detail.md');

  /// @deprecated 使用 reimbursementFile(sessionId:, workDirectory:) 代替
  static String reimbursementFileLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'reimbursement.md');

  /// @deprecated 使用 rolesDir(sessionId:, workDirectory:) 代替
  static String rolesDirLegacy(String sessionId) =>
      p.join(sessionDir(sessionId), 'roles');

  /// @deprecated 使用 roleFile(sessionId:, roleName:, workDirectory:) 代替
  static String roleFileLegacy(String sessionId, String roleName) =>
      p.join(rolesDirLegacy(sessionId), '$roleName.md');

  // ═══════════════════════════════════════════════════
  // 通用工具
  // ═══════════════════════════════════════════════════

  /// 确保根目录存在
  static Future<void> ensureRoot() async {
    await Directory(root).create(recursive: true);
  }

  /// 确保 MCPs 目录存在
  static Future<void> ensureMcpsDir() async {
    await Directory(mcpsDir).create(recursive: true);
  }

  /// 确保 SSL 目录存在
  static Future<void> ensureSslDir() async {
    await Directory(sslDir).create(recursive: true);
  }

  /// 确保会话目录存在
  static Future<void> ensureSessionDir(String sessionId) async {
    await Directory(sessionDir(sessionId)).create(recursive: true);
  }

  /// 列出所有会话目录名（sessionId）
  static Future<List<String>> listSessionIds() async {
    final chats = Directory(chatsDir);
    if (!await chats.exists()) return [];
    final entries = await chats.list().toList();
    return entries
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList();
  }

  /// 迁移模式文件：从会话目录迁移到工作目录
  ///
  /// 当用户设置工作目录时，将已有的模式文件从会话目录移动到工作目录。
  /// 支持的模式：contract, invoice, chatroom, creative
  static Future<void> migrateModeFiles({
    required String sessionId,
    required String workDirectory,
  }) async {
    final modes = ['contract', 'invoice', 'chatroom', 'creative'];

    for (final mode in modes) {
      final srcDir = modeDir(sessionId: sessionId, workMode: mode);
      final dstDir = modeDir(
        sessionId: sessionId,
        workMode: mode,
        workDirectory: workDirectory,
      );

      final src = Directory(srcDir);
      if (!await src.exists()) continue;

      // 检查源目录是否有实际文件
      final srcFiles = await src.list(recursive: true).toList();
      final hasSrcFiles = srcFiles.any((e) => e is File);
      if (!hasSrcFiles) continue;

      // 确保目标目录存在
      await Directory(dstDir).create(recursive: true);

      // 复制所有文件
      await for (final entity in src.list(recursive: true)) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: srcDir);
          final dstFile = File(p.join(dstDir, relativePath));
          await dstFile.parent.create(recursive: true);
          await entity.copy(dstFile.path);
        }
      }

      // 删除源目录
      await src.delete(recursive: true);
    }
  }
}
