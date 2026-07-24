import 'package:flutter/material.dart';
import 'package:llmate/l10n/app_localizations.dart';
import 'package:llmate/controllers/mcp_controller.dart';
import 'package:llmate/models/chat/mcp.dart';

/// 弹出当前会话已绑定 MCP 的只读查看面板（不可在此新增/编辑）。
///
/// [mcpNames] 为当前会话绑定的 MCP 服务名列表（与 `~/.llmate/mcps/{name}` 对应）。
void showMcpDetailDialog(BuildContext context, List<String> mcpNames) {
  final l10n = AppLocalizations.of(context)!;
  final mcpc = McpController.instance;
  final resolved =
      mcpNames
          .map((name) => mcpc.getMcp(name))
          .where((m) => m != null)
          .cast<Mcp>()
          .toList();

  showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.link, size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.mcpBoundTitle(resolved.length),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child:
              resolved.isEmpty
                  ? Text(
                    l10n.noMcpServiceConfigured,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children:
                          resolved
                              .map((mcp) => McpDetailCard(mcp: mcp))
                              .toList(),
                    ),
                  ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.close,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 单个 MCP 的只读展示卡片
class McpDetailCard extends StatelessWidget {
  final Mcp mcp;

  const McpDetailCard({super.key, required this.mcp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel =
        mcp.url != null && mcp.url!.isNotEmpty
            ? (mcp.type?.value ?? 'url')
            : 'stdio';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mcp.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          if (mcp.description != null && mcp.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              mcp.description!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          if (mcp.tools != null && mcp.tools!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '工具 (${mcp.tools!.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 4),
            ...mcp.tools!.map(
              (t) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t.description.isNotEmpty
                            ? '${t.name}：${t.description}'
                            : t.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
