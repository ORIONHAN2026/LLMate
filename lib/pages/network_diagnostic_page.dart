import 'package:flutter/material.dart';
import '../framework/network_diagnostics.dart';

/// 网络诊断测试页面
/// 用于测试各种API端点的网络连接
class NetworkDiagnosticPage extends StatefulWidget {
  const NetworkDiagnosticPage({super.key});

  @override
  State<NetworkDiagnosticPage> createState() => _NetworkDiagnosticPageState();
}

class _NetworkDiagnosticPageState extends State<NetworkDiagnosticPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  String _diagnosticResult = '';
  bool _isLoading = false;

  // 预设的API端点
  final List<Map<String, String>> _presetEndpoints = [
    {
      'name': 'OpenAI',
      'url': 'https://api.openai.com/v1/chat/completions',
      'description': 'OpenAI ChatGPT API',
    },
    {
      'name': 'DeepSeek',
      'url': 'https://api.deepseek.com/v1/chat/completions',
      'description': 'DeepSeek API',
    },
    {
      'name': 'Ollama (本地)',
      'url': 'http://localhost:11434/api/tags',
      'description': 'Ollama 本地 API',
    },
    {
      'name': 'Azure OpenAI',
      'url':
          'https://your-resource.openai.azure.com/openai/deployments/gpt-4/chat/completions',
      'description': 'Azure OpenAI API',
    },
  ];

  @override
  void initState() {
    super.initState();
    _urlController.text = _presetEndpoints[0]['url']!;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _diagnosticResult = '请输入API端点URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _diagnosticResult = '正在进行网络诊断...';
    });

    try {
      final result = await NetworkDiagnostics.testConnection(
        url: _urlController.text,
        apiKey:
            _apiKeyController.text.isNotEmpty ? _apiKeyController.text : null,
      );

      final readableReport = NetworkDiagnostics.generateReadableReport(result);

      setState(() {
        _diagnosticResult = readableReport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _diagnosticResult = '诊断失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网络诊断工具'), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预设端点选择
            const Text(
              '选择预设端点:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  _presetEndpoints.map((endpoint) {
                    return ActionChip(
                      label: Text(endpoint['name']!),
                      tooltip: endpoint['description'],
                      onPressed: () {
                        _urlController.text = endpoint['url']!;
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // URL输入
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API端点URL',
                border: OutlineInputBorder(),
                hintText: 'https://api.openai.com/v1/chat/completions',
              ),
            ),
            const SizedBox(height: 16),

            // API Key输入
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key (可选)',
                border: OutlineInputBorder(),
                hintText: 'sk-...',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // 诊断按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runDiagnostics,
                child:
                    _isLoading
                        ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('诊断中...'),
                          ],
                        )
                        : const Text('开始诊断'),
              ),
            ),
            const SizedBox(height: 16),

            // 结果显示
            const Text(
              '诊断结果:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _diagnosticResult.isEmpty
                        ? '点击"开始诊断"按钮进行网络检测'
                        : _diagnosticResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 网络诊断工具入口
/// 可以在主应用中添加这个页面进行网络诊断
class NetworkDiagnosticTool {
  /// 显示网络诊断页面
  static void showDiagnosticPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NetworkDiagnosticPage()),
    );
  }

  /// 快速诊断指定URL
  static Future<String> quickDiagnose(String url, {String? apiKey}) async {
    try {
      final result = await NetworkDiagnostics.testConnection(
        url: url,
        apiKey: apiKey,
      );
      return NetworkDiagnostics.generateReadableReport(result);
    } catch (e) {
      return '诊断失败: $e';
    }
  }
}
