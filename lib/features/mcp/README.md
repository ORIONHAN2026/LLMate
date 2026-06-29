# features/mcp/ - MCP 管理模块

## 职责

管理 Model Context Protocol (MCP) 服务的配置、连接和生命周期。

## 目录结构

```
mcp/
├── pages/
│   └── mcp_management_page.dart     # MCP 管理页：列表/启停/添加/编辑/删除
├── controllers/
│   └── mcp_controller.dart          # 全局 MCP 控制器：加载、缓存、查找配置
└── storage/
    └── mcp_storage_manager.dart     # MCP 数据持久化（~/.llmwork/mcps/）
```

## 使用方式

MCP 服务通过 JSON 配置添加（支持 mcpServers 格式或直接配置），不包含内置服务器实现。

```dart
// 添加 MCP
final mcp = Mcp(mcpId: 'mcp_xxx', name: 'xxx', command: '...', args: [...]);
await McpController.addService(mcp);

// 连接并调用工具
await McpService.connect(mcp);
final result = await McpService.callTool('xxx', 'tool_name', {});
```
