import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../framework/llm_hub.dart';
import '../models/bigmodel/chat_model.dart';

/// 配置验证测试页面
/// 用于测试各个LLM提供商的配置验证功能
class ConfigurationValidationPage extends StatefulWidget {
  const ConfigurationValidationPage({super.key});

  @override
  State<ConfigurationValidationPage> createState() =>
      _ConfigurationValidationPageState();
}

class _ConfigurationValidationPageState
    extends State<ConfigurationValidationPage> {
  final Map<String, bool> _validationResults = {};
  final Map<String, String> _validationMessages = {};
  bool _isValidating = false;

  // 测试配置数据
  final List<Map<String, dynamic>> _testConfigs = [
    {
      'provider': 'openai',
      'name': 'GPT-4',
      'model': 'gpt-4',
      'apiUrl': 'https://api.openai.com/v1/chat/completions',
      'apiKey': 'sk-test-key-replace-with-real-key',
      'description': 'OpenAI GPT-4 模型',
    },
    {
      'provider': 'deepseek',
      'name': 'DeepSeek Chat',
      'model': 'deepseek-chat',
      'apiUrl': 'https://api.deepseek.com/v1/chat/completions',
      'apiKey': 'sk-test-key-replace-with-real-key',
      'description': 'DeepSeek 对话模型',
    },
    {
      'provider': 'anthropic',
      'name': 'Claude 3',
      'model': 'claude-3-sonnet-20240229',
      'apiUrl': 'https://api.anthropic.com/v1/messages',
      'apiKey': 'sk-test-key-replace-with-real-key',
      'description': 'Anthropic Claude 3 模型',
    },
    {
      'provider': 'ollama',
      'name': 'Llama 3',
      'model': 'llama3',
      'apiUrl': 'http://localhost:11434/api/chat',
      'apiKey': '',
      'description': 'Ollama 本地模型',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配置验证测试'), backgroundColor: Colors.blue),
      body: Column(
        children: [
          // 控制按钮区域
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isValidating ? null : _validateAllConfigurations,
                    child:
                        _isValidating
                            ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('验证中...'),
                              ],
                            )
                            : const Text('验证所有配置'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearResults,
                  child: const Text('清除结果'),
                ),
              ],
            ),
          ),

          // 结果列表
          Expanded(
            child: ListView.builder(
              itemCount: _testConfigs.length,
              itemBuilder: (context, index) {
                final config = _testConfigs[index];
                final provider = config['provider'] as String;
                final isValidated = _validationResults.containsKey(provider);
                final isValid = _validationResults[provider] ?? false;
                final message = _validationMessages[provider] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      '${config['name']} (${config['provider']})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(config['description']),
                        const SizedBox(height: 4),
                        Text('模型: ${config['model']}'),
                        Text('API URL: ${config['apiUrl']}'),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              color: isValid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing:
                        isValidated
                            ? Icon(
                              isValid ? Icons.check_circle : Icons.error,
                              color: isValid ? Colors.green : Colors.red,
                            )
                            : IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed:
                                  () => _validateSingleConfiguration(
                                    provider,
                                    config,
                                  ),
                            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 验证所有配置
  Future<void> _validateAllConfigurations() async {
    setState(() {
      _isValidating = true;
      _validationResults.clear();
      _validationMessages.clear();
    });

    for (final config in _testConfigs) {
      final provider = config['provider'] as String;
      await _validateSingleConfiguration(provider, config);
    }

    setState(() {
      _isValidating = false;
    });
  }

  /// 验证单个配置
  Future<void> _validateSingleConfiguration(
    String provider,
    Map<String, dynamic> config,
  ) async {
    try {
      if (kDebugMode) {
        print('开始验证 $provider 配置...');
      }

      // 创建测试模型
      final testModel = ChatModel.create(
        name: config['name'],
        model: config['model'],
        provider: provider,
        apiUrl: config['apiUrl'],
        apiKey: config['apiKey'].isNotEmpty ? config['apiKey'] : null,
      );

      // 创建并配置 provider
      final providerInstance = LlmHub.createProvider(testModel);

      // 执行验证
      final isValid = await providerInstance.validateConfiguration();

      setState(() {
        _validationResults[provider] = isValid;
        _validationMessages[provider] =
            isValid ? '✅ 配置验证成功！' : '❌ 配置验证失败，请检查API Key和URL设置';
      });

      if (kDebugMode) {
        print('$provider 配置验证结果: ${isValid ? '成功' : '失败'}');
      }
    } catch (e) {
      setState(() {
        _validationResults[provider] = false;
        _validationMessages[provider] = '❌ 验证过程中发生错误: ${e.toString()}';
      });

      if (kDebugMode) {
        print('$provider 配置验证错误: $e');
      }
    }
  }

  /// 清除结果
  void _clearResults() {
    setState(() {
      _validationResults.clear();
      _validationMessages.clear();
    });
  }
}

/// 配置验证工具类
class ConfigurationValidator {
  /// 快速验证配置
  static Future<Map<String, dynamic>> quickValidate({
    required String provider,
    required String model,
    required String apiUrl,
    String? apiKey,
  }) async {
    try {
      final testModel = ChatModel.create(
        name: 'Test Model',
        model: model,
        provider: provider,
        apiUrl: apiUrl,
        apiKey: apiKey,
      );

      final providerInstance = LlmHub.createProvider(testModel);

      final isValid = await providerInstance.validateConfiguration();

      return {
        'success': isValid,
        'message': isValid ? '配置验证成功' : '配置验证失败',
        'provider': provider,
        'model': model,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': '验证过程中发生错误: ${e.toString()}',
        'provider': provider,
        'model': model,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 批量验证多个配置
  static Future<List<Map<String, dynamic>>> batchValidate(
    List<Map<String, dynamic>> configs,
  ) async {
    final results = <Map<String, dynamic>>[];

    for (final config in configs) {
      final result = await quickValidate(
        provider: config['provider'],
        model: config['model'],
        apiUrl: config['apiUrl'],
        apiKey: config['apiKey'],
      );
      results.add(result);
    }

    return results;
  }
}
