# 记忆系统测试脚本

## 测试目标
验证L0-L3分层记忆系统的工作流程

## 测试环境
- 确保 `MemoryInitializer.initialize()` 已在main.dart中调用
- 确保有可用的LLM模型配置

---

## 测试场景：Flutter聊天应用开发

### 第一轮对话（L0记录）

**用户输入：**
```
我想做一个Flutter聊天应用，类似于微信那种界面
```

**预期AI回复：**
```
好的！Flutter非常适合开发聊天应用。我们可以使用：
- ListView.builder 展示消息列表
- TextField + IconButton 做输入框
- GetX 或 Provider 做状态管理
你需要我详细讲解哪个部分？
```

**验证：**
- ✅ L0计数 +1
- ✅ 存储位置：`~/Documents/memory/l0/test_session.jsonl`

---

### 第二轮对话（偏好记录）

**用户输入：**
```
我喜欢用GetX，感觉比较简洁，不喜欢Provider那种模板代码
```

**预期AI回复：**
```
明白！GetX确实更轻量，语法也更简洁。它集成了状态管理、路由管理和依赖注入。
那我们就用GetX来构建这个聊天应用吧！
```

**验证：**
- ✅ L0计数 +1
- 记忆类型：preference

---

### 第三轮对话（技术偏好）

**用户输入：**
```
界面要用深色模式，我眼睛对亮色系比较敏感
```

**预期AI回复：**
```
收到！深色模式对眼睛更友好，特别是长时间使用。
Flutter的ThemeData可以轻松配置深色主题，
我会记住你偏好深色模式的设置。
```

**验证：**
- ✅ L0计数 +1
- 记忆类型：preference

---

### 第四轮对话（工具选择）

**用户输入：**
```
后端我想用Firebase，不想自己搭建服务器
```

**预期AI回复：**
```
Firebase是不错的选择！它提供：
- Firestore 实时数据库
- Firebase Auth 用户认证
- Cloud Storage 图片存储
- FCM 推送通知
非常适合快速开发聊天应用。
```

**验证：**
- ✅ L0计数 +1
- 记忆类型：tool

---

### 第五轮对话（目标明确）→ 触发L1提取

**用户输入：**
```
我的目标是做一个支持文字、图片、语音的完整聊天应用
```

**预期AI回复：**
```
很棒的目标！完整功能需要：
1. 文字消息 - 基础功能
2. 图片发送 - image_picker + Firebase Storage
3. 语音消息 - record 插件 + 音频播放
我们可以一步步来实现这些功能。
```

**验证（关键）：**
- ✅ L0计数 = 5
- ⏳ 等待2-3秒，触发L1自动提取
- ✅ 检查L1记忆是否生成

---

### 第六轮对话（验证L1召回）

**用户输入：**
```
用什么状态管理比较好？
```

**预期行为：**
AI回复前，Prompt中应该自动注入之前的记忆：

```markdown
## 相关历史记忆
1. 用户偏好使用GetX进行状态管理，不喜欢Provider的模板代码

## 当前问题
用什么状态管理比较好？
```

**预期AI回复：**
```
根据你之前的偏好，我推荐使用GetX！
（因为记忆系统会注入你之前说喜欢GetX的信息）
```

**验证：**
- ✅ 回复中提到GetX（证明记忆被召回）

---

### 第七轮对话（代码风格）

**用户输入：**
```
我喜欢用函数式编程的风格写代码，不太喜欢面向对象那种繁琐的类定义
```

**预期AI回复：**
```
收到！Dart支持函数式编程，GetX也支持响应式编程风格。
我们可以多用extension、arrow function和stream来保持代码简洁。
```

---

### 第八轮对话（项目结构）

**用户输入：**
```
项目结构怎么组织？我喜欢按功能模块划分，不喜欢按类型划分
```

**预期AI回复：**
```
按功能模块划分确实更清晰！推荐结构：
lib/
├── modules/
│   ├── chat/       # 聊天模块
│   ├── auth/       # 认证模块
│   └── profile/    # 个人资料
├── services/       # 全局服务
└── main.dart
```

---

### 第九轮对话（UI偏好）

**用户输入：**
```
UI要Material Design 3风格，圆角大一些，比较现代
```

**预期AI回复：**
```
Material 3确实更现代！Flutter 3.0+ 支持Material 3，
可以用ThemeData.useMaterial3: true开启，
配合RoundedRectangleBorder实现大圆角效果。
```

---

### 第十轮对话（性能要求）→ 继续积累L1

**用户输入：**
```
性能很重要，消息列表要流畅，不能卡顿
```

**预期AI回复：**
```
性能优化关键点：
- ListView.builder懒加载
- 图片压缩和缓存
- 消息分页加载
- 避免不必要的 rebuild
```

**验证：**
- ✅ L0计数 = 10
- ⏳ 触发更多L1提取

---

## 验证L1记忆

### 查看统计

在应用内添加调试按钮或日志：

```dart
final stats = await memoryService.getStats('test_session');
print('L0: ${stats.l0Count}');
print('L1: ${stats.l1Count}');
print('L2: ${stats.l2Count}');
print('L3: ${stats.hasL3}');
```

### 预期结果（第10轮后）

```
L0: 10
L1: 5-8 (提取的记忆数)
L2: 0-1 (如果达到3条未聚类记忆)
L3: false
```

---

## 继续对话（触发L2场景聚合）

### 第11-15轮：继续积累L1记忆

重复类似对话，直到L1记忆达到10条以上，触发L2聚合。

**快速触发方式：**
连续发送5轮包含明确偏好的短句：

```
11. "我喜欢用VS Code写代码"
12. "主题色用蓝色系"
13. "字体用Roboto"
14. "少用第三方库，喜欢原生"
15. "注释要详细，方便维护"
```

---

## 验证L2场景

### 强制触发L2聚合

```dart
await memoryService.flushSession('test_session');
```

### 查看场景

```dart
final export = await memoryService.exportSession('test_session');
print(jsonEncode(export['l2Scenes'], indent: 2));
```

### 预期输出

```json
{
  "l2Scenes": [
    {
      "title": "Flutter项目偏好",
      "description": "用户正在开发Flutter聊天应用，偏好GetX、深色模式、Material 3设计",
      "tags": ["Flutter", "GetX", "深色模式", "UI设计"]
    }
  ]
}
```

---

## 最终验证：记忆召回效果

### 测试查询1

**用户输入：**
```
界面用什么设计规范？
```

**预期召回的记忆：**
- 偏好深色模式
- 偏好Material 3风格
- 偏好大圆角现代设计

**预期AI回复特征：**
- 提到深色模式
- 提到Material 3
- 提到圆角设计

### 测试查询2

**用户输入：**
```
状态管理你推荐什么？
```

**预期召回的记忆：**
- 喜欢GetX
- 不喜欢Provider
- 喜欢函数式编程

**预期AI回复特征：**
- 推荐GetX
- 提到函数式风格
- 不提Provider

---

## 成功标准

| 检查项 | 成功标志 |
|--------|---------|
| L0记录 | 每轮对话后计数增加 |
| L1提取 | 第5轮后L1 > 0 |
| L2聚合 | flush后L2 > 0 |
| 记忆召回 | AI回复中体现历史偏好 |
| 系统提示 | 日志显示记忆被注入Prompt |

---

## 调试技巧

### 1. 查看日志

关注控制台输出：
```
📝 L0 captured: test_session, turn: 1
📝 L0 captured: test_session, turn: 2
...
🔍 Running L1 extraction for test_session
✅ L1 extracted: 3 memories for test_session
```

### 2. 导出数据检查

```dart
final export = await memoryService.exportSession('test_session');
// 保存到文件查看
File('export.json').writeAsString(jsonEncode(export));
```

### 3. 强制刷新

```dart
// 强制处理所有层级
await memoryService.flushSession('test_session');
```

---

## 测试时间预估

| 步骤 | 时间 |
|------|------|
| 5轮对话（触发L1） | 2-3分钟 |
| 10轮对话（触发L2） | 5-8分钟 |
| 验证召回效果 | 1-2分钟 |
| **总计** | **10-15分钟** |
