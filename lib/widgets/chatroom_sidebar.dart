import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import '../storage/storage_paths.dart';
import '../storage/file_storage.dart';

/// 聊天室模式右侧边栏内容
class ChatroomSidebar {
  /// 刷新计数器，用于强制 FutureBuilder 重新加载
  static int _refreshCounter = 0;

  /// 触发刷新
  static void refresh() {
    _refreshCounter++;
  }

  /// 获取聊天室模式的 Tab 标题列表
  /// 注意：Tab 0 是文件列表（由 chat_right_sidebar 提供），这里只返回额外的 tab 标题
  static List<String> getTabTitles() {
    return ['文件列表', '角色列表', '备忘录'];
  }

  /// 获取 Tab 数量（含文件列表）
  static int get tabCount => 3;

  /// 构建指定 Tab 的内容
  static Widget buildTabContent(BuildContext context, int index, String sessionId) {
    switch (index) {
      case 0:
        return _buildRolesTab(context, sessionId);
      case 1:
        return _buildNoteTab(context, sessionId);
      default:
        return const SizedBox.shrink();
    }
  }

  /// 角色列表 Tab
  static Widget _buildRolesTab(BuildContext context, String sessionId) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无角色', '在对话中创建角色后会自动记录');
    }

    return FutureBuilder<List<_RoleInfo>>(
      key: ValueKey('roles_${sessionId}_$_refreshCounter'),
      future: _loadRoles(sessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final roles = snapshot.data ?? [];

        if (roles.isEmpty) {
          return _buildEmptyState(context, '暂无角色', '在对话中创建角色后会自动记录');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '角色列表 (${roles.length})'),
              const SizedBox(height: 8),
              ...roles.map((role) => _buildRoleCard(context, role)),
            ],
          ),
        );
      },
    );
  }

  /// 备忘录 Tab
  static Widget _buildNoteTab(BuildContext context, String sessionId) {
    return _buildFileTab(context, sessionId, 'note.md', '备忘录');
  }

  /// 通用文件 Tab
  static Widget _buildFileTab(
    BuildContext context,
    String sessionId,
    String fileName,
    String title,
  ) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无$title', '在对话中提及相关信息时会自动记录');
    }

    return FutureBuilder<String?>(
      future: _loadFile(sessionId, fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildEmptyState(context, '暂无$title', '在对话中提及相关信息时会自动记录');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, title),
              const SizedBox(height: 8),
              MarkdownBody(
                data: content.trim(),
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  h1: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  h2: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  h3: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 加载所有角色
  static Future<List<_RoleInfo>> _loadRoles(String sessionId) async {
    final rolesDirPath = StoragePaths.rolesDir(sessionId);
    final dir = Directory(rolesDirPath);
    
    if (!await dir.exists()) return [];
    
    final roles = <_RoleInfo>[];
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final fileName = p.basenameWithoutExtension(entity.path);
        final content = await FileStorage.readText(entity.path);
        if (content != null && content.trim().isNotEmpty) {
          // 从文件头提取显示名称
          final displayNameMatch = RegExp(r'^# (.+)$', multiLine: true).firstMatch(content);
          final displayName = displayNameMatch?.group(1) ?? fileName;
          roles.add(_RoleInfo(
            name: fileName,
            displayName: displayName,
            content: content,
          ));
        }
      }
    }
    
    return roles;
  }

  /// 加载文件内容
  static Future<String?> _loadFile(String sessionId, String fileName) async {
    final path = '${StoragePaths.sessionDir(sessionId)}/$fileName';
    return FileStorage.readText(path);
  }

  /// 空状态
  static Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 章节标题
  static Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        letterSpacing: 0.3,
      ),
    );
  }

  /// 角色卡片
  static Widget _buildRoleCard(BuildContext context, _RoleInfo role) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  role.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                role.name,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 显示角色描述的前几行
          Text(
            role.content
                .replaceAll(RegExp(r'^# .+$', multiLine: true), '')
                .trim()
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .take(5)
                .join('\n'),
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 角色信息
class _RoleInfo {
  final String name;
  final String displayName;
  final String content;

  _RoleInfo({
    required this.name,
    required this.displayName,
    required this.content,
  });
}
