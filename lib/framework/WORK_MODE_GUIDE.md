# 工作模式创建指南

本文档描述了创建新工作模式的完整流程，确保架构一致性。

## 一、目录结构

```
lib/framework/modes/
├── work_mode_strategy.dart     # 策略接口（已有）
├── work_mode_sidebar.dart      # 侧边栏接口（已有）
├── work_mode_factory.dart      # 策略工厂（需注册）
├── mode_sidebars.dart          # 侧边栏工厂（需注册）
├── mode_utils.dart             # 共享工具（已有）
├── {new}_mode.dart             # 新模式实现（需创建）

lib/widgets/
├── {new}_sidebar.dart          # 新模式侧边栏（需创建）

lib/services/system_tool_service.dart  # 工具定义（需添加）

lib/framework/common/system_prompts.dart  # 系统提示词（需添加）
```

## 二、文件存储路径

所有模式文件统一存储在 `{workDir}/.llmwork/{mode}/` 下：

```
{workDir}/.llmwork/
├── {new}/
│   ├── note.md           # 备忘录（可选，各模式共享）
│   ├── xxx.md            # 模式专属文件
│   └── subfolder/        # 模式专属子目录（可选）
```

## 三、创建步骤

### Step 1: StoragePaths 添加文件路径方法

在 `lib/storage/storage_paths.dart` 中添加：

```dart
/// 新模式文件
static String newModeFile({
  required String sessionId,
  String? workDirectory,
}) => p.join(
  modeDir(sessionId: sessionId, workMode: 'new', workDirectory: workDirectory),
  'xxx.md',
);
```

### Step 2: 创建模式策略类

创建 `lib/framework/modes/new_mode.dart`：

```dart
import 'package:get/get.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../services/system_tool_service.dart';
import '../../storage/storage_paths.dart';
import '../common/system_prompts.dart';
import 'work_mode_strategy.dart';
import 'work_mode_sidebar.dart';
import 'mode_utils.dart';

/// 新模式
class NewMode extends WorkModeStrategy {
  @override
  String get modeName => 'new';

  @override
  Future<List<Map<String, dynamic>>> buildMessages({
    required ChatModel? model,
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    final messages = <Map<String, dynamic>>[];
    final effectiveWorkDir = getEffectiveWorkDir(session);
    final modeDirPath = StoragePaths.modeDir(
      sessionId: session.sessionId,
      workMode: 'new',
      workDirectory: session.workDirectory,
    );

    // 1. 通用系统提示词
    messages.addAll(buildBaseSystemMessages(
      model: model,
      session: session,
      thinkEnabled: session.deepThink,
      workDir: effectiveWorkDir,
    ));

    // 2. 模式专用提示词
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.newMode(effectiveWorkDir, modeDirPath),
    });

    // 3. 记忆上下文
    final memoryCtx = buildMemoryContext(session);
    if (memoryCtx.isNotEmpty) {
      messages.add({'role': 'system', 'content': memoryCtx});
    }

    // 4. 历史消息
    if (session.messages.isNotEmpty) {
      appendHistoryMessages(messages, session, userMessage);
    }

    // 5. 核心规则 + 语言
    messages.add({'role': 'system', 'content': CommonSystemPrompts.coreRules});
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.responseLanguage(
        Get.locale?.languageCode ?? 'zh',
      ),
    });

    // 6. 用户消息
    messages.add({'role': 'user', 'content': buildUserContent(userMessage)});

    return messages;
  }

  @override
  List<Map<String, dynamic>> buildTools(ChatSession? session) {
    final allTools = <Map<String, dynamic>>[];

    // 基础工具
    allTools.addAll(SystemToolService.buildOpenAIToolsFormat());

    // 模式专属工具（直接内联）
    allTools.addAll([
      {
        'type': 'function',
        'function': {
          'name': 'new_tool_update',
          'description': '工具描述',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '内容'},
            },
            'required': ['content'],
          },
        },
      },
    ]);

    // MCP + Skill 工具
    allTools.addAll(buildMcpTools(session));
    allTools.addAll(buildSkillTools(session));
    return allTools;
  }
}

/// 新模式侧边栏
class NewModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 2;

  @override
  List<String> get tabTitles => ['Tab1', 'Tab2'];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    switch (index) {
      case 0:
        return _buildTab1(context, sessionId, workDirectory: workDirectory);
      case 1:
        return _buildTab2(context, sessionId, workDirectory: workDirectory);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTab1(BuildContext context, String sessionId, {String? workDirectory}) {
    // 使用 modeDir 加载文件
    final path = '${StoragePaths.modeDir(sessionId: sessionId, workMode: 'new', workDirectory: workDirectory)}/xxx.md';
    // ... FutureBuilder 加载文件
  }
}
```

### Step 3: 添加系统提示词

在 `lib/framework/common/system_prompts.dart` 中添加：

```dart
/// 新模式提示词
static String newMode(String workDir, String modeDir) {
  return '''## 🎯 新模式

你处于新模式下，专注于 XXX 场景。

### 核心要求

**必须使用工具保存内容，这样用户才能在右侧边栏查看。**

### 工具使用

| 工具 | 用途 | 存储位置 |
|------|------|----------|
| `new_tool_update` | 更新文件 | `$modeDir/xxx.md` |

### 回复风格

- 使用 `[🎯 助手]` 作为回复前缀
''';
}
```

### Step 4: 添加工具定义

在 `lib/services/system_tool_service.dart` 中：

1. 添加工具常量：
```dart
static const String newToolUpdateTool = 'new_tool_update';
```

2. 添加工具定义到 `_tools` 列表：
```dart
SystemToolDefinition(
  name: newToolUpdateTool,
  description: '工具描述',
  parameters: {
    'type': 'object',
    'properties': {
      'content': {'type': 'string', 'description': '内容'},
    },
    'required': ['content'],
  },
),
```

3. 添加工具执行方法：
```dart
static Future<Map<String, dynamic>> _executeNewToolUpdate({
  required ChatSession session,
  required Map<String, dynamic> arguments,
  required String callId,
}) async {
  final content = arguments['content'] as String? ?? '';
  final filePath = StoragePaths.newModeFile(
    sessionId: session.sessionId,
    workDirectory: session.workDirectory,
  );
  await StoragePaths.ensureModeDir(
    sessionId: session.sessionId,
    workMode: 'new',
    workDirectory: session.workDirectory,
  );
  await File(filePath).writeAsString(content);
  return {
    'id': callId,
    'name': newToolUpdateTool,
    'result': jsonEncode({'ok': true}),
    'isError': false,
  };
}
```

4. 在 `execute` 方法的 switch 中添加：
```dart
case newToolUpdateTool:
  return _executeNewToolUpdate(session: session, arguments: arguments, callId: callId);
```

### Step 5: 注册到工厂

在 `lib/framework/modes/work_mode_factory.dart` 中添加：
```dart
case 'new':
  return NewMode();
```

在 `lib/framework/modes/mode_sidebars.dart` 中添加：
```dart
case 'new':
  return NewModeSidebar();
```

### Step 6: 注册到 UI

1. **模式切换按钮** - `lib/widgets/chat_input_widget.dart` 的 `_showModePicker` 方法：
```dart
_ModeItem('new', CupertinoIcons.xxx, '新模式', '描述'),
```

2. **模式切换逻辑** - `_buildWorkModeToggle` 方法的 switch 中添加：
```dart
case 'new':
  icon = CupertinoIcons.xxx;
  label = '新模式';
  break;
```

3. **循环切换逻辑** - `onTap` 中的 switch 添加：
```dart
case 'new':
  newMode = 'conversation';  // 或下一个模式
  break;
```

### Step 7: 更新 barrel export

在 `lib/framework/llm_framework.dart` 中添加：
```dart
export 'modes/new_mode.dart';
```

## 四、关键检查清单

创建新模式后，确认以下事项：

- [ ] StoragePaths 添加了文件路径方法
- [ ] 模式策略类实现了 `buildMessages` 和 `buildTools`
- [ ] 侧边栏实现了 `buildTabContent` 并传递 `workDirectory`
- [ ] 系统提示词已添加
- [ ] 工具定义已添加到 `_tools` 列表
- [ ] 工具执行方法已添加到 `SystemToolService`
- [ ] 已注册到 `work_mode_factory.dart`
- [ ] 已注册到 `mode_sidebars.dart`
- [ ] 已添加到 UI 模式选择菜单
- [ ] 已添加到 barrel export
- [ ] `_detectFileType` 中添加了目录检测逻辑
- [ ] 运行 `flutter analyze` 无错误

## 五、文件读写规范

### 写入文件
```dart
// SystemToolService 中
final filePath = StoragePaths.newModeFile(
  sessionId: session.sessionId,
  workDirectory: session.workDirectory,
);
await StoragePaths.ensureModeDir(
  sessionId: session.sessionId,
  workMode: 'new',
  workDirectory: session.workDirectory,
);
await File(filePath).writeAsString(content);
```

### 读取文件
```dart
// 侧边栏中
final path = StoragePaths.modeDir(
  sessionId: sessionId,
  workMode: 'new',
  workDirectory: workDirectory,
);
final content = await FileStorage.readText('$path/xxx.md');
```

## 六、目录检测逻辑

在 `chat_input_widget.dart` 的 `_detectFileType` 方法中添加：

```dart
if (await Directory(p.join(llmworkDir.path, 'new')).exists()) {
  debugPrint('✅ 检测到 .llmwork/new 目录');
  return 'new';
}
```

## 七、注意事项

1. **workDirectory 必须传递** - 所有文件读写都必须使用 `workDirectory` 参数
2. **工具定义直接内联** - 不要使用 `buildToolsFromDefinitions`，直接在 `buildTools` 中写工具定义
3. **侧边栏 FutureBuilder key** - 必须包含 `workDirectory`，否则刷新时不会重新加载
4. **文件路径统一** - 使用 `StoragePaths.modeDir()` 确保路径一致性
5. **隐藏目录** - `.llmwork/` 以点开头，在 Finder 中默认隐藏
