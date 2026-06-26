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

  /// ~/.llmwork/models.json
  static String get modelsFile => p.join(root, 'models.json');

  /// ~/.llmwork/mcp.json
  static String get mcpFile => p.join(root, 'mcp.json');

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

  /// ~/.llmwork/chats/{sessionId}/skill.json
  static String skillFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'skill.json');

  /// ~/.llmwork/chats/{sessionId}/mcp.json
  static String sessionMcpFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'mcp.json');

  /// ~/.llmwork/chats/{sessionId}/business.md
  static String businessFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'business.md');

  /// ~/.llmwork/chats/{sessionId}/contract_content.md（合同要点）
  static String contractContentFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'contract_content.md');

  /// ~/.llmwork/chats/{sessionId}/contract_process.md（合同履约跟踪）
  static String contractProcessFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'contract_process.md');

  /// ~/.llmwork/chats/{sessionId}/contract_disguss.md（合同争议记录）
  static String contractDisgussFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'contract_disguss.md');

  /// ~/.llmwork/chats/{sessionId}/note.md（备忘录）
  static String noteFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'note.md');

  /// ~/.llmwork/chats/{sessionId}/invoice_summary.md（发票汇总）
  static String invoiceSummaryFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'invoice_summary.md');

  /// ~/.llmwork/chats/{sessionId}/invoice_detail.md（发票明细）
  static String invoiceDetailFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'invoice_detail.md');

  /// ~/.llmwork/chats/{sessionId}/reimbursement.md（报销记录）
  static String reimbursementFile(String sessionId) =>
      p.join(sessionDir(sessionId), 'reimbursement.md');

  /// ~/.llmwork/chats/{sessionId}/roles/（角色目录）
  static String rolesDir(String sessionId) =>
      p.join(sessionDir(sessionId), 'roles');

  /// 获取角色文件路径
  static String roleFile(String sessionId, String roleName) =>
      p.join(rolesDir(sessionId), '$roleName.md');

  /// 确保根目录存在
  static Future<void> ensureRoot() async {
    await Directory(root).create(recursive: true);
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
}
