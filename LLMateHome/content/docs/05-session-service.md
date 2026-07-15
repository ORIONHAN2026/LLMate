---
title: 会话服务地址
type: docs
prev: docs/04-create-session
next: docs/06-usage-management
weight: 5
---

LLMate 内置本地 HTTP/HTTPS 代理服务，将配置好的大模型接口透传为 OpenAI 兼容 API。

### 启动服务

1. 在应用设置中找到 **本地 HTTP 服务**
2. 配置服务参数：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 监听端口 | HTTP 服务端口号 | `80` |
| 启用 HTTPS | 是否启用加密传输 | 否 |
| 允许外部访问 | 是否允许局域网内其他设备调用 | 是 |
| API Key 认证 | 是否要求调用方提供密钥 | 可选 |

### 使用方式

服务启动后，企业内部系统可通过标准 OpenAI API 格式调用：

```bash
curl http://localhost:80/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "你好"}]
  }'
```

每个会话的服务地址可在会话设置中查看和复制，方便分发给对应部门使用。
