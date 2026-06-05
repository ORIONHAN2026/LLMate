import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/skill_service.dart';
import '../utils/snackbar_utils.dart';

/// 技能市场条目
class _SkillMarketItem {
  final String name;
  final String description;
  final String prompt;
  final String category;
  final String emoji;

  const _SkillMarketItem({
    required this.name,
    required this.description,
    required this.prompt,
    required this.category,
    required this.emoji,
  });
}

/// 技能应用市场页面
///
/// 展示可用的预置技能，支持按分类筛选和搜索，
/// 点击可查看详情并安装到本地。
class SkillMarketplacePage extends StatefulWidget {
  const SkillMarketplacePage({super.key});

  @override
  State<SkillMarketplacePage> createState() => _SkillMarketplacePageState();
}

class _SkillMarketplacePageState extends State<SkillMarketplacePage> {
  final _searchController = TextEditingController();
  String _selectedCategory = '全部';
  List<_SkillMarketItem> _filteredItems = [];
  List<String> _installedSkillIds = [];

  static const List<String> _categories = [
    '全部',
    '代码开发',
    '内容创作',
    '数据分析',
    '效率工具',
    '学习助手',
    '其他',
  ];

  static const List<_SkillMarketItem> _allItems = [
    // ── 代码开发 ──
    _SkillMarketItem(
      name: '代码审查专家',
      description: '专业的代码审查助手，帮你发现代码中的 Bug、性能问题和安全隐患',
      category: '代码开发',
      emoji: '💻',
      prompt:
          '你是一位资深代码审查专家。请仔细审查以下代码，关注：\n'
          '1. 潜在的 Bug 和逻辑错误\n'
          '2. 性能问题和优化建议\n'
          '3. 安全漏洞和风险\n'
          '4. 代码风格和最佳实践\n'
          '5. 可维护性和可读性\n\n'
          '请给出具体的修改建议和代码示例。',
    ),
    _SkillMarketItem(
      name: '单元测试生成器',
      description: '自动为你的代码生成高质量的单元测试用例',
      category: '代码开发',
      emoji: '🔍',
      prompt:
          '你是一位测试驱动开发专家。请为提供的代码生成全面的单元测试：\n'
          '1. 覆盖正常路径和边界条件\n'
          '2. 包含异常处理测试\n'
          '3. 使用合适的测试框架和断言\n'
          '4. 测试用例命名清晰、描述准确\n'
          '5. 提供 mock 和 stub 的示例',
    ),
    _SkillMarketItem(
      name: '代码重构顾问',
      description: '分析代码结构，提供重构方案，提升代码质量和可维护性',
      category: '代码开发',
      emoji: '⚙️',
      prompt:
          '你是一位软件架构和代码重构专家。分析以下代码后请提供：\n'
          '1. 识别代码异味（Code Smells）\n'
          '2. 建议合适的设计模式\n'
          '3. 提供逐步重构方案\n'
          '4. 评估重构的风险和收益\n'
          '5. 给出重构前后的对比示例\n\n'
          '请确保重构建议符合 SOLID 原则。',
    ),
    _SkillMarketItem(
      name: 'API 文档生成器',
      description: '根据代码自动生成清晰、专业的 API 文档',
      category: '代码开发',
      emoji: '📄',
      prompt:
          '你是一位技术文档撰写专家。请根据提供的代码生成 API 文档：\n'
          '1. 接口概述和用途说明\n'
          '2. 请求方法和 URL 路径\n'
          '3. 请求参数表格（名称、类型、必填、说明）\n'
          '4. 响应格式和字段说明\n'
          '5. 请求/响应示例\n'
          '6. 错误码说明\n\n'
          '使用 Markdown 格式输出。',
    ),
    _SkillMarketItem(
      name: 'SQL 优化专家',
      description: '分析 SQL 查询语句，提供索引建议和性能优化方案',
      category: '代码开发',
      emoji: '📊',
      prompt:
          '你是一位数据库性能优化专家。分析以下 SQL 查询并提供优化建议：\n'
          '1. 分析执行计划和瓶颈\n'
          '2. 推荐合适的索引策略\n'
          '3. 优化查询语句结构\n'
          '4. 考虑分库分表方案\n'
          '5. 评估优化后的性能提升\n\n'
          '请给出具体的优化前后 SQL 对比。',
    ),

    // ── 内容创作 ──
    _SkillMarketItem(
      name: '文案大师',
      description: '撰写各类营销文案、广告语、产品描述，提升转化率',
      category: '内容创作',
      emoji: '✏️',
      prompt:
          '你是一位资深文案策划和营销专家。撰写文案时请关注：\n'
          '1. 明确目标受众和核心卖点\n'
          '2. 使用 AIDA 模型（注意-兴趣-欲望-行动）\n'
          '3. 融入情感触发点和痛点共鸣\n'
          '4. 提供多个版本供选择（简短/详细/创意）\n'
          '5. 优化 SEO 关键词布局\n\n'
          '语言风格：简洁有力，引人入胜。',
    ),
    _SkillMarketItem(
      name: '翻译与本地化',
      description: '多语言翻译专家，支持中英日韩等多语种互译，保留原文风格',
      category: '内容创作',
      emoji: '🌐',
      prompt:
          '你是一位专业的翻译和本地化专家。翻译时请注意：\n'
          '1. 准确传达原文含义，避免逐字翻译\n'
          '2. 保留原文的语气和风格\n'
          '3. 适当处理文化差异和习语\n'
          '4. 术语保持一致性\n'
          '5. 提供翻译说明（如有需要）\n\n'
          '对于专业文档，请标注专业术语的翻译依据。',
    ),
    _SkillMarketItem(
      name: '故事创作家',
      description: '创作引人入胜的故事、剧本和创意叙事内容',
      category: '内容创作',
      emoji: '🪄',
      prompt:
          '你是一位富有想象力的故事创作者。创作时请注意：\n'
          '1. 构建引人入胜的开头和冲突\n'
          '2. 塑造立体的人物角色\n'
          '3. 运用五感描写增强画面感\n'
          '4. 保持节奏感，张弛有度\n'
          '5. 结尾有深意或反转\n\n'
          '可根据提供的主题、角色或场景展开创作。',
    ),

    // ── 数据分析 ──
    _SkillMarketItem(
      name: '数据分析师',
      description: '分析数据趋势，生成洞察报告，辅助决策制定',
      category: '数据分析',
      emoji: '📊',
      prompt:
          '你是一位资深数据分析师。分析数据时请关注：\n'
          '1. 数据质量检查和清洗建议\n'
          '2. 关键指标和趋势分析\n'
          '3. 相关性分析和因果推断\n'
          '4. 异常值检测和解释\n'
          '5. 可操作的业务建议\n\n'
          '输出格式：使用图表描述 + 文字分析，重点突出 insights。',
    ),
    _SkillMarketItem(
      name: '论文润色助手',
      description: '帮助润色学术论文，改善句式结构，提升学术表达水平',
      category: '学习助手',
      emoji: '📄',
      prompt:
          '你是一位学术写作辅导专家。润色论文时请注意：\n'
          '1. 改善句式结构，避免中式英语\n'
          '2. 使用更精确的学术词汇\n'
          '3. 确保逻辑连贯和段落过渡\n'
          '4. 检查语法和拼写错误\n'
          '5. 保持原意不变\n\n'
          '请在修改后标注主要改动和修改原因。',
    ),
    _SkillMarketItem(
      name: '学习规划师',
      description: '根据学习目标定制个性化学习计划和进度管理',
      category: '学习助手',
      emoji: '💡',
      prompt:
          '你是一位专业的学习规划教练。制定计划时请考虑：\n'
          '1. 分析学习者的当前水平和目标\n'
          '2. 分解学习目标为可执行的里程碑\n'
          '3. 推荐合适的学习资源和工具\n'
          '4. 制定周/月度时间安排\n'
          '5. 设置检验学习效果的节点\n\n'
          '确保计划具有可操作性和弹性调整空间。',
    ),

    // ── 效率工具 ──
    _SkillMarketItem(
      name: '会议纪要助手',
      description: '将会议内容整理为结构化纪要，提取关键决策和行动项',
      category: '效率工具',
      emoji: '📝',
      prompt:
          '你是一位专业的会议秘书。整理会议纪要时请遵循：\n'
          '1. 基本信息：日期、参会人、议题\n'
          '2. 讨论要点：按议题分条归纳\n'
          '3. 决策事项：明确标注已达成共识的决定\n'
          '4. 行动项：负责人 + 截止日期 + 具体任务\n'
          '5. 遗留问题：待后续讨论的事项\n\n'
          '格式清晰，层次分明，便于追踪执行。',
    ),
    _SkillMarketItem(
      name: '周报生成器',
      description: '根据工作内容自动生成结构化周报，突出成果和计划',
      category: '效率工具',
      emoji: '📋',
      prompt:
          '你是一位职场沟通专家。生成周报时请按照以下结构：\n'
          '1. 本周亮点：1-2 句话概括最大成就\n'
          '2. 完成事项：按项目/任务分类列出\n'
          '3. 数据指标：量化成果，突出关键数字\n'
          '4. 问题与挑战：遇到的困难及解决方案\n'
          '5. 下周计划：明确优先级和预期产出\n\n'
          '语言精练专业，重点突出，便于管理层快速阅读。',
    ),
    _SkillMarketItem(
      name: '头脑风暴引导者',
      description: '引导创意发散思维，结构化整理点子，辅助方案形成',
      category: '效率工具',
      emoji: '🧠',
      prompt:
          '你是一位创意引导和设计思维专家。进行头脑风暴时：\n'
          '1. 使用 SCAMPER 等创新方法提问引导\n'
          '2. 鼓励发散思维，不做批判\n'
          '3. 对观点进行归类和关联\n'
          '4. 帮助筛选和优先级排序\n'
          '5. 汇总形成可执行的概念方案\n\n'
          '保持积极、开放的态度，激发创造力。',
    ),
    _SkillMarketItem(
      name: 'PPT 内容策划',
      description: '帮你规划 PPT 大纲和每一页的内容要点，让演示更有说服力',
      category: '效率工具',
      emoji: '🖼️',
      prompt:
          '你是一位演示设计专家。策划 PPT 时请关注：\n'
          '1. 明确演示目标和受众分析\n'
          '2. 设计叙事主线（问题→方案→证据→行动）\n'
          '3. 每页一个核心观点，不超过 3 个要点\n'
          '4. 推荐合适的数据可视化方式\n'
          '5. 开场和结尾的设计建议\n\n'
          '输出包含完整的页面标题和内容要点。',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInstalledSkills();
    _filter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledSkills() async {
    await SkillService.ensureLoaded();
    if (mounted) {
      setState(() {
        _installedSkillIds =
            SkillService.skills.map((s) => s.name).toList();
      });
    }
  }

  void _filter() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchSearch = _searchController.text.isEmpty ||
            item.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
            item.description.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
        final matchCategory =
            _selectedCategory == '全部' || item.category == _selectedCategory;
        return matchSearch && matchCategory;
      }).toList();
    });
  }

  void _showDetailSheet(_SkillMarketItem item) {
    final isInstalled = _installedSkillIds.contains(item.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                '系统提示词',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.prompt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFFD4D4D4),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: isInstalled
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _uninstallSkill(item.name);
                        },
                        icon: const Icon(CupertinoIcons.delete, size: 16),
                        label: const Text('卸载技能'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _installSkill(item);
                        },
                        icon: const Icon(CupertinoIcons.plus, size: 16),
                        label: const Text('安装技能'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _installSkill(_SkillMarketItem item) async {
    try {
      await SkillService.addSkill(
        name: item.name,
        description: item.description,
        prompt: item.prompt,
        icon: _deriveIconKey(item.emoji),
      );
      await _loadInstalledSkills();
      if (mounted) {
        SnackBarUtils.showSuccess(context, '已安装技能: ${item.name}');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '安装失败: $e');
      }
    }
  }

  Future<void> _uninstallSkill(String name) async {
    try {
      final skill = SkillService.skills.firstWhere(
        (s) => s.name == name,
      );
      await SkillService.deleteSkill(skill.skillId);
      await _loadInstalledSkills();
      if (mounted) {
        SnackBarUtils.showInfo(context, '已卸载技能: $name');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '卸载失败: $e');
      }
    }
  }

  String _deriveIconKey(String emoji) {
    const map = {
      '💻': 'code',
      '🔍': 'search',
      '⚙️': 'gear',
      '📄': 'doc',
      '📊': 'chart',
      '✏️': 'pencil',
      '🌐': 'globe',
      '🪄': 'wand',
      '💡': 'lightbulb',
      '📝': 'pencil',
      '📋': 'doc',
      '🧠': 'lightbulb',
      '🖼️': 'image',
    };
    return map[emoji] ?? 'star';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('技能应用市场'),
      ),
      body: Column(
        children: [
          // 搜索和分类
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _filter(),
                  decoration: InputDecoration(
                    hintText: '搜索技能...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              CupertinoIcons.clear,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filter();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      final sel = c == _selectedCategory;
                      return FilterChip(
                        label: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            color: sel ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) {
                          _selectedCategory = c;
                          _filter();
                        },
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        selectedColor:
                            Theme.of(context).colorScheme.primary,
                        checkmarkColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 列表（2列网格）
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      '没有找到相关技能',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.6,
                        ),
                    itemCount: _filteredItems.length,
                    itemBuilder: (_, i) =>
                        _buildItemCard(_filteredItems[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(_SkillMarketItem item) {
    final isInstalled = _installedSkillIds.contains(item.name);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetailSheet(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧图标
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                // 中间：名称 + 描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 右侧按钮
                GestureDetector(
                  onTap: () {
                    if (isInstalled) {
                      _uninstallSkill(item.name);
                    } else {
                      _installSkill(item);
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isInstalled
                            ? Colors.transparent
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.15),
                      ),
                      color: isInstalled
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : null,
                    ),
                    child: Icon(
                      isInstalled
                          ? CupertinoIcons.checkmark_alt
                          : CupertinoIcons.plus,
                      size: 13,
                      color: isInstalled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
