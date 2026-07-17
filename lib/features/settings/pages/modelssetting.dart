import 'package:llmate/utils/snackbar_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/standard_app_bar.dart';

import '../../../controllers/session_controller.dart';
import '../../../controllers/model_controller.dart';
// Update the import path below to the correct relative path if the file exists elsewhere, for example:
import '../../../models/chat/session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/model.dart';
import '../../models/pages/add_online_model_dialog.dart';
import '../../models/widgets/model_detail_page.dart';

class ModelSettingPage extends StatefulWidget {
  final bool embedded;

  const ModelSettingPage({super.key, this.embedded = false});

  @override
  State<ModelSettingPage> createState() => _ModelSettingPageState();

  // 静态方法用于显示独立窗口
  static Future<void> showAsDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 禁用点击外部关闭
      useSafeArea: false,
      builder: (BuildContext context) {
        return const ModelSettingDialog();
      },
    );
  }
}

// 独立窗口版本的模型设置页面
class ModelSettingDialog extends StatelessWidget {
  const ModelSettingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width > 1200 ? screenSize.width * 0.1 : 40,
        vertical: screenSize.height > 800 ? screenSize.height * 0.05 : 20,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: const ModelSettingPage(),
        ),
      ),
    );
  }
}

class _ModelSettingPageState extends State<ModelSettingPage> {
  int _selectedTab = 0;
  final String _apiUrl = 'http://127.0.0.1:11434/api';

  List<ChatModel> _availableModels = [];
  final sessionController = Get.find<SessionController>();
  final modelController = Get.find<ModelController>();
  List<ChatSession> get chatSessions => sessionController.sessions;
  ChatSession? get currentSession => sessionController.currentSession.value;
  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  // 加载模型列表
  Future<void> _loadModels() async {
    final models = await modelController.loadModels();

    setState(() {
      _availableModels = models;
      // 确保选中的索引在有效范围内
      if (_availableModels.isEmpty) {
        _selectedTab = -1;
      } else if (_selectedTab >= _availableModels.length || _selectedTab < 0) {
        _selectedTab = 0;
      }
    });
  }

  // 从模型名称推断提供商
  /// 根据模型ID查找显示名称（保留原始大小写）
  String _resolveModelDisplayName(String modelId) {
    for (var p in onlineProviders) {
      if (p['models'] != null) {
        for (var model in p['models']) {
          if (model['id'] == modelId) {
            return model['name'] ?? modelId;
          }
        }
      }
    }
    return modelId;
  }

  // 清理使用已删除模型的会话中的 chatModel 字段
  Future<void> _clearModelFromSessions(String modelId) async {
    try {
      // 获取当前会话列表的副本
      final currentSessions = List<ChatSession>.from(chatSessions);
      List<ChatSession> updatedSessions = [];
      bool hasUpdates = false;

      // 遍历所有会话，检查是否使用了被删除的模型
      for (final session in currentSessions) {
        if (session.modelId == modelId) {
          // 创建清空模型的新会话对象
          final updatedSession = session.copyWith(clearChatModel: true);
          updatedSessions.add(updatedSession);
          hasUpdates = true;
          debugPrint('清理会话 ${session.name} 中的已删除模型');
        } else {
          // 保持原会话不变
          updatedSessions.add(session);
        }
      }

      // 如果有更新，保存会话数据
      if (hasUpdates) {
        await sessionController.setSessions(updatedSessions);

        // 如果当前会话使用了被删除的模型，需要更新当前会话引用
        if (currentSession?.modelId == modelId) {
          final updatedCurrentSession = updatedSessions.firstWhere(
            (session) => session.sessionId == currentSession!.sessionId,
            orElse: () => currentSession!,
          );
          await sessionController.setCurrentSession(updatedCurrentSession);
        }

        debugPrint('已成功清理使用已删除模型的会话');
      }
    } catch (e) {
      debugPrint('清理会话模型信息时出错: $e');
      // 在出错时不重新抛出异常，避免影响模型删除流程
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Row(
      children: [
        // 左侧导航菜单
        _buildLeftNavigation(),
        // 分割线
        Container(width: 1, color: Theme.of(context).dividerColor),
        // 右侧内容区域
        Expanded(child: _buildRightContent()),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: StandardAppBar(
        title: AppLocalizations.of(context)!.modelManagement,
        showBottomDivider: true,
      ),
      body: body,
    );
  }

  Widget _buildLeftNavigation() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _availableModels.length,
              itemBuilder: (context, index) {
                final model = _availableModels[index];
                final isSelected = _selectedTab == index;
                return _buildModelNavItem(
                  model.name,
                  _resolveModelDisplayName(model.model),
                  true,
                  index,
                  isSelected,
                );
              },
            ),
          ),
          // 底部添加按钮
          Container(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showOnlineModelDialog,
                icon: const Icon(Icons.add, size: 10),
                label: Text(
                  AppLocalizations.of(context)!.addModel,
                  style: const TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  // shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelNavItem(
    String modelName,
    String fullName,
    bool isActive,
    int index,
    bool isSelected,
  ) {
    final model = _availableModels[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            isSelected
                ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
                : null,
      ),
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          _showModelContextMenu(context, details.globalPosition, model);
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // 模型图标
                SizedBox(
                  width: 16,
                  height: 16,
                  child: _buildModelIconWidget(
                    model.name,
                    isSelected,
                    provider: model.platform,
                  ),
                ),
                const SizedBox(width: 8),
                // 模型信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // 完整名称
                      Text(
                        fullName,
                        style: TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // 业务类型标签
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModelContextMenu(
    BuildContext context,
    Offset position,
    ChatModel model,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      items: [
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.copy,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.copyModel,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          onTap: () => _copyModel(model),
        ),
      ],
    );
  }

  void _copyModel(ChatModel model) async {
    // 生成新的名称
    String newName = _generateCopyName(model.name);

    // 调试：打印原模型的API密钥
    print('=== 复制模型调试信息 ===');
    print('原模型名称: ${model.name}');
    print('原模型API密钥: ${model.apiKey ?? "null"}');
    print('原模型API URL: ${model.apiUrl ?? "null"}');
    print('原模型platform: ${model.platform ?? "null"}');

    // 创建模型副本，只保留基本配置，排除会话、MCP、知识库等设置
    ChatModel copiedModel = model.copyWith(
      modelId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 调试：打印复制后的模型信息
    print('复制后模型名称: ${copiedModel.name}');
    print('复制后模型API密钥: ${copiedModel.apiKey ?? "null"}');
    print('复制后模型API URL: ${copiedModel.apiUrl ?? "null"}');
    print('复制后模型platform: ${copiedModel.platform ?? "null"}');
    print('========================');

    // 添加到模型列表并保存
    setState(() {
      _availableModels.add(copiedModel);
    });
    await modelController.addModel(copiedModel);

    // 显示成功提示
    SnackBarUtils.showSuccess(
      context,
      AppLocalizations.of(context)!.modelCopied(newName),
    );
  }

  String _generateCopyName(String originalName) {
    String baseName = originalName;
    int copyNumber = 1;

    // 如果原名称已经包含 "的副本"，提取基础名称
    RegExp copyPattern = RegExp(r'^(.+?)(?:的副本(?:\s*\((\d+)\))?)?$');
    RegExpMatch? match = copyPattern.firstMatch(originalName);
    if (match != null) {
      baseName = match.group(1)!;
      if (match.group(2) != null) {
        copyNumber = int.parse(match.group(2)!) + 1;
      }
    }

    // 检查名称是否已存在，如果存在则递增数字
    String newName;
    do {
      if (copyNumber == 1) {
        newName = AppLocalizations.of(context)!.copyOf(baseName);
      } else {
        newName = AppLocalizations.of(context)!.copyOfN(baseName, copyNumber);
      }
      copyNumber++;
    } while (_availableModels.any((model) => model.name == newName));

    return newName;
  }

  Widget _buildRightContent() {
    if (_availableModels.isNotEmpty &&
        _selectedTab >= 0 &&
        _selectedTab < _availableModels.length) {
      final selectedModel = _availableModels[_selectedTab];
      return _buildModelDetailContent(selectedModel);
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noModels,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.clickAddModelHint,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelDetailContent(ChatModel model) {
    return ModelDetailPage(
      key: ValueKey(model.modelId), // 使用modelId作为Key，确保不同模型时重新创建组件
      model: model,
      apiUrl: _apiUrl,
      onModelUpdated: (updatedModel) async {
        setState(() {
          final index = _availableModels.indexWhere(
            (m) => m.modelId == updatedModel.modelId,
          );
          if (index != -1) {
            _availableModels[index] = updatedModel;
          }
        });

        // 保存模型到本地存储
        await modelController.updateModel(updatedModel);

        // 同步更新所有使用该模型的会话
        await sessionController.updateModelInSessions(updatedModel);

        // 显示成功消息
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(AppLocalizations.of(context)!.modelUpdatedNotify(updatedModel.name)),
          //     duration: const Duration(seconds: 2),
          //     backgroundColor: const Color(0xFF10B981),
          //   ),
          // );
          SnackBarUtils.showSuccess(
            context,
            AppLocalizations.of(context)!.modelUpdatedNotify(updatedModel.name),
          );
        }
      },
      onModelDeleted: (modelId) async {
        setState(() {
          _availableModels.removeWhere((m) => m.modelId == modelId);
          // 如果删除的是当前选中的模型，重置选中状态
          if (_selectedTab >= _availableModels.length) {
            _selectedTab = _availableModels.isNotEmpty ? 0 : -1;
          }
        });

        // 清理使用该模型的会话中的 chatModel 字段
        await _clearModelFromSessions(modelId);

        await modelController.deleteModel(modelId);
      },
    );
  }

  // 显示添加模型类型选择框
  // 显示本地模型对话框
  // 显示在线模型对话框
  void _showOnlineModelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddOnlineModelDialog();
      },
    ).then((result) async {
      if (result != null) {
        final newModel = ChatModel.fromMap(result);
        setState(() {
          _availableModels.add(newModel);
        });
        await modelController.addModel(newModel);
      }
    });
  }

  // 根据模型名称或平台构建对应的图标Widget
  Widget _buildModelIconWidget(
    String modelName,
    bool isSelected, {
    String? provider,
  }) {
    final iconPath = ModelController.resolveIconPath(
      platform: provider,
      modelName: modelName,
    );

    // 如果找到对应的图标文件，使用图片
    if (iconPath != null) {
      return Image.asset(
        iconPath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 如果图片加载失败，回退到图标
          return Icon(
            Icons.horizontal_rule,
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 9,
          );
        },
      );
    } else {
      // 没有对应图标文件的模型使用默认图标
      return Icon(
        Icons.laptop,
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        size: 9,
      );
    }
  }
}

// 添加模型对话框
// 添加在线模型对话框
// 模型详情页面类
