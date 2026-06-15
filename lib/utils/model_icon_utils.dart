import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ModelIconUtils {
  /// 根据平台名称、协议、模型名称等信息解析图标路径
  /// 优先级：platform > protocol > modelName
  static String? resolveIconPath({
    String? platform,
    String? protocol,
    String? modelName,
  }) {
    // 1. 优先用 platform 字段匹配（最准确）
    if (platform != null) {
      final p = platform.toLowerCase();
      if (p.contains('deepseek')) {
        return 'assets/icons/deepseek-color.webp';
      }
      if (p.contains('openai') || p.contains('chatgpt')) {
        return 'assets/icons/openai.webp';
      }
      if (p.contains('gemini') || p.contains('google')) {
        return 'assets/icons/gemini-color.webp';
      }
      if (p.contains('claude') || p.contains('anthropic')) {
        return 'assets/icons/claude-color.webp';
      }
      if (p.contains('qwen') || p.contains('通义') || p.contains('百炼') || p.contains('阿里')) {
        return 'assets/icons/qwen-color.webp';
      }
      if (p.contains('hunyuan') || p.contains('混元') || p.contains('腾讯')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (p.contains('glm') || p.contains('智谱') || p.contains('zhipu')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (p.contains('kimi') || p.contains('moonshot')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (p.contains('minimax')) {
        return 'assets/icons/yuanbao-color.webp';
      }
    }

    // 2. 用 protocol 字段匹配
    if (protocol != null) {
      final proto = protocol.toLowerCase();
      if (proto == 'gemini') {
        return 'assets/icons/gemini-color.webp';
      }
      if (proto == 'anthropic') {
        return 'assets/icons/claude-color.webp';
      }
    }

    // 3. 最后用模型名称兜底匹配
    if (modelName != null) {
      final name = modelName.toLowerCase();
      if (name.contains('deepseek') || name.contains('r1')) {
        return 'assets/icons/deepseek-color.webp';
      }
      if (name.contains('gpt') || name.contains('openai')) {
        return 'assets/icons/openai.webp';
      }
      if (name.contains('claude') || name.contains('anthropic')) {
        return 'assets/icons/claude-color.webp';
      }
      if (name.contains('gemini') || name.contains('bard') || name.contains('google')) {
        return 'assets/icons/gemini-color.webp';
      }
      if (name.contains('qwen') || name.contains('tongyi')) {
        return 'assets/icons/qwen-color.webp';
      }
      if (name.contains('hunyuan') || name.contains('混元')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (name.contains('glm') || name.contains('zhipu') || name.contains('智谱')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (name.contains('kimi') || name.contains('moonshot')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (name.contains('minimax')) {
        return 'assets/icons/yuanbao-color.webp';
      }
    }

    return null;
  }

  static Widget buildModelIconWidget(
    String modelName,
    bool isSelected, {
    String? platform,
    String? protocol,
  }) {
    final iconPath = resolveIconPath(
      platform: platform,
      protocol: protocol,
      modelName: modelName,
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: iconPath != null
            ? _buildAssetIcon(
                iconPath,
                isSelected ? Colors.white : Colors.grey[600],
              )
            : Icon(
                CupertinoIcons.device_desktop,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 16,
              ),
      ),
    );
  }

  static Widget _buildAssetIcon(String assetPath, Color? fallbackColor) {
    return Image.asset(
      assetPath,
      width: 16,
      height: 16,
      errorBuilder: (context, error, stackTrace) {
        return Icon(CupertinoIcons.device_desktop, color: fallbackColor, size: 16);
      },
    );
  }
}
