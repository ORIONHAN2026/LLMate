# controllers/ - 全局状态管理

## 职责

基于 GetX 的全局状态控制器，管理跨功能的共享状态。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `session_controller.dart` | 661 | **会话控制器**：会话 CRUD、消息更新、懒加载、定时任务调度 |
| `theme_controller.dart` | 90 | 主题控制器：亮色/暗色/跟随系统，持久化切换 |
| `locale_controller.dart` | 54 | 语言控制器：中文/英文切换，持久化 |

## 使用方式

```dart
// 获取控制器
final sessionCtrl = Get.find<SessionController>();
final themeCtrl = Get.find<ThemeController>();

// 响应式更新
Obx(() => Text(themeCtrl.themeMode.value.name));

// 操作
await sessionCtrl.addSession(newSession);
themeCtrl.toggleTheme();
```

## 初始化顺序

在 `main.dart` 中按依赖顺序初始化：
1. `StorageService` (数据层)
2. `ThemeController` (主题)
3. `LocaleController` (语言)
4. `ModelController` (模型列表)
5. `SessionController` (会话)
7. `McpController` (MCP 配置)
