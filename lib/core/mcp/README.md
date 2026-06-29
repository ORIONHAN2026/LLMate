# core/mcp/ - MCP 协议服务

## 职责

实现 Model Context Protocol (MCP) 客户端，管理与 MCP 服务器的连接、工具发现和调用。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `mcp_service.dart` | 1320 | **MCP 客户端服务**：连接/断开 MCP 服务器、工具发现、工具调用、SSE 传输、服务器生命周期管理 |
| `mcp_json_parser.dart` | 191 | MCP 配置解析器：支持多种 JSON 格式（mcpServers、直接配置、数组）标准化为统一配置结构 |

## MCP 连接方式

- **Stdio** — 通过标准输入/输出与本地进程通信
- **SSE (URL)** — 通过 HTTP SSE 与远程服务器通信

## 使用流程

```dart
// 1. 解析配置
final config = McpJsonParser.parse(jsonString);

// 2. 连接服务器
await McpService.connect(serverConfig);

// 3. 发现工具
final tools = await McpService.listTools(serverName);

// 4. 调用工具
final result = await McpService.callTool(serverName, toolName, args);
```
