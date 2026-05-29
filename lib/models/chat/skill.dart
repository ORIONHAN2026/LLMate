/// AI Skill 模型
///
/// 表示一个可被 AI 调用的技能/能力，包含：
/// - 技能元信息（名称、描述、图标）
/// - 系统提示词（注入到对话上下文中）
class Skill {
  final String id;
  final String name;
  final String description;
  final String prompt; // 注入到 system prompt 中的提示内容
  final String icon; // 图标名称（如 'code', 'search', 'image' 等）
  final DateTime createdAt;
  final DateTime updatedAt;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.prompt,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 生成唯一的技能 ID
  static String generateSkillId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'skill_${timestamp}_$random';
  }

  /// 创建新的技能
  static Skill create({
    required String name,
    required String description,
    required String prompt,
    String icon = 'star',
  }) {
    final now = DateTime.now();
    return Skill(
      id: generateSkillId(),
      name: name,
      description: description,
      prompt: prompt,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 复制并修改部分字段
  Skill copyWith({
    String? id,
    String? name,
    String? description,
    String? prompt,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prompt: prompt ?? this.prompt,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取预设技能列表
  static List<Skill> getPresetSkills() {
    return [
      Skill.create(
        name: '代码助手',
        description: '帮助编写、解释和调试代码',
        prompt: '你是一个专业的代码助手，擅长编写高质量代码、解释技术概念和调试问题。请提供详细、准确的代码示例和解释。',
        icon: 'code',
      ),
      Skill.create(
        name: '翻译专家',
        description: '高质量多语言翻译',
        prompt: '你是一个专业的翻译专家，精通多种语言之间的互译。请提供准确、自然、符合语境的高质量翻译。',
        icon: 'globe',
      ),
      Skill.create(
        name: '写作助手',
        description: '帮助撰写和润色各类文本',
        prompt: '你是一个专业的写作助手，擅长帮助用户撰写、润色和改进各类文本，包括文章、邮件、报告等。请提供清晰、有条理、风格恰当的文本。',
        icon: 'pencil',
      ),
      Skill.create(
        name: '数据分析',
        description: '帮助分析和解释数据',
        prompt: '你是一个数据分析专家，擅长从数据中提取洞察、发现规律和趋势。请提供深入的数据分析和清晰的结论。',
        icon: 'chart',
      ),
      Skill.create(
        name: '创意生成',
        description: '帮助产生创意和头脑风暴',
        prompt: '你是一个创意专家，擅长头脑风暴和产生创新想法。请提供独特、有创意的建议和解决方案。',
        icon: 'lightbulb',
      ),
      Skill.create(
        name: '文档总结',
        description: '帮助总结和提炼文档内容',
        prompt: '你是一个文档总结专家，擅长快速提炼文档核心内容、提取关键信息和生成结构化的摘要。请提供简洁、准确的总结。',
        icon: 'doc',
      ),
    ];
  }

  // JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'prompt': prompt,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // JSON 反序列化
  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] ?? generateSkillId(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      prompt: json['prompt'] ?? '',
      icon: json['icon'] ?? 'star',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Skill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Skill{id: $id, name: $name, description: $description}';
  }
}
