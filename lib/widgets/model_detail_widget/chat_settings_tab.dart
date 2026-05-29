import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/models/chat/chat_setting.dart';

class ChatSettingsTab extends StatefulWidget {
  final ChatModel model;
  final Function(ChatModel) onModelUpdated;

  const ChatSettingsTab({
    super.key,
    required this.model,
    required this.onModelUpdated,
  });

  @override
  State<ChatSettingsTab> createState() => _ChatSettingsTabState();
}

class _ChatSettingsTabState extends State<ChatSettingsTab> {
  late ChatModel _currentModel;
  late TextEditingController _systemPromptController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
    _systemPromptController = TextEditingController();
    _initializeData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      _currentModel = widget.model;
      _initializeData();
    }
  }

  void _initializeData() {
    _systemPromptController.text =
        _currentModel.chatSettings?.systemPrompt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // 模型参数卡片
          _buildConfigCard('模型参数', CupertinoIcons.slider_horizontal_3, [
            _buildTemperatureSlider(),
            const SizedBox(height: 12),
            _buildSystemPromptField(),
          ]),

          // const SizedBox(height: 12),
          // // 响应设置卡片
          // _buildConfigCard('响应设置', CupertinoIcons.chat_bubble_text, [
          //   _buildReplyLanguageDropdown(),
          // ]),

          // const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildConfigCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          //     const SizedBox(width: 6),
          //     Text(
          //       title,
          //       style: TextStyle(
          //         fontSize: 14,
          //         fontWeight: FontWeight.w600,
          //         color: Theme.of(context).colorScheme.primary,
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTemperatureSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '温度 (Temperature)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              (_currentModel.chatSettings?.temperature ?? 0.7).toStringAsFixed(
                1,
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).dividerColor,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: _currentModel.chatSettings?.temperature ?? 0.7,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                final updatedChatSettings = (_currentModel.chatSettings ??
                        ChatSettings(
                          conversationName: '新对话',
                          systemPrompt: '',
                          temperature: 0.7,
                          replyLanguage: '',
                        ))
                    .copyWith(temperature: value);
                _currentModel = _currentModel.copyWith(
                  chatSettings: updatedChatSettings,
                );
              });
              // 自动保存
              widget.onModelUpdated(_currentModel);
            },
          ),
        ),
        // 温度刻度标签
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '精确',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '中性',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '创意',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '控制回复的随机性和创造性。较低值更保守，较高值更有创意。',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPromptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '模型的角色设定',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            GestureDetector(
              onTap: _showPresetRolesDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '预设角色',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _systemPromptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '请输入角色设定的描述，用于指导大模型的行为和响应风格...',
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.all(10),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) {
            // 取消之前的定时器
            _debounceTimer?.cancel();

            // 设置新的定时器，1秒后自动保存
            _debounceTimer = Timer(const Duration(seconds: 1), () {
              final updatedChatSettings = (_currentModel.chatSettings ??
                      ChatSettings(
                        conversationName: '新对话',
                        systemPrompt: '',
                        temperature: 0.7,
                        replyLanguage: '',
                      ))
                  .copyWith(systemPrompt: value);
              setState(() {
                _currentModel = _currentModel.copyWith(
                  chatSettings: updatedChatSettings,
                );
              });
              widget.onModelUpdated(_currentModel);
              print("保存");
            });
          },
        ),
        const SizedBox(height: 3),
        Text(
          '角色设定会在每次对话开始时发送给大模型，用于设定角色和行为规范，可根据自己希望大模型扮演的角色自行调整。',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // 预设角色数据
  final List<Map<String, String>> _presetRoles = [
    {
      'name': '通用助手',
      'description': '友善、专业的AI助手',
      'prompt': '你是一个友善、专业且乐于助人的AI助手。请用清晰、准确的语言回答用户的问题，并在适当时提供有用的建议和解释。',
    },
    {
      'name': '拼写检查',
      'description': '拼写检查专家',
      'prompt': '你是一个经验丰富的文字编辑工作者，可以发现并纠正文章中的错别字以及相关语法问题。',
    },
    {
      'name': '代码专家',
      'description': '精通编程开发的技术专家',
      'prompt':
          '你是一个经验丰富的软件开发专家，精通多种编程语言和开发框架。请为用户提供高质量的代码解决方案，包括代码示例、最佳实践和技术建议。回答时要考虑代码的可读性、性能和安全性。',
    },
    {
      'name': '法律专家',
      'description': '专业的法律顾问',
      'prompt':
          '你是一位经验丰富的法律专家，熟悉各种法律法规。请为用户提供专业的法律建议和解释，但请注意提醒用户这些建议仅供参考，具体法律问题应咨询专业律师。',
    },
    {
      'name': '文案写手',
      'description': '创意文案和内容创作专家',
      'prompt':
          '你是一位富有创意的文案写手，擅长创作各种类型的文案内容。请根据用户需求，创作引人入胜、表达清晰且符合目标受众的文案。注意语言的感染力和传播效果。',
    },
    {
      'name': '数据分析师',
      'description': '数据分析和统计专家',
      'prompt':
          '你是一位专业的数据分析师，精通统计学、数据挖掘和数据可视化。请为用户提供准确的数据分析、统计解释和可视化建议。用清晰的语言解释复杂的数据概念。',
    },
    {
      'name': '教育导师',
      'description': '耐心的教学专家',
      'prompt':
          '你是一位耐心、专业的教育导师，擅长用简单易懂的方式解释复杂概念。请根据用户的学习水平，提供循序渐进的教学内容，并鼓励用户主动思考和提问。',
    },
    {
      'name': '商业顾问',
      'description': '企业管理和商业策略专家',
      'prompt':
          '你是一位经验丰富的商业顾问，精通企业管理、市场营销和商业策略。请为用户提供实用的商业建议，包括市场分析、运营优化和战略规划等方面的专业见解。',
    },
    {
      'name': '心理咨询师',
      'description': '专业的心理健康顾问',
      'prompt':
          '你是一位专业、温暖的心理咨询师，具备丰富的心理学知识。请以同理心倾听用户的困扰，提供支持性的建议和心理健康知识。但请提醒用户，严重的心理问题需要寻求专业心理医生的帮助。',
    },
  ];

  // 显示预设角色对话框
  void _showPresetRolesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Row(
            children: [
              Icon(
                Icons.psychology,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '选择预设角色',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.separated(
              itemCount: _presetRoles.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final role = _presetRoles[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      role['name']![0],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    role['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      role['prompt']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _applyPresetRole(role['prompt']!);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 应用预设角色
  void _applyPresetRole(String prompt) {
    _systemPromptController.text = prompt;

    final updatedChatSettings = (_currentModel.chatSettings ??
            ChatSettings(
              conversationName: '新对话',
              systemPrompt: '',
              temperature: 0.7,
              replyLanguage: '',
            ))
        .copyWith(systemPrompt: prompt);

    setState(() {
      _currentModel = _currentModel.copyWith(chatSettings: updatedChatSettings);
    });

    widget.onModelUpdated(_currentModel);

    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('预设角色已应用'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
