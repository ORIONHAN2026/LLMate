import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../chat/chat_setting.dart';
import '../../core/utils/model_icon_utils.dart';

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

  // 对话设置 - 使用ChatSettings对象
  final ChatSettings? chatSettings;

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
    this.chatSettings,
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
      promptPrice: map['promptPrice']?.toDouble() ?? map['inputPrice']?.toDouble(),
      completionPrice: map['completionPrice']?.toDouble() ?? map['outputPrice']?.toDouble(),
      currency: map['currency'] as String?,
      chatSettings: settings,
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

    // 保存 ChatSettings 对象
    if (chatSettings != null) {
      result['chatSettings'] = chatSettings!.toJson();
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
    return const ChatModel(
      modelId: "",
      name: '请设置',
      model: '未设置对话大模型',
    );
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
    ChatSettings? chatSettings,
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
      chatSettings: chatSettings,
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
    ChatSettings? chatSettings,
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
      chatSettings: chatSettings ?? this.chatSettings,
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
    return ModelIconUtils.resolveIconPath(
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
