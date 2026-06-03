import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/models/chat/mcp_config.dart';
import 'package:chathub/utils/snackbar_utils.dart';

class McpTab extends StatefulWidget {
  final ChatModel model;
  final Function(ChatModel) onModelUpdated;

  const McpTab({super.key, required this.model, required this.onModelUpdated});

  @override
  State<McpTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<McpTab> {
  late ChatModel _currentModel;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddMcpServiceDialog,
              icon: const Icon(CupertinoIcons.plus, size: 10),
              label: const Text('添加服务'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(80, 28),
                textStyle: const TextStyle(fontSize: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child:
              (_currentModel.mcpServices?.isEmpty ?? true)
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.device_desktop,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无MCP服务',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击上方"添加服务"按钮来配置MCP服务',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _currentModel.mcpServices?.length ?? 0,
                    itemBuilder: (context, index) {
                      final service = _currentModel.mcpServices![index];
                      return _buildMcpServiceCard(service);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildMcpServiceCard(Mcp service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.cloud,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 测试连接按钮
              ElevatedButton.icon(
                onPressed: () => _testMcpService(service),
                icon: const Icon(CupertinoIcons.link, size: 10),
                label: const Text('测试连接'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: const Size(60, 24),
                  textStyle: const TextStyle(fontSize: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 完整测试按钮
              ElevatedButton.icon(
                onPressed: () => _fullMcpTest(service),
                icon: const Icon(CupertinoIcons.play, size: 10),
                label: const Text('完整测试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: const Size(60, 24),
                  textStyle: const TextStyle(fontSize: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.trash,
                  size: 12,
                  color: Colors.red,
                ),
                onPressed: () => _showDeleteMcpServiceDialog(service),
                tooltip: '删除服务',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 显示配置信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '配置信息',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'command: ${service.command?.isEmpty != false ? '(空)' : service.command}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color:
                        service.command?.isEmpty != false
                            ? Colors.red
                            : Colors.black87,
                  ),
                ),
                if (service.args?.isNotEmpty == true)
                  Text(
                    'args: [${service.args!.map((arg) => '"$arg"').join(', ')}]',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                  ),
                if (service.workingDirectory != null)
                  Text(
                    'workingDirectory: ${service.workingDirectory}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                  ),
                if (service.timeout != null)
                  Text(
                    'timeout: ${service.timeout}s',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _testMcpService(Mcp service) {
    // 显示简单的测试提示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Icon(
                CupertinoIcons.play,
                size: 14,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Text(
                '测试MCP服务',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '正在测试服务 "${service.name}"...',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '命令: ${service.command}',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭', style: TextStyle(fontSize: 11)),
            ),
          ],
        );
      },
    );

    // 简化的测试逻辑
    SnackBarUtils.showSuccess(context, 'MCP服务测试功能开发中');
  }

  void _fullMcpTest(Mcp service) {
    // 显示完整测试提示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Icon(
                CupertinoIcons.play_circle,
                size: 14,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Text(
                '完整测试MCP服务',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '正在进行完整测试服务 "${service.name}"...',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '命令: ${service.command}',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭', style: TextStyle(fontSize: 11)),
            ),
          ],
        );
      },
    );

    // 简化的完整测试逻辑
    SnackBarUtils.showSuccess(context, 'MCP服务完整测试功能开发中');
  }

  void _showAddMcpServiceDialog() {
    final configController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.plus,
                size: 14,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Text(
                '添加MCP服务',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '请输入MCP服务配置（JSON格式）:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: configController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText: '''支持以下格式:

标准MCP配置格式:
{
  "mcpServers": {
    "service-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/files"]
    }
  }
}

平面格式:
{
  "service-name": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/files"]
  }
}

简化格式:
{
  "name": "service-name",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/files"]
}''',
                      hintStyle: const TextStyle(fontSize: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '💡 提示: 可以同时添加多个服务，系统会自动解析不同的格式',
                    style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final configText = configController.text.trim();
                if (configText.isEmpty) {
                  SnackBarUtils.showWarning(context, '请输入配置信息');
                  return;
                }

                try {
                  _parseAndAddMcpConfig(configText);
                  Navigator.pop(context);

                  // 自动保存
                  widget.onModelUpdated(_currentModel);
                  SnackBarUtils.showSuccess(
                    context,
                    'MCP服务添加成功，当前服务数量: ${_currentModel.mcpServices?.length ?? 0}',
                  );
                } catch (e) {
                  SnackBarUtils.showWarning(context, '配置解析失败: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(60, 28),
                textStyle: const TextStyle(fontSize: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.plus, size: 10),
                  const SizedBox(width: 4),
                  Text('添加'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteMcpServiceDialog(Mcp service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 14,
                color: Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '确定要删除MCP服务 "${service.name}" 吗？',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '服务信息:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '命令: ${service.command}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                    if (service.args?.isNotEmpty == true)
                      Text(
                        '参数: ${service.args!.join(' ')}',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info, size: 12, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '此操作不可撤销',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // 删除服务
                final currentServices = List<Mcp>.from(
                  _currentModel.mcpServices ?? [],
                );
                currentServices.removeWhere((s) => s.name == service.name);

                setState(() {
                  _currentModel = _currentModel.copyWith(
                    mcpServices: currentServices,
                  );
                });

                // 自动保存
                widget.onModelUpdated(_currentModel);
                SnackBarUtils.showSuccess(
                  context,
                  'MCP服务 "${service.name}" 已删除',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(60, 28),
                textStyle: const TextStyle(fontSize: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.trash, size: 10),
                  const SizedBox(width: 4),
                  Text('删除'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _parseAndAddMcpConfig(String configText) {
    try {
      final Map<String, dynamic> json = jsonDecode(configText);
      final currentServices = List<Mcp>.from(_currentModel.mcpServices ?? []);

      // 检查是否是简化格式（直接包含name, command, args）
      if (json.containsKey('name') && json.containsKey('command')) {
        // 简化格式
        final serviceName = json['name'] as String;

        // 检查是否已存在同名服务
        if (currentServices.any((s) => s.name == serviceName)) {
          throw Exception('服务名称 "$serviceName" 已存在');
        }

        final service = Mcp(
          mcpId:
              'mcp_${DateTime.now().millisecondsSinceEpoch}_${currentServices.length}',
          name: serviceName,
          command: json['command'] as String?,
          args: (json['args'] as List<dynamic>?)?.cast<String>(),
          env:
              json['env'] != null
                  ? Map<String, String>.from(json['env'])
                  : null,
          workingDirectory: json['workingDirectory'] as String?,
          timeout: json['timeout'] as int?,
        );

        currentServices.add(service);
      } else if (json.containsKey('mcpServers')) {
        // 标准MCP配置格式
        final servers = json['mcpServers'] as Map<String, dynamic>;
        for (final entry in servers.entries) {
          final serviceName = entry.key;
          final serviceConfig = entry.value as Map<String, dynamic>;

          // 检查是否已存在同名服务
          if (currentServices.any((s) => s.name == serviceName)) {
            throw Exception('服务名称 "$serviceName" 已存在');
          }

          final service = Mcp(
            mcpId:
                'mcp_${DateTime.now().millisecondsSinceEpoch}_${currentServices.length}',
            name: serviceName,
            command: serviceConfig['command'] as String?,
            args: (serviceConfig['args'] as List<dynamic>?)?.cast<String>(),
            env:
                serviceConfig['env'] != null
                    ? Map<String, String>.from(serviceConfig['env'])
                    : null,
            workingDirectory: serviceConfig['workingDirectory'] as String?,
            timeout: serviceConfig['timeout'] as int?,
          );

          currentServices.add(service);
        }
      } else {
        // 平面格式：直接是服务名到配置的映射
        for (final entry in json.entries) {
          final serviceName = entry.key;
          final serviceConfig = entry.value as Map<String, dynamic>;

          // 检查是否已存在同名服务
          if (currentServices.any((s) => s.name == serviceName)) {
            throw Exception('服务名称 "$serviceName" 已存在');
          }

          final service = Mcp(
            mcpId:
                'mcp_${DateTime.now().millisecondsSinceEpoch}_${currentServices.length}',
            name: serviceName,
            command: serviceConfig['command'] as String?,
            args: (serviceConfig['args'] as List<dynamic>?)?.cast<String>(),
            env:
                serviceConfig['env'] != null
                    ? Map<String, String>.from(serviceConfig['env'])
                    : null,
            workingDirectory: serviceConfig['workingDirectory'] as String?,
            timeout: serviceConfig['timeout'] as int?,
          );

          currentServices.add(service);
        }
      }

      setState(() {
        _currentModel = _currentModel.copyWith(mcpServices: currentServices);
      });
    } catch (e) {
      rethrow;
    }
  }
}
