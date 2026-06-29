# core/tools/executors/ - 脚本执行器

## 职责

为 LLM 提供执行用户脚本的能力，支持内联代码和文件执行。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `python_tool_service.dart` | 163 | Python 脚本执行器：支持内联代码或文件执行，可选 pip 依赖安装 |
| `node_tool_service.dart` | 151 | Node.js 脚本执行器：支持内联 JavaScript/TypeScript 或文件执行，可选 npm 依赖安装 |

## 安全注意事项

- 脚本在隔离的子进程中执行
- 支持超时控制
- 输出大小限制，防止内存溢出
