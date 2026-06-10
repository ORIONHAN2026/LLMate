import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../chat/chat_setting.dart';
import '../chat/skill.dart';
import '../chat/mcp_config.dart';

/// 聊天模型数据结构
class ChatModel {
  final String modelId; // 唯一标识符
  final String name;
  final String model; // API调用时使用的模型名称
  final String status; // 'active', 'inactive'
  final String? description;
  final String? type; // 'local', 'online'
  final String? provider; // 提供商：deepseek, openai, anthropic等
  final String? platform; // 平台展示名称，如：阿里云百炼、DeepSeek、OpenAI等
  final String? apiKey;
  final String? apiUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 对话设置 - 使用ChatSettings对象
  final ChatSettings? chatSettings;

  // MCP服务列表 - 模型绑定的MCP服务配置
  final List<Mcp>? mcpServices;

  // 快捷指令列表 - 模型绑定的快捷指令配置
  final List<ChatCommand>? chatCommands;

  // Skill 技能列表 - 模型绑定的技能配置
  final List<Skill>? skills;

  const ChatModel({
    required this.modelId,
    required this.name,
    required this.model,
    required this.status,
    this.description,
    this.type,
    this.provider,
    this.platform,
    this.apiKey,
    this.apiUrl,
    this.createdAt,
    this.updatedAt,
    this.chatSettings,
    this.mcpServices,
    this.chatCommands,
    this.skills,
  });

  /// 生成唯一的模型ID
  static String generateModelId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'model_${timestamp}_$random';
  }

  /// 从 Map 创建 ChatModel
  factory ChatModel.fromMap(Map<String, dynamic> map) {
    // 处理对话设置 - 兼容旧数据和新数据
    ChatSettings? settings;
    if (map['chatSettings'] != null) {
      // 新格式：有 chatSettings 对象
      settings = ChatSettings.fromJson(map['chatSettings']);
    } else if (map['temperature'] != null ||
        map['systemPrompt'] != null ||
        map['replyLanguage'] != null) {
      // 旧格式：有独立的设置字段，转换为 ChatSettings
      settings = ChatSettings(
        conversationName: '模型默认设置',
        systemPrompt: map['systemPrompt'] ?? '',
        temperature: map['temperature']?.toDouble() ?? 1.0,

        replyLanguage: map['replyLanguage'] ?? '助手设置（默认）',
      );
    }

    return ChatModel(
      modelId: map['modelId'] ?? generateModelId(), // 如果没有modelId则生成新的
      name: map['name'] ?? '',
      model: map['model'] ?? map['fullName'] ?? '', // 兼容旧数据的fullName字段
      status: map['status'] ?? 'inactive',
      description: map['description'],
      type: map['type'],
      provider: map['provider'],
      platform: map['platform'] ?? _resolvePlatformName(map['provider']),
      apiKey: map['apiKey'],
      apiUrl: map['apiUrl'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      chatSettings: settings,
      mcpServices:
          map['mcpServices'] != null
              ? (map['mcpServices'] as List)
                  .where((item) => item != null) // 过滤掉空项
                  .map((item) {
                    try {
                      return Mcp.fromJson(
                        item['name'] ?? '',
                        item is Map<String, dynamic>
                            ? item
                            : Map<String, dynamic>.from(item),
                      );
                    } catch (e) {
                      print('Error parsing MCP service config: $e');
                      print('Item data: $item');
                      // 返回一个默认配置而不是抛出异常
                      return Mcp(
                        mcpId: item['name'] ?? 'unknown',
                        name: item['name'] ?? 'unknown',
                        command: '',
                        args: [],
                      );
                    }
                  })
                  .toList()
              : null,
      chatCommands:
          map['chatCommands'] != null
              ? (map['chatCommands'] as List)
                  .where((item) => item != null) // 过滤掉空项
                  .map((item) {
                    try {
                      return ChatCommand.fromJson(
                        item is Map<String, dynamic>
                            ? item
                            : Map<String, dynamic>.from(item),
                      );
                    } catch (e) {
                      print('Error parsing chat command: $e');
                      print('Item data: $item');
                      // 返回一个默认配置而不是抛出异常
                      return ChatCommand.create(
                        name: item['name'] ?? '未知指令',
                        content: item['content'] ?? '',
                        icon: item['icon'] ?? '💬',
                      );
                    }
                  })
                  .toList()
              : null,
      skills:
          map['skills'] != null
              ? (map['skills'] as List).where((item) => item != null).map((
                item,
              ) {
                try {
                  return Skill.fromJson(
                    item is Map<String, dynamic>
                        ? item
                        : Map<String, dynamic>.from(item),
                  );
                } catch (e) {
                  print('Error parsing skill: $e');
                  print('Item data: $item');
                  final now = DateTime.now();
                  return Skill(
                    skillId: item['id'] ?? '',
                    name: item['name'] ?? '未知技能',
                    description: item['description'] ?? '',
                    prompt: item['prompt'] ?? '',
                    icon: item['icon'] ?? 'star',
                    createdAt: now,
                    updatedAt: now,
                    path: '',
                  );
                }
              }).toList()
              : null,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'modelId': modelId,
      'name': name,
      'model': model,
      'status': status,
      'description': description,
      'type': type,
      'provider': provider,
      'platform': platform,
      'apiKey': apiKey,
      'apiUrl': apiUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };

    // 保存 ChatSettings 对象
    if (chatSettings != null) {
      result['chatSettings'] = chatSettings!.toJson();
    }

    // 保存 MCP 服务列表（含工具缓存等内部字段）
    if (mcpServices != null) {
      result['mcpServices'] =
          mcpServices!.map((service) => service.toFullJson()).toList();
    }

    // 保存快捷指令列表
    if (chatCommands != null) {
      result['chatCommands'] =
          chatCommands!.map((command) => command.toJson()).toList();
    }

    // 保存技能列表
    if (skills != null) {
      result['skills'] = skills!.map((skill) => skill.toJson()).toList();
    }

    return result;
  }

  /// 从 JSON 字符串创建 ChatModel
  factory ChatModel.fromJson(String source) =>
      ChatModel.fromMap(json.decode(source));

  /// 转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 创建空的 ChatModel 实例
  static ChatModel empty() {
    return ChatModel(
      modelId: "",
      name: '请设置',
      model: '未设置对话大模型',
      status: 'inactive',
    );
  }

  /// 创建新的 ChatModel 实例（带自动生成的ID）
  static ChatModel create({
    required String name,
    required String model,
    String status = 'inactive',
    String? businessType,
    String? description,
    String? type,
    String? provider,
    String? platform,
    String? apiKey,
    String? apiUrl,
    ChatSettings? chatSettings,
  }) {
    return ChatModel(
      modelId: generateModelId(),
      name: name,
      model: model,
      status: status,
      description: description,
      type: type,
      provider: provider,
      platform: platform ?? _resolvePlatformName(provider),
      apiKey: apiKey,
      apiUrl: apiUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      chatSettings: chatSettings,
      mcpServices: null, // 新模型默认没有MCP服务
      chatCommands: null, // 新模型默认没有快捷指令
      skills: null, // 新模型默认没有技能
    );
  }

  /// 复制并修改部分字段
  ChatModel copyWith({
    String? modelId,
    String? name,
    String? model,
    String? status,
    String? businessType,
    String? description,
    String? type,
    String? provider,
    String? platform,
    String? apiKey,
    String? apiUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatSettings? chatSettings,
    List<Mcp>? mcpServices,
    List<ChatCommand>? chatCommands,
    List<Skill>? skills,
  }) {
    return ChatModel(
      modelId: modelId ?? this.modelId,
      name: name ?? this.name,
      model: model ?? this.model,
      status: status ?? this.status,
      description: description ?? this.description,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      platform: platform ?? this.platform,
      apiKey: apiKey ?? this.apiKey,
      apiUrl: apiUrl ?? this.apiUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chatSettings: chatSettings ?? this.chatSettings,
      mcpServices: mcpServices ?? this.mcpServices,
      chatCommands: chatCommands ?? this.chatCommands,
      skills: skills ?? this.skills,
    );
  }

  /// 是否为在线模型
  bool get isOnlineModel => type == 'online';

  /// 是否为本地模型
  bool get isLocalModel => type == 'local' || type == null;

  /// 是否为活跃状态
  bool get isActive => status == 'active';

  /// 获取显示名称（如果有自定义名称则使用自定义名称，否则使用模型名称）
  String get displayName => name.isNotEmpty ? name : model;

  /// 根据模型名称或提供商获取对应的图标路径
  String? getIconPath() {
    final lowercaseName = displayName.toLowerCase();

    // 优先根据 provider 判断
    if (provider != null) {
      final lowercaseProvider = provider!.toLowerCase();
      if (lowercaseProvider == 'deepseek') {
        return 'assets/icons/deepseek-color.webp';
      } else if (lowercaseProvider == 'anthropic') {
        return 'assets/icons/claude-color.webp';
      } else if (lowercaseProvider == 'openai') {
        return 'assets/icons/openai.webp';
      } else if (lowercaseProvider == 'google') {
        return 'assets/icons/gemini-color.webp';
      } else if (lowercaseProvider == 'qwen' ||
          lowercaseProvider == 'tongyi' ||
          lowercaseProvider == 'alibaba') {
        return 'assets/icons/qwen-color.webp';
      } else if (lowercaseProvider == 'zhipu' ||
          lowercaseProvider == 'bytedance') {
        return 'assets/icons/yuanbao-color.webp';
      } else if (lowercaseProvider == 'modelscope') {
        return 'assets/icons/qwen-color.webp';
      } else if (lowercaseProvider == 'ollama') {
        return 'assets/icons/ollama.webp';
      }
    }

    // 如果没有provider或者provider匹配失败，根据模型名称推测
    if (lowercaseName.contains('deepseek') || lowercaseName.contains('r1')) {
      return 'assets/icons/deepseek-color.webp';
    } else if (lowercaseName.contains('claude') ||
        lowercaseName.contains('anthropic')) {
      return 'assets/icons/claude-color.webp';
    } else if (lowercaseName.contains('gpt') ||
        lowercaseName.contains('openai')) {
      return 'assets/icons/openai.webp';
    } else if (lowercaseName.contains('gemini') ||
        lowercaseName.contains('bard') ||
        lowercaseName.contains('google')) {
      return 'assets/icons/gemini-color.webp';
    } else if (lowercaseName.contains('qwen') ||
        lowercaseName.contains('tongyi') ||
        lowercaseName.contains('baichuan') ||
        lowercaseName.contains('chatglm') ||
        lowercaseName.contains('yi-') ||
        lowercaseName.contains('deepseek-v3') ||
        lowercaseName.contains('doubao-') ||
        lowercaseName.contains('internlm2.5')) {
      return 'assets/icons/qwen-color.webp';
    } else if (lowercaseName.contains('yuanbao') ||
        lowercaseName.contains('元宝') ||
        lowercaseName.contains('glm') ||
        lowercaseName.contains('zhipu')) {
      return 'assets/icons/yuanbao-color.webp';
    } else if (lowercaseName.contains('ollama')) {
      return 'assets/icons/ollama.webp';
    }

    return null; // 没有匹配的图标
  }

  /// 根据 provider ID 解析出平台中文展示名称
  static String? _resolvePlatformName(String? providerId) {
    if (providerId == null) return null;
    final p = ModelProvider.fromString(providerId);
    return p?.displayName ?? providerId;
  }

  @override
  String toString() {
    return 'ChatModel(modelId: $modelId, name: $name, model: $model, status: $status, type: $type, provider: $provider)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatModel && other.modelId == modelId; // 使用 modelId 作为唯一标识
  }

  @override
  int get hashCode {
    return modelId.hashCode; // 使用 modelId 的 hashCode
  }

  /// 构建模型图标Widget
  Widget buildIconWidget(bool isSelected, {double size = 16}) {
    final iconPath = getIconPath();

    if (iconPath != null) {
      return Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            getIconData(),
            size: size,
            color: isSelected ? Colors.white : getIconColor(),
          );
        },
      );
    } else {
      return Icon(
        getIconData(),
        size: size,
        color: isSelected ? Colors.white : getIconColor(),
      );
    }
  }

  /// 根据模型名称获取对应的图标
  IconData getIconData() {
    final lowercaseName = displayName.toLowerCase();

    if (lowercaseName.contains('deepseek') || lowercaseName.contains('r1')) {
      return CupertinoIcons.person_crop_circle;
    } else if (lowercaseName.contains('gpt') ||
        lowercaseName.contains('openai')) {
      return CupertinoIcons.chat_bubble_2;
    } else if (lowercaseName.contains('claude')) {
      return CupertinoIcons.person_crop_circle_badge_checkmark;
    } else if (lowercaseName.contains('gemini') ||
        lowercaseName.contains('bard')) {
      return CupertinoIcons.star;
    } else if (lowercaseName.contains('llama') ||
        lowercaseName.contains('meta')) {
      return CupertinoIcons.time;
    } else if (lowercaseName.contains('qwen') ||
        lowercaseName.contains('tongyi')) {
      return CupertinoIcons.cloud;
    } else if (lowercaseName.contains('chatglm') ||
        lowercaseName.contains('glm')) {
      return CupertinoIcons.bolt;
    } else if (lowercaseName.contains('baichuan')) {
      return CupertinoIcons.tree;
    } else if (lowercaseName.contains('wenxin') ||
        lowercaseName.contains('ernie')) {
      return CupertinoIcons.clear;
    } else if (lowercaseName.contains('spark') ||
        lowercaseName.contains('讯飞')) {
      return CupertinoIcons.time;
    } else {
      return CupertinoIcons.chat_bubble;
    }
  }

  /// 根据模型名称获取对应的图标颜色
  Color getIconColor() {
    final lowercaseName = displayName.toLowerCase();

    if (lowercaseName.contains('deepseek') || lowercaseName.contains('r1')) {
      return const Color(0xFF6366F1);
    } else if (lowercaseName.contains('gpt') ||
        lowercaseName.contains('openai')) {
      return const Color(0xFF10B981);
    } else if (lowercaseName.contains('claude')) {
      return const Color(0xFFF59E0B);
    } else if (lowercaseName.contains('gemini') ||
        lowercaseName.contains('bard')) {
      return const Color(0xFF3B82F6);
    } else if (lowercaseName.contains('llama') ||
        lowercaseName.contains('meta')) {
      return const Color(0xFFEF4444);
    } else if (lowercaseName.contains('qwen') ||
        lowercaseName.contains('tongyi')) {
      return const Color(0xFF8B5CF6);
    } else if (lowercaseName.contains('chatglm') ||
        lowercaseName.contains('glm')) {
      return const Color(0xFF06B6D4);
    } else if (lowercaseName.contains('baichuan')) {
      return const Color(0xFF84CC16);
    } else if (lowercaseName.contains('wenxin') ||
        lowercaseName.contains('ernie')) {
      return const Color(0xFFF97316);
    } else if (lowercaseName.contains('spark') ||
        lowercaseName.contains('讯飞')) {
      return const Color(0xFFEC4899);
    } else {
      return Colors.grey[600]!;
    }
  }

  // ========== MCP 服务管理方法 ==========

  /// 添加 MCP 服务配置
  ChatModel addMcpService(Mcp service) {
    final currentServices = mcpServices?.toList() ?? <Mcp>[];
    // 检查是否已存在同名服务
    if (!currentServices.any((s) => s.name == service.name)) {
      currentServices.add(service);
    }
    return copyWith(mcpServices: currentServices);
  }

  /// 移除 MCP 服务配置
  ChatModel removeMcpService(String serviceName) {
    final currentServices = mcpServices?.toList() ?? <Mcp>[];
    currentServices.removeWhere((s) => s.name == serviceName);
    return copyWith(mcpServices: currentServices);
  }

  /// 更新 MCP 服务配置
  ChatModel updateMcpService(String serviceName, Mcp newService) {
    final currentServices = mcpServices?.toList() ?? <Mcp>[];
    final index = currentServices.indexWhere((s) => s.name == serviceName);
    if (index != -1) {
      currentServices[index] = newService;
    }
    return copyWith(mcpServices: currentServices);
  }

  /// 获取指定名称的 MCP 服务配置
  Mcp? getMcpService(String serviceName) {
    return mcpServices?.firstWhere(
      (s) => s.name == serviceName,
      orElse: () => throw StateError('Service not found'),
    );
  }

  /// 检查是否存在指定的 MCP 服务
  bool hasMcpService(String serviceName) {
    return mcpServices?.any((s) => s.name == serviceName) ?? false;
  }

  /// 获取所有 MCP 服务名称
  List<String> getMcpServiceNames() {
    return mcpServices?.map((s) => s.name).toList() ?? [];
  }

  /// 清空所有 MCP 服务配置
  ChatModel clearMcpServices() {
    return copyWith(mcpServices: <Mcp>[]);
  }

  /// 从 JSON 配置批量添加 MCP 服务
  ChatModel addMcpServicesFromJson(List<Map<String, dynamic>> servicesJson) {
    final currentServices = mcpServices?.toList() ?? <Mcp>[];

    for (final serviceJson in servicesJson) {
      try {
        final serviceName = serviceJson['name'] as String? ?? '';
        if (serviceName.isNotEmpty) {
          final service = Mcp.fromJson(serviceName, serviceJson);
          // 检查是否已存在同名服务
          if (!currentServices.any((s) => s.name == service.name)) {
            currentServices.add(service);
          }
        }
      } catch (e) {
        // 忽略无效的配置项
        print('Invalid MCP service configuration: $e');
      }
    }

    return copyWith(mcpServices: currentServices);
  }

  /// 将 MCP 服务配置导出为标准 JSON
  List<Map<String, dynamic>> getMcpServicesJson() {
    return mcpServices?.map((service) {
          final json = service.toJson();
          json['name'] = service.name;
          return json;
        }).toList() ??
        [];
  }

  // ========== 快捷指令管理方法 ==========

  /// 添加快捷指令
  ChatModel addChatCommand(ChatCommand command) {
    final currentCommands = chatCommands?.toList() ?? <ChatCommand>[];
    // 检查是否已存在同ID指令
    if (!currentCommands.any((c) => c.id == command.id)) {
      currentCommands.add(command);
    }
    return copyWith(chatCommands: currentCommands);
  }

  /// 移除快捷指令
  ChatModel removeChatCommand(String commandId) {
    final currentCommands = chatCommands?.toList() ?? <ChatCommand>[];
    currentCommands.removeWhere((c) => c.id == commandId);
    return copyWith(chatCommands: currentCommands);
  }

  /// 更新快捷指令
  ChatModel updateChatCommand(String commandId, ChatCommand newCommand) {
    final currentCommands = chatCommands?.toList() ?? <ChatCommand>[];
    final index = currentCommands.indexWhere((c) => c.id == commandId);
    if (index != -1) {
      currentCommands[index] = newCommand;
    }
    return copyWith(chatCommands: currentCommands);
  }

  /// 获取指定ID的快捷指令
  ChatCommand? getChatCommand(String commandId) {
    return chatCommands?.firstWhere(
      (c) => c.id == commandId,
      orElse: () => throw StateError('Command not found'),
    );
  }

  /// 检查是否存在指定的快捷指令
  bool hasChatCommand(String commandId) {
    return chatCommands?.any((c) => c.id == commandId) ?? false;
  }

  /// 获取所有快捷指令ID
  List<String> getChatCommandIds() {
    return chatCommands?.map((c) => c.id).toList() ?? [];
  }

  /// 清空所有快捷指令
  ChatModel clearChatCommands() {
    return copyWith(chatCommands: <ChatCommand>[]);
  }

  /// 从 JSON 配置批量添加快捷指令
  ChatModel addChatCommandsFromJson(List<Map<String, dynamic>> commandsJson) {
    final currentCommands = chatCommands?.toList() ?? <ChatCommand>[];

    for (final commandJson in commandsJson) {
      try {
        final command = ChatCommand.fromJson(commandJson);
        // 检查是否已存在同ID指令
        if (!currentCommands.any((c) => c.id == command.id)) {
          currentCommands.add(command);
        }
      } catch (e) {
        // 忽略无效的配置项
        print('Invalid chat command configuration: $e');
      }
    }

    return copyWith(chatCommands: currentCommands);
  }

  /// 将快捷指令配置导出为 JSON
  List<Map<String, dynamic>> getChatCommandsJson() {
    return chatCommands?.map((command) => command.toJson()).toList() ?? [];
  }

  // ========== Skill 技能管理方法 ==========

  /// 添加技能
  ChatModel addSkill(Skill skill) {
    final currentSkills = skills?.toList() ?? <Skill>[];
    if (!currentSkills.any((s) => s.skillId == skill.skillId)) {
      currentSkills.add(skill);
    }
    return copyWith(skills: currentSkills);
  }

  /// 移除技能
  ChatModel removeSkill(String skillId) {
    final currentSkills = skills?.toList() ?? <Skill>[];
    currentSkills.removeWhere((s) => s.skillId == skillId);
    return copyWith(skills: currentSkills);
  }

  /// 更新技能
  ChatModel updateSkill(String skillId, Skill newSkill) {
    final currentSkills = skills?.toList() ?? <Skill>[];
    final index = currentSkills.indexWhere((s) => s.skillId == skillId);
    if (index != -1) {
      currentSkills[index] = newSkill;
    }
    return copyWith(skills: currentSkills);
  }

  /// 获取指定ID的技能
  Skill? getSkill(String skillId) {
    return skills?.firstWhere(
      (s) => s.skillId == skillId,
      orElse: () => throw StateError('Skill not found'),
    );
  }

  /// 检查是否存在指定的技能
  bool hasSkill(String skillId) {
    return skills?.any((s) => s.skillId == skillId) ?? false;
  }

  /// 获取所有技能ID
  List<String> getSkillIds() {
    return skills?.map((s) => s.skillId).toList() ?? [];
  }

  /// 清空所有技能
  ChatModel clearSkills() {
    return copyWith(skills: <Skill>[]);
  }

  /// 从 JSON 配置批量添加技能
  ChatModel addSkillsFromJson(List<Map<String, dynamic>> skillsJson) {
    final currentSkills = skills?.toList() ?? <Skill>[];
    for (final skillJson in skillsJson) {
      try {
        final skill = Skill.fromJson(skillJson);
        if (!currentSkills.any((s) => s.skillId == skill.skillId)) {
          currentSkills.add(skill);
        }
      } catch (e) {
        print('Invalid skill configuration: $e');
      }
    }
    return copyWith(skills: currentSkills);
  }

  /// 将技能配置导出为 JSON
  List<Map<String, dynamic>> getSkillsJson() {
    return skills?.map((skill) => skill.toJson()).toList() ?? [];
  }
}

/// 业务类型枚举
enum BusinessType {
  codeAnalysis('代码分析', '代码审查、调试、重构和优化建议'),
  legalQuery('法律查询', '法律条文查询、合同审查、法律咨询'),
  compliance('合规管理', '企业合规检查、风险评估、政策解读'),
  generalChat('通用对话', '日常对话、问答、知识查询'),
  documentProcessing('文档处理', '文档总结、翻译、格式转换'),
  dataAnalysis('数据分析', '数据处理、图表生成、统计分析');

  const BusinessType(this.displayName, this.description);

  final String displayName;
  final String description;

  static BusinessType? fromString(String value) {
    for (BusinessType type in BusinessType.values) {
      if (type.displayName == value) {
        return type;
      }
    }
    return null;
  }
}

/// 模型提供商枚举
enum ModelProvider {
  deepseek('deepseek', 'DeepSeek', 'https://api.deepseek.com/v1'),
  openai('openai', 'OpenAI', 'https://api.openai.com/v1'),
  anthropic('anthropic', 'Anthropic', 'https://api.anthropic.com/v1'),
  google('google', 'Google', 'https://generativelanguage.googleapis.com/v1'),
  qwen('qwen', '阿里云百炼', 'https://dashscope.aliyuncs.com/compatible-mode/v1'),
  zhipu('zhipu', '智谱AI', 'https://open.bigmodel.cn/api/paas/v4'),
  ollama('ollama', 'Ollama', 'http://127.0.0.1:11434/api');

  const ModelProvider(this.id, this.displayName, this.defaultApiUrl);

  final String id;
  final String displayName;
  final String defaultApiUrl;

  static ModelProvider? fromString(String value) {
    for (ModelProvider provider in ModelProvider.values) {
      if (provider.id == value) {
        return provider;
      }
    }
    return null;
  }

  /// 获取提供商对应的图标路径
  String? getIconPath() {
    switch (this) {
      case ModelProvider.deepseek:
        return 'assets/icons/deepseek-color.webp';
      case ModelProvider.openai:
        return 'assets/icons/openai.webp';
      case ModelProvider.anthropic:
        return 'assets/icons/claude-color.webp';
      case ModelProvider.google:
        return 'assets/icons/gemini-color.webp';
      case ModelProvider.qwen:
        return 'assets/icons/qwen-color.webp';
      case ModelProvider.zhipu:
        return 'assets/icons/yuanbao-color.webp';
      case ModelProvider.ollama:
        return 'assets/icons/ollama.webp';
    }
  }
}
