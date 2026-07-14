# data/ - 数据持久化层

## 职责

提供基于 JSON 文件的本地数据存储，替代原 Isar 数据库方案。所有数据持久化到 `~/.llmate/` 目录。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `storage_service.dart` | 500 | **存储服务（单例）**：管理模型、会话、消息、MCP、设置、密钥等数据的读写 |
| `storage_paths.dart` | 314 | **路径管理**：集中管理 `~/.llmate/` 下所有存储位置的路径常量 |
| `file_storage.dart` | 89 | **底层文件操作**：JSON/文本文件的读/写/删工具类 |

## 存储结构

```
~/.llmate/
├── models.json              # 所有模型配置
├── mcp.json                 # 所有 MCP 服务配置
├── settings.json            # 通用设置（主题、语言等）
├── vendor_keys.json         # 供应商 API 密钥
└── chats/                   # 会话目录
    └── {sessionId}/
        ├── session.json     # 会话元数据
        ├── message.json     # 消息列表
        ├── memory.md        # 压缩记忆（markdown）
        ├── mcp.json         # MCP 绑定
        └── business.json    # 商务数据（合同等）
```

## 使用方式

```dart
// 获取存储实例
final store = StorageService.instance.store;

// 模型操作
final models = await ModelStore.getAll();
await ModelStore.save(model);

// 会话操作
final sessions = await SessionStore.getAll();
await SessionStore.save(session);
```
