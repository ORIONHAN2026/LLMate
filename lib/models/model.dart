import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../controllers/model_controller.dart';

/// 聊天模型数据结构
class ChatModel {
  final String modelId; // 唯一标识符
  final String name; // 模型显示名称
  final String model; // API调用时使用的模型名称
  final String? type; // 'local', 'online'
  final String? platform; // 平台展示名称，如：阿里云百炼、DeepSeek、OpenAI等
  final String? protocol; // 协议类型：openai, anthropic, gemini
  final String? apiKey;
  final String? apiUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 输入价格（价格单位由 currency 字段决定，/百万token）
  final double? promptPrice;

  /// 输出价格（价格单位由 currency 字段决定，/百万token）
  final double? completionPrice;

  /// 货币类型：'CNY'（人民币）或 'USD'（美元），默认美元
  final String? currency;

  // 对话设置（原 ChatSettings 内容，已扁平化到 ChatModel）
  final String? conversationName;
  final String? systemPrompt;
  final double? temperature;
  final String? replyLanguage;

  /// 安全设置：开启后，请求/响应中的手机号将被 * 号脱敏
  final bool maskPhone;

  /// 安全设置：开启后，请求/响应中的身份证号将被 * 号脱敏
  final bool maskIdCard;

  const ChatModel({
    required this.modelId,
    required this.name,
    required this.model,
    this.type,
    this.platform,
    this.protocol,
    this.apiKey,
    this.apiUrl,
    this.createdAt,
    this.updatedAt,
    this.promptPrice,
    this.completionPrice,
    this.currency,
    this.conversationName,
    this.systemPrompt,
    this.temperature,
    this.replyLanguage,
    this.maskPhone = false,
    this.maskIdCard = false,
  });

  /// 生成唯一的模型ID
  static String generateModelId() {
    const uuid = Uuid();
    return 'model${uuid.v4()}';
  }

  /// 从 Map 创建 ChatModel
  factory ChatModel.fromMap(Map<String, dynamic> map) {
    // 处理对话设置 - 兼容旧数据（嵌套 chatSettings）与扁平字段
    final Map<String, dynamic>? cs =
        map['chatSettings'] is Map
            ? Map<String, dynamic>.from(map['chatSettings'] as Map)
            : null;

    return ChatModel(
      modelId: map['modelId'] ?? generateModelId(),
      name: map['name'] ?? '',
      model: map['model'] ?? map['fullName'] ?? '',
      type: map['type'],
      platform: map['platform'],
      protocol: map['protocol'],
      apiKey: map['apiKey'],
      apiUrl: map['apiUrl'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      promptPrice:
          map['promptPrice']?.toDouble() ?? map['inputPrice']?.toDouble(),
      completionPrice:
          map['completionPrice']?.toDouble() ?? map['outputPrice']?.toDouble(),
      currency: map['currency'] as String?,
      conversationName:
          cs?['conversationName'] as String? ??
          map['conversationName'] as String?,
      systemPrompt:
          cs?['systemPrompt'] as String? ?? map['systemPrompt'] as String?,
      temperature:
          (cs?['temperature'] as num?)?.toDouble() ??
          (map['temperature'] as num?)?.toDouble(),
      replyLanguage:
          cs?['replyLanguage'] as String? ?? map['replyLanguage'] as String?,
      maskPhone:
          (cs?['maskPhone'] as bool?) ?? (map['maskPhone'] as bool?) ?? false,
      maskIdCard:
          (cs?['maskIdCard'] as bool?) ?? (map['maskIdCard'] as bool?) ?? false,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'modelId': modelId,
      'name': name,
      'model': model,
      'type': type,
      'platform': platform,
      'protocol': protocol,
      'apiKey': apiKey,
      'apiUrl': apiUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      if (promptPrice != null) 'promptPrice': promptPrice,
      if (completionPrice != null) 'completionPrice': completionPrice,
      if (currency != null) 'currency': currency,
    };

    // 对话设置（扁平化字段）
    if (conversationName != null) result['conversationName'] = conversationName;
    if (systemPrompt != null) result['systemPrompt'] = systemPrompt;
    if (temperature != null) result['temperature'] = temperature;
    if (replyLanguage != null) result['replyLanguage'] = replyLanguage;
    result['maskPhone'] = maskPhone;
    result['maskIdCard'] = maskIdCard;

    return result;
  }

  /// 从 JSON 字符串创建 ChatModel
  factory ChatModel.fromJson(String source) =>
      ChatModel.fromMap(json.decode(source));

  /// 转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 创建空的 ChatModel 实例
  static ChatModel empty() {
    return const ChatModel(modelId: "", name: '请设置', model: '未设置对话大模型');
  }

  /// 创建新的 ChatModel 实例（带自动生成的ID）
  static ChatModel create({
    required String name,
    required String model,
    String? type,
    String? platform,
    String? protocol,
    String? apiKey,
    String? apiUrl,
    double? promptPrice,
    double? completionPrice,
    String? currency,
    String? conversationName,
    String? systemPrompt,
    double? temperature,
    String? replyLanguage,
    bool maskPhone = false,
    bool maskIdCard = false,
  }) {
    return ChatModel(
      modelId: generateModelId(),
      name: name,
      model: model,
      type: type,
      platform: platform,
      protocol: protocol,
      apiKey: apiKey,
      apiUrl: apiUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      promptPrice: promptPrice,
      completionPrice: completionPrice,
      currency: currency,
      conversationName: conversationName,
      systemPrompt: systemPrompt,
      temperature: temperature,
      replyLanguage: replyLanguage,
      maskPhone: maskPhone,
      maskIdCard: maskIdCard,
    );
  }

  /// 复制并修改部分字段
  ChatModel copyWith({
    String? modelId,
    String? name,
    String? model,
    String? type,
    String? platform,
    String? protocol,
    String? apiKey,
    String? apiUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? promptPrice,
    double? completionPrice,
    String? currency,
    String? conversationName,
    String? systemPrompt,
    double? temperature,
    String? replyLanguage,
    bool? maskPhone,
    bool? maskIdCard,
  }) {
    return ChatModel(
      modelId: modelId ?? this.modelId,
      name: name ?? this.name,
      model: model ?? this.model,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      protocol: protocol ?? this.protocol,
      apiKey: apiKey ?? this.apiKey,
      apiUrl: apiUrl ?? this.apiUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      promptPrice: promptPrice ?? this.promptPrice,
      completionPrice: completionPrice ?? this.completionPrice,
      currency: currency ?? this.currency,
      conversationName: conversationName ?? this.conversationName,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      replyLanguage: replyLanguage ?? this.replyLanguage,
      maskPhone: maskPhone ?? this.maskPhone,
      maskIdCard: maskIdCard ?? this.maskIdCard,
    );
  }

  /// 是否为在线模型
  bool get isOnlineModel => type == 'online';

  /// 是否为本地模型
  bool get isLocalModel => type == 'local' || type == null;

  /// 获取显示名称（如果有自定义名称则使用自定义名称，否则使用模型名称）
  String get displayName => name.isNotEmpty ? name : model;

  /// 根据模型的 platform、protocol、name/model 字段获取对应的图标路径
  String? getIconPath() {
    return ModelController.resolveIconPath(
      platform: platform,
      protocol: protocol,
      modelName: displayName,
    );
  }

  @override
  String toString() {
    return 'ChatModel(modelId: $modelId, name: $name, model: $model, type: $type, protocol: $protocol)';
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
      return Icons.account_circle_outlined;
    } else if (lowercaseName.contains('gpt') ||
        lowercaseName.contains('openai')) {
      return Icons.chat_bubble_outline;
    } else if (lowercaseName.contains('claude')) {
      return Icons.verified_user;
    } else if (lowercaseName.contains('gemini') ||
        lowercaseName.contains('bard')) {
      return Icons.star_border;
    } else if (lowercaseName.contains('llama') ||
        lowercaseName.contains('meta')) {
      return Icons.schedule;
    } else if (lowercaseName.contains('qwen') ||
        lowercaseName.contains('tongyi')) {
      return Icons.cloud_outlined;
    } else if (lowercaseName.contains('chatglm') ||
        lowercaseName.contains('glm')) {
      return Icons.bolt;
    } else if (lowercaseName.contains('baichuan')) {
      return Icons.park;
    } else if (lowercaseName.contains('wenxin') ||
        lowercaseName.contains('ernie')) {
      return Icons.clear;
    } else if (lowercaseName.contains('spark') ||
        lowercaseName.contains('讯飞')) {
      return Icons.schedule;
    } else {
      return Icons.chat_bubble_outline;
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

// 在线模型提供商列表
final List<Map<String, dynamic>> onlineProviders = [
  {
    'name': 'DeepSeek',
    'id': 'deepseek',
    'protocol': 'openai',
    'currency': 'CNY',
    'icon': Icons.widgets,
    'description': '高性能AI助手，支持多种任务',
    'color': const Color(0xFF1F2937),
    'defaultUrl': 'https://api.deepseek.com',
    'models': [
      {
        'id': 'deepseek-v4-flash',
        'name': 'DeepSeek-V4-Flash',
        'specs': '快速响应 • 高性价比 • 通用对话',
      },
      {
        'id': 'deepseek-v4-pro',
        'name': 'DeepSeek-V4-Pro',
        'specs': '深度推理 • 复杂问题 • 思维链',
      },
    ],
  },
  {
    'name': 'ChatGPT',
    'id': 'openai',
    'protocol': 'openai',
    'currency': 'USD',
    'icon': Icons.terminal,
    'description': 'OpenAI GPT系列模型',
    'color': const Color(0xFF10B981),
    'defaultUrl': 'https://api.openai.com/v1',
    'models': [
      {'id': 'gpt-4o', 'name': 'GPT-4o', 'specs': '多模态 • 高级推理 • 最新旗舰'},
      {'id': 'gpt-4-turbo', 'name': 'GPT-4 Turbo', 'specs': '更快响应 • 128K上下文'},
      {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo', 'specs': '快速响应 • 高性价比'},
    ],
  },
  {
    'name': 'Gemini',
    'id': 'google',
    'protocol': 'gemini',
    'currency': 'USD',
    'icon': Icons.person,
    'description': 'Google Gemini系列模型',
    'color': const Color(0xFFEF4444),
    'defaultUrl': 'https://generativelanguage.googleapis.com/v1',
    'models': [
      {
        'id': 'gemini-pro',
        'name': 'Gemini Pro',
        'specs': '多模态 • 长上下文 • Google',
      },
      {
        'id': 'gemini-pro-vision',
        'name': 'Gemini Pro Vision',
        'specs': '视觉理解 • 图像分析 • 多模态',
      },
      {
        'id': 'gemini-2.0-flash',
        'name': 'Gemini 2.0 Flash',
        'specs': '极速响应 • 多模态 • 轻量',
      },
    ],
  },
  {
    'name': '阿里云百炼',
    'id': 'qwen',
    'protocol': 'openai',
    'currency': 'CNY',
    'icon': Icons.chat_bubble_outline,
    'description': '阿里云百炼平台模型服务',
    'color': const Color(0xFF8B5CF6),
    'defaultUrl': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    'models': [
      // ===== 推荐模型 =====
      {
        'id': 'qwen3.7-max',
        'name': 'Qwen3.7-Max',
        'specs': '1M上下文 • 最强推理 • 思考模式 • 工具调用',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen3.7-plus',
        'name': 'Qwen3.7-Plus',
        'specs': '1M上下文 • 能力成本均衡 • 思考模式 • 工具调用',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen3.6-flash',
        'name': 'Qwen3.6-Flash',
        'specs': '1M上下文 • 轻量低成本 • 思考模式 • 工具调用',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'deepseek-v4-pro',
        'name': 'DeepSeek-V4-Pro',
        'specs': '1M上下文 • 深度推理 • Function Calling',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-v4-flash',
        'name': 'DeepSeek-V4-Flash',
        'specs': '1M上下文 • 快速推理 • Function Calling',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'glm-5.1',
        'name': 'GLM-5.1',
        'specs': '198k上下文 • 智能体优化 • 思考模式 • 结构化输出',
        'context': '198k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'kimi-k2.6',
        'name': 'Kimi-K2.6',
        'specs': '256k上下文 • 思考模式 • Function Calling',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'MiniMax-M2.5',
        'name': 'MiniMax-M2.5',
        'specs': '192k上下文 • 智能体优化 • Function Calling',
        'context': '192k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'mimo-v2.5-pro',
        'name': 'Mimo-V2.5-Pro',
        'specs': '1M上下文 • 思考模式 • 结构化输出',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== Qwen3.7 系列 =====
      {
        'id': 'qwen3.7-max-2026-05-20',
        'name': 'Qwen3.7-Max (05-20)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.7-max-preview',
        'name': 'Qwen3.7-Max Preview',
        'specs': '1M上下文 • 预览版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.7-plus-2026-05-26',
        'name': 'Qwen3.7-Plus (05-26)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== Qwen3.6 系列 =====
      {
        'id': 'qwen3.6-max-preview',
        'name': 'Qwen3.6-Max Preview',
        'specs': '256k上下文 • 预览版',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.6-plus',
        'name': 'Qwen3.6-Plus',
        'specs': '1M上下文 • 思考模式 • 工具调用',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen3.6-plus-2026-04-02',
        'name': 'Qwen3.6-Plus (04-02)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.6-flash-2026-04-16',
        'name': 'Qwen3.6-Flash (04-16)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== Qwen3.5 系列 =====
      {
        'id': 'qwen3.5-plus',
        'name': 'Qwen3.5-Plus',
        'specs': '1M上下文 • 思考模式 • 工具调用',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen3.5-plus-2026-02-15',
        'name': 'Qwen3.5-Plus (02-15)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.5-flash',
        'name': 'Qwen3.5-Flash',
        'specs': '1M上下文 • 思考模式 • 工具调用',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen3.5-flash-2026-02-23',
        'name': 'Qwen3.5-Flash (02-23)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.5-397b-a17b',
        'name': 'Qwen3.5-397B-A17B',
        'specs': '256k上下文 • MoE架构 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.5-122b-a10b',
        'name': 'Qwen3.5-122B-A10B',
        'specs': '256k上下文 • MoE架构 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.5-27b',
        'name': 'Qwen3.5-27B',
        'specs': '256k上下文 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.5-35b-a3b',
        'name': 'Qwen3.5-35B-A3B',
        'specs': '256k上下文 • MoE轻量 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== 第三方模型 =====
      {
        'id': 'glm-5',
        'name': 'GLM-5',
        'specs': '198k上下文 • 思考模式 • Function Calling',
        'context': '198k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'glm-4.7',
        'name': 'GLM-4.7',
        'specs': '198k上下文 • 思考模式 • Function Calling',
        'context': '198k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'glm-4.5',
        'name': 'GLM-4.5',
        'specs': '198k上下文 • 思考模式 • Function Calling',
        'context': '198k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'glm-4.5-air',
        'name': 'GLM-4.5-Air',
        'specs': '198k上下文 • 轻量版',
        'context': '198k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'MiniMax-M2.1',
        'name': 'MiniMax-M2.1',
        'specs': '200k上下文 • 思考模式 • Function Calling',
        'context': '200k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'kimi-k2.5',
        'name': 'Kimi-K2.5',
        'specs': '256k上下文 • 思考模式 • Function Calling',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'kimi-k2-thinking',
        'name': 'Kimi-K2-Thinking',
        'specs': '256k上下文 • 深度思考 • 结构化输出',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'Moonshot-Kimi-K2-Instruct',
        'name': 'Kimi-K2-Instruct',
        'specs': '256k上下文 • 开源 • Function Calling',
        'context': '256k',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-v3.2',
        'name': 'DeepSeek-V3.2',
        'specs': '128k上下文 • 思考模式 • Function Calling',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': true,
      },
      {
        'id': 'deepseek-v3.2-exp',
        'name': 'DeepSeek-V3.2-Exp',
        'specs': '128k上下文 • 实验版',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-v3.1',
        'name': 'DeepSeek-V3.1',
        'specs': '128k上下文 • 思考模式 • Function Calling',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': true,
      },
      {
        'id': 'deepseek-v3',
        'name': 'DeepSeek-V3',
        'specs': '128k上下文 • Function Calling',
        'context': '128k',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': true,
      },
      {
        'id': 'deepseek-r1',
        'name': 'DeepSeek-R1',
        'specs': '128k上下文 • 深度推理 • Function Calling',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': true,
      },
      {
        'id': 'deepseek-r1-0528',
        'name': 'DeepSeek-R1-0528',
        'specs': '128k上下文 • 深度推理 • 快照版',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-r1-distill-llama-70b',
        'name': 'DeepSeek-R1-Distill-70B',
        'specs': '128k上下文 • 蒸馏版 • 思考模式',
        'context': '128k',
        'thinking': true,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-r1-distill-qwen-32b',
        'name': 'DeepSeek-R1-Distill-32B',
        'specs': '128k上下文 • 蒸馏版',
        'context': '128k',
        'thinking': true,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-r1-distill-qwen-14b',
        'name': 'DeepSeek-R1-Distill-14B',
        'specs': '128k上下文 • 蒸馏版',
        'context': '128k',
        'thinking': true,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-r1-distill-qwen-7b',
        'name': 'DeepSeek-R1-Distill-7B',
        'specs': '128k上下文 • 蒸馏版',
        'context': '128k',
        'thinking': true,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-r1-distill-qwen-1.5b',
        'name': 'DeepSeek-R1-Distill-1.5B',
        'specs': '128k上下文 • 蒸馏版 • 轻量',
        'context': '128k',
        'thinking': true,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-r1-distill-llama-8b',
        'name': 'DeepSeek-R1-Distill-8B',
        'specs': '128k上下文 • 蒸馏版 • 轻量',
        'context': '128k',
        'thinking': true,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      // ===== Qwen3 系列 =====
      {
        'id': 'qwen3-max',
        'name': 'Qwen3-Max',
        'specs': '256k上下文 • 思考模式 • 工具调用 • 结构化输出',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen3-max-2026-01-23',
        'name': 'Qwen3-Max (01-23)',
        'specs': '256k上下文 • 快照版',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-max-preview',
        'name': 'Qwen3-Max Preview',
        'specs': '256k上下文 • 预览版',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-235b-a22b',
        'name': 'Qwen3-235B-A22B',
        'specs': '256k上下文 • MoE架构 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-32b',
        'name': 'Qwen3-32B',
        'specs': '256k上下文 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-30b-a3b',
        'name': 'Qwen3-30B-A3B',
        'specs': '256k上下文 • MoE轻量 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-14b',
        'name': 'Qwen3-14B',
        'specs': '256k上下文 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-8b',
        'name': 'Qwen3-8B',
        'specs': '256k上下文 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-4b',
        'name': 'Qwen3-4B',
        'specs': '256k上下文 • 开源',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-1.7b',
        'name': 'Qwen3-1.7B',
        'specs': '256k上下文 • 开源 • 轻量',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-0.6b',
        'name': 'Qwen3-0.6B',
        'specs': '256k上下文 • 开源 • 极轻量',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== Qwen3-Coder 系列 =====
      {
        'id': 'qwen3-coder-plus',
        'name': 'Qwen3-Coder-Plus',
        'specs': '1M上下文 • 代码专用',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-coder-plus-2025-09-23',
        'name': 'Qwen3-Coder-Plus (09-23)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-coder-plus-2025-07-22',
        'name': 'Qwen3-Coder-Plus (07-22)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-coder-flash',
        'name': 'Qwen3-Coder-Flash',
        'specs': '1M上下文 • 代码专用 • 轻量快速',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-coder-flash-2025-07-28',
        'name': 'Qwen3-Coder-Flash (07-28)',
        'specs': '1M上下文 • 快照版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-coder-next',
        'name': 'Qwen3-Coder-Next',
        'specs': '256k上下文 • 代码专用',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-coder-480b-a35b-instruct',
        'name': 'Qwen3-Coder-480B-Instruct',
        'specs': '256k上下文 • 开源 • 代码专用',
        'context': '256k',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen3-coder-30b-a3b-instruct',
        'name': 'Qwen3-Coder-30B-Instruct',
        'specs': '256k上下文 • 开源 • 代码专用',
        'context': '256k',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== Qwen2.5 开源系列 =====
      {
        'id': 'qwen2.5-vl-72b-instruct',
        'name': 'Qwen2.5-VL-72B',
        'specs': '1M上下文 • 视觉理解 • 多模态',
        'context': '1M',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-vl-32b-instruct',
        'name': 'Qwen2.5-VL-32B',
        'specs': '1M上下文 • 视觉理解 • 多模态',
        'context': '1M',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-vl-7b-instruct',
        'name': 'Qwen2.5-VL-7B',
        'specs': '1M上下文 • 视觉理解 • 轻量',
        'context': '1M',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-vl-3b-instruct',
        'name': 'Qwen2.5-VL-3B',
        'specs': '1M上下文 • 视觉理解 • 极轻量',
        'context': '1M',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-72b-instruct',
        'name': 'Qwen2.5-72B-Instruct',
        'specs': '1M上下文 • 开源 • Function Calling',
        'context': '1M',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-32b-instruct',
        'name': 'Qwen2.5-32B-Instruct',
        'specs': '1M上下文 • 开源 • Function Calling',
        'context': '1M',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-14b-instruct',
        'name': 'Qwen2.5-14B-Instruct',
        'specs': '1M上下文 • 开源 • Function Calling',
        'context': '1M',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-7b-instruct',
        'name': 'Qwen2.5-7B-Instruct',
        'specs': '1M上下文 • 开源 • 轻量',
        'context': '1M',
        'thinking': false,
        'fc': true,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'qwen2.5-omni-7b',
        'name': 'Qwen2.5-Omni-7B',
        'specs': '1M上下文 • 多模态 • 语音图文',
        'context': '1M',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      // ===== Qwen Long =====
      {
        'id': 'qwen-long',
        'name': 'Qwen-Long',
        'specs': '10M上下文 • 超长文档 • 结构化输出',
        'context': '10M',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen-long-latest',
        'name': 'Qwen-Long-Latest',
        'specs': '10M上下文 • 超长文档 • 最新版',
        'context': '10M',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': true,
        'batchCalling': true,
      },
      // ===== 旧版模型 =====
      {
        'id': 'qwen-plus',
        'name': 'Qwen-Plus',
        'specs': '1M上下文 • 思考模式 • 工具调用 • 旧版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen-max',
        'name': 'Qwen-Max',
        'specs': '128k上下文 • 思考模式 • 工具调用 • 旧版',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwen-turbo',
        'name': 'Qwen-Turbo',
        'specs': '1M上下文 • 思考模式 • 工具调用 • 旧版',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': true,
      },
      {
        'id': 'qwq-plus',
        'name': 'QwQ-Plus',
        'specs': '128k上下文 • 思考模式 • 深度推理',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': true,
      },
      {
        'id': 'qvq-max',
        'name': 'QvQ-Max',
        'specs': '128k上下文 • 视觉推理 • 思考模式',
        'context': '128k',
        'thinking': true,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'qwen-mt-plus',
        'name': 'Qwen-MT-Plus',
        'specs': '16k上下文 • 翻译专用',
        'context': '16k',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'qwen-mt-turbo',
        'name': 'Qwen-MT-Turbo',
        'specs': '16k上下文 • 翻译专用 • 快速',
        'context': '16k',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
    ],
  },
  {
    'name': '腾讯云TokenHub',
    'id': 'tencent',
    'protocol': 'openai',
    'currency': 'CNY',
    'icon': Icons.cloud_outlined,
    'description': '腾讯云TokenHub大模型服务',
    'color': const Color(0xFF00A4FF),
    'defaultUrl': 'https://api.hunyuan.cloud.tencent.com/v1',
    'models': [
      // ===== 推荐模型 =====
      {
        'id': 'hy3-preview',
        'name': 'Hy3 Preview',
        'specs': '256k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-v4-flash',
        'name': 'DeepSeek-V4-Flash',
        'specs': '1M上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'deepseek-v4-pro',
        'name': 'DeepSeek-V4-Pro',
        'specs': '1M上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== 混元系列 =====
      {
        'id': 'hunyuan-role-latest',
        'name': 'Hunyuan Role',
        'specs': '32k上下文 • 角色扮演 • 对话创作',
        'context': '32k',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'hy-mt2-pro',
        'name': 'Hy-MT2-Pro',
        'specs': '8k上下文 • 翻译旗舰 • 专业领域',
        'context': '8k',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'hy-mt2-plus',
        'name': 'Hy-MT2-Plus',
        'specs': '8k上下文 • 翻译模型 • 指令遵循',
        'context': '8k',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'hy-mt2-lite',
        'name': 'Hy-MT2-Lite',
        'specs': '8k上下文 • 翻译轻量 • 快速响应',
        'context': '8k',
        'thinking': false,
        'fc': false,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      // ===== DeepSeek 系列 =====
      {
        'id': 'deepseek-v3.2',
        'name': 'DeepSeek-V3.2',
        'specs': '128k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '128k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== GLM 系列 =====
      {
        'id': 'glm-5.2',
        'name': 'GLM-5.2',
        'specs': '1M上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'glm-5.1',
        'name': 'GLM-5.1',
        'specs': '200k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '200k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'glm-5v-turbo',
        'name': 'GLM-5V-Turbo',
        'specs': '200k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '200k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'glm-5-turbo',
        'name': 'GLM-5-Turbo',
        'specs': '200k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '200k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'glm-5',
        'name': 'GLM-5',
        'specs': '200k上下文 • 深度思考 • Function Calling',
        'context': '200k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      // ===== Kimi 系列 =====
      {
        'id': 'kimi-k2.7-code',
        'name': 'Kimi-K2.7-Code',
        'specs': '256k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'kimi-k2.6',
        'name': 'Kimi-K2.6',
        'specs': '256k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      {
        'id': 'kimi-k2.5',
        'name': 'Kimi-K2.5',
        'specs': '256k上下文 • 深度思考 • 结构化输出 • Function Calling',
        'context': '256k',
        'thinking': true,
        'fc': true,
        'tools': true,
        'structuredOutput': true,
        'batchCalling': false,
      },
      // ===== MiniMax 系列 =====
      {
        'id': 'minimax-m3',
        'name': 'MiniMax-M3',
        'specs': '1M上下文 • 深度思考 • Function Calling',
        'context': '1M',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'minimax-m2.7',
        'name': 'MiniMax-M2.7',
        'specs': '200k上下文 • 深度思考 • Function Calling',
        'context': '200k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'minimax-m2.5',
        'name': 'MiniMax-M2.5',
        'specs': '200k上下文 • 深度思考 • Function Calling',
        'context': '200k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      // ===== Qwen 系列 =====
      {
        'id': 'qwen3.5-flash',
        'name': 'Qwen3.5-Flash',
        'specs': '991k上下文 • 深度思考 • Function Calling',
        'context': '991k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
      {
        'id': 'qwen3.5-plus',
        'name': 'Qwen3.5-Plus',
        'specs': '991k上下文 • 深度思考 • Function Calling',
        'context': '991k',
        'thinking': true,
        'fc': true,
        'tools': false,
        'structuredOutput': false,
        'batchCalling': false,
      },
    ],
  },
  {
    'name': 'Mimo',
    'id': 'xiaomi_mimo',
    'protocol': 'openai',
    'currency': 'CNY',
    'icon': Icons.phone_iphone,
    'description': '小米Mimo大模型服务',
    'color': const Color(0xFFFF6900),
    'defaultUrl': 'https://api.xiaomimimo.com/v1',
    'models': [
      {
        'id': 'mimo-v2.5-pro',
        'name': 'Mimo-V2.5-Pro',
        'specs': '1M上下文 • 思考模式 • 结构化输出',
      },
      {
        'id': 'mimo-v2.5-lite',
        'name': 'Mimo-V2.5-Lite',
        'specs': '轻量快速 • 高性价比 • 日常对话',
      },
    ],
  },
];
