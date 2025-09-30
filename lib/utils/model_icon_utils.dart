import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ModelIconUtils {
  static Widget buildModelIconWidget(
    String modelName,
    bool isSelected, {
    String? provider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: _getModelIcon(modelName, isSelected, provider: provider),
      ),
    );
  }

  static Widget _getModelIcon(
    String modelName,
    bool isSelected, {
    String? provider,
  }) {
    final iconColor = isSelected ? Colors.white : Colors.grey[600];

    // 根据模型名称或provider返回相应图标
    if (provider != null) {
      switch (provider.toLowerCase()) {
        case 'openai':
          return _buildAssetIcon('assets/icons/openai.webp', iconColor);
        case 'anthropic':
          return _buildAssetIcon('assets/icons/anthropic.webp', iconColor);
        case 'gemini':
        case 'google':
          return _buildAssetIcon('assets/icons/gemini-color.webp', iconColor);
        case 'deepseek':
          return _buildAssetIcon('assets/icons/deepseek-color.webp', iconColor);
        case 'qwen':
          return _buildAssetIcon('assets/icons/qwen-color.webp', iconColor);
        case 'yuanbao':
          return _buildAssetIcon('assets/icons/yuanbao-color.webp', iconColor);
        case 'ollama':
          return _buildAssetIcon('assets/icons/ollama.webp', iconColor);
        default:
          return Icon(CupertinoIcons.device_desktop, color: iconColor, size: 16);
      }
    }

    // 根据模型名称匹配
    final lowerName = modelName.toLowerCase();
    if (lowerName.contains('gpt') || lowerName.contains('openai')) {
      return _buildAssetIcon('assets/icons/openai.webp', iconColor);
    } else if (lowerName.contains('claude') ||
        lowerName.contains('anthropic')) {
      return _buildAssetIcon('assets/icons/anthropic.webp', iconColor);
    } else if (lowerName.contains('gemini') || lowerName.contains('google')) {
      return _buildAssetIcon('assets/icons/gemini-color.webp', iconColor);
    } else if (lowerName.contains('deepseek')) {
      return _buildAssetIcon('assets/icons/deepseek-color.webp', iconColor);
    } else if (lowerName.contains('qwen')) {
      return _buildAssetIcon('assets/icons/qwen-color.webp', iconColor);
    } else if (lowerName.contains('yuanbao')) {
      return _buildAssetIcon('assets/icons/yuanbao-color.webp', iconColor);
    } else if (lowerName.contains('llama') || lowerName.contains('ollama')) {
      return _buildAssetIcon('assets/icons/ollama.webp', iconColor);
    } else {
      return Icon(CupertinoIcons.device_desktop, color: iconColor, size: 16);
    }
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
