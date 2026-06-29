import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../../models/chat/mcp_config.dart';
import '../../../models/chat/skill.dart';
import '../../mcp/controllers/mcp_controller.dart';
import '../../../core/skills/skill_storage_service.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../l10n/app_localizations.dart';

/// 技能编辑页面
///
/// 功能：
/// 1. 编辑技能的 name / description / prompt（即 SKILL.md 内容）
/// 2. 输入 @ 符号时在 @ 字符位置弹出 MCP 服务 & 工具列表供选择，选中后自动插入引用
class SkillEditPage extends StatefulWidget {
  final Skill skill;

  const SkillEditPage({super.key, required this.skill});

  @override
  State<SkillEditPage> createState() => _SkillEditPageState();
}

class _SkillEditPageState extends State<SkillEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _promptController;

  bool _isSaving = false;

  // ── @ Mention 相关状态 ──
  String _mentionFilter = '';
  int _mentionAtOffset = 0;
  bool _suppressMention = false;
  Mcp? _selectedMcpService;
  OverlayEntry? _mentionOverlayEntry;
  final GlobalKey _promptFieldKey = GlobalKey();

  // MCP 数据
  List<Mcp> _mcpServices = [];
  bool _mcpLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skill.name);
    _descriptionController = TextEditingController(text: widget.skill.description);
    _promptController = TextEditingController(text: widget.skill.prompt);
    _promptController.addListener(_onPromptChanged);
    _loadMcpServices();
  }

  @override
  void dispose() {
    _promptController.removeListener(_onPromptChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    _hideMentionOverlay();
    super.dispose();
  }

  Future<void> _loadMcpServices() async {
    try {
      final mcpc = Get.find<McpController>();
      await mcpc.ensureLoaded();
      if (mounted) {
        setState(() {
          _mcpServices = mcpc.configs.toList();
          _mcpLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('加载 MCP 服务失败: $e');
      if (mounted) setState(() => _mcpLoaded = true);
    }
  }

  // ── @ Mention 检测 ──

  void _onPromptChanged() {
    if (_suppressMention) return;

    final text = _promptController.text;
    final cursorPos = _promptController.selection.baseOffset;

    if (cursorPos < 0) {
      _hideMentionOverlay();
      return;
    }

    int atPos = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      final ch = text[i];
      if (ch == '@') {
        atPos = i;
        break;
      } else if (ch == ' ' || ch == '\n' || ch == '\r') {
        break;
      }
    }

    if (atPos >= 0) {
      final filter = text.substring(atPos + 1, cursorPos);
      if (filter.contains(' ') || filter.contains('\n')) {
        _hideMentionOverlay();
        return;
      }
      _mentionFilter = filter;
      _mentionAtOffset = atPos;
      _updateMentionOverlay();
    } else {
      _hideMentionOverlay();
    }
  }

  // ── 构建过滤后的列表 ──

  List<Mcp> _buildFilteredServices() {
    final filter = _mentionFilter.toLowerCase();
    if (filter.isEmpty) return _mcpServices;
    return _mcpServices.where((mcp) =>
        mcp.name.toLowerCase().contains(filter) ||
        (mcp.description ?? '').toLowerCase().contains(filter)).toList();
  }

  List<McpToolInfo> _buildFilteredTools(Mcp mcp) {
    final filter = _mentionFilter.toLowerCase();
    final tools = mcp.tools ?? [];
    if (filter.isEmpty) return tools;
    return tools.where((t) =>
        t.name.toLowerCase().contains(filter) ||
        t.description.toLowerCase().contains(filter)).toList();
  }

  void _selectMcpService(Mcp mcp) {
    setState(() {
      _selectedMcpService = mcp;
      _mentionFilter = '';
    });
    _updateMentionOverlay();
  }

  void _backToServiceList() {
    setState(() => _selectedMcpService = null);
    _updateMentionOverlay();
  }

  // ── 插入 mention ──

  void _insertMention(String serviceName, String? toolName) {
    _suppressMention = true;

    final text = _promptController.text;
    final currentCursor = _promptController.selection.baseOffset;

    final insertText = toolName != null
        ? '@$serviceName.$toolName '
        : '@$serviceName ';

    final before = text.substring(0, _mentionAtOffset);
    final after = text.substring(currentCursor);
    final newText = '$before$insertText$after';

    _promptController.text = newText;
    final newCursorPos = _mentionAtOffset + insertText.length;
    _promptController.selection = TextSelection.collapsed(offset: newCursorPos);

    _hideMentionOverlay();
    setState(() {
      _selectedMcpService = null;
      _suppressMention = false;
    });
  }

  // ── Overlay 弹出层管理 ──

  Offset? _getAtCharGlobalPosition() {
    final textFieldContext = _promptFieldKey.currentContext;
    if (textFieldContext == null) return null;

    final textFieldBox = textFieldContext.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return null;

    RenderEditable? renderEditable;
    void findEditable(RenderObject parent) {
      parent.visitChildren((child) {
        if (child is RenderEditable) {
          renderEditable = child;
        } else {
          findEditable(child);
        }
      });
    }
    findEditable(textFieldBox);

    if (renderEditable == null) return null;

    final caretRect = renderEditable!.getLocalRectForCaret(
      TextPosition(offset: _mentionAtOffset),
    );

    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
    return renderEditable!.localToGlobal(
      caretRect.bottomLeft + Offset(0, caretRect.height),
      ancestor: overlayBox,
    );
  }

  void _updateMentionOverlay() {
    _hideMentionOverlay();
    if (!_mcpLoaded || _mcpServices.isEmpty) return;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(builder: (ctx) => _buildOverlayPopup());
    _mentionOverlayEntry = entry;
    overlay.insert(entry);
  }

  void _hideMentionOverlay() {
    _mentionOverlayEntry?.remove();
    _mentionOverlayEntry = null;
  }

  // ── 保存 ──

  Future<void> _saveSkill() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final prompt = _promptController.text;

    if (name.isEmpty) {
      SnackBarUtils.showError(context, '技能名称不能为空');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedSkill = widget.skill.copyWith(
        name: name, description: description, prompt: prompt,
      );
      await SkillStorageService.updateSkill(updatedSkill);
      if (mounted) {
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.save);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, '保存失败: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 44,
        leadingWidth: Platform.isMacOS ? 70 + 20 + 15 : 44,
        leading: Padding(
          padding: EdgeInsets.only(left: Platform.isMacOS ? 70 : 0),
          child: Transform.translate(
            offset: const Offset(0, -5),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              icon: const Icon(CupertinoIcons.back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Transform.translate(
          offset: const Offset(0, -5),
          child: Text(
            AppLocalizations.of(context)!.edit,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Transform.translate(
              offset: const Offset(0, -5),
              child: TextButton(
                onPressed: _isSaving ? null : _saveSkill,
                child: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        AppLocalizations.of(context)!.save,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('技能 ID'),
            const SizedBox(height: 4),
            _buildReadOnlyBox(widget.skill.skillId),
            const SizedBox(height: 20),

            _buildSectionLabel('技能名称'),
            const SizedBox(height: 4),
            TextField(controller: _nameController, style: const TextStyle(fontSize: 14), decoration: _buildFieldDecoration('输入技能名称')),
            const SizedBox(height: 20),

            _buildSectionLabel(AppLocalizations.of(context)!.skillDescription),
            const SizedBox(height: 4),
            TextField(controller: _descriptionController, style: const TextStyle(fontSize: 14), maxLines: 3, decoration: _buildFieldDecoration('输入技能描述')),
            const SizedBox(height: 20),

            _buildSectionLabel('Prompt（输入 @ 插入 MCP 工具引用）'),
            const SizedBox(height: 4),
            TextField(
              key: _promptFieldKey,
              controller: _promptController,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              maxLines: null,
              minLines: 10,
              decoration: _buildFieldDecoration('输入技能 Prompt，使用 @ 引入 MCP 工具'),
            ),
            const SizedBox(height: 20),

            _buildReferencedToolsSection(),
            const SizedBox(height: 20),

            _buildSectionLabel('文件路径'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _buildReadOnlyBox(p.join(widget.skill.path, 'SKILL.md'))),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36, width: 36,
                  child: IconButton(
                    onPressed: () => launchUrl(Uri.file(p.join(widget.skill.path, 'SKILL.md'))),
                    icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 16),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Overlay 弹出 popup（定位在 @ 符号位置） ──

  Widget _buildOverlayPopup() {
    final atPosition = _getAtCharGlobalPosition();
    if (atPosition == null) return const SizedBox.shrink();

    final popupWidth = 380.0;
    final popupMaxHeight = 260.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double popupLeft = atPosition.dx;
    if (popupLeft + popupWidth > screenWidth - 10) {
      popupLeft = screenWidth - popupWidth - 10;
    }
    if (popupLeft < 10) popupLeft = 10;

    double popupTop = atPosition.dy + 4;
    if (popupTop + popupMaxHeight > screenHeight - 20) {
      popupTop = atPosition.dy - popupMaxHeight - 20;
    }

    Widget content;
    if (_selectedMcpService != null) {
      content = _buildLevel2Content(_selectedMcpService!);
    } else {
      content = _buildLevel1Content();
    }

    return Positioned(
      left: popupLeft,
      top: popupTop,
      width: popupWidth,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        shadowColor: Colors.black.withOpacity(0.25),
        child: Container(
          constraints: BoxConstraints(maxHeight: popupMaxHeight),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildLevel1Content() {
    final services = _buildFilteredServices();
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('未找到匹配的 MCP 服务', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPopupHeader(icon: CupertinoIcons.link, title: '选择 MCP 服务 (${services.length})', subtitle: '@ + 关键词搜索'),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: services.length,
            itemBuilder: (ctx, index) => _buildServiceItem(services[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildLevel2Content(Mcp mcp) {
    final tools = _buildFilteredTools(mcp);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPopupHeader(icon: CupertinoIcons.hammer, title: '${mcp.name} · 工具 (${tools.length})', subtitle: '← 返回', onSubtitleTap: _backToServiceList),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: tools.length + 1,
            itemBuilder: (ctx, index) {
              if (index == 0) return _buildServiceRefItem(mcp);
              return _buildToolItem(mcp, tools[index - 1]);
            },
          ),
        ),
      ],
    );
  }

  // ── 弹出列表组件 ──

  Widget _buildPopupHeader({required IconData icon, required String title, required String subtitle, VoidCallback? onSubtitleTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          const Spacer(),
          GestureDetector(
            onTap: onSubtitleTap,
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: onSubtitleTap != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: onSubtitleTap != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Mcp mcp) {
    final toolCount = mcp.tools?.length ?? 0;
    return InkWell(
      onTap: () => _selectMcpService(mcp),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Icon(CupertinoIcons.link, size: 14, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(mcp.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (mcp.description != null && mcp.description!.isNotEmpty)
                  Text(mcp.description!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
              child: Text('$toolCount 工具', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.chevron_right, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRefItem(Mcp mcp) {
    return InkWell(
      onTap: () => _insertMention(mcp.name, null),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
              child: Icon(CupertinoIcons.link, size: 12, color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(width: 8),
            Expanded(child: Text('引用整个 @${mcp.name} 服务', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary))),
          ],
        ),
      ),
    );
  }

  Widget _buildToolItem(Mcp mcp, McpToolInfo tool) {
    return InkWell(
      onTap: () => _insertMention(mcp.name, tool.name),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
              child: Icon(CupertinoIcons.hammer, size: 12, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(tool.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (tool.description.isNotEmpty)
                  Text(tool.description, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── 通用 UI ──

  Widget _buildSectionLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)));
  }

  Widget _buildReadOnlyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
    );
  }

  InputDecoration _buildFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildReferencedToolsSection() {
    final prompt = _promptController.text;
    final references = <String>[];
    final regex = RegExp(r'@([\w\-]+)(?:\.([\w\-]+))?');
    for (final match in regex.allMatches(prompt)) {
      final serviceName = match.group(1) ?? '';
      final toolName = match.group(2);
      if (toolName != null) {
        references.add('$serviceName / $toolName');
      } else {
        references.add(serviceName);
      }
    }
    if (references.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(CupertinoIcons.link, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text('已引用 (${references.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 4, runSpacing: 4, children: references.map((ref) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
          ),
          child: Text(ref, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
        );
      }).toList()),
    ]);
  }
}
