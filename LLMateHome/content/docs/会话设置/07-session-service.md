---
title: API地址设置
type: docs
prev: docs/会话设置/06-session-prompt
next: docs/用量设置/08-session-usage-quota
weight: 7
---

LLMate 为每个会话提供独立的**API地址设置**（底层为内置的本地 HTTP/HTTPS 代理，将配置好的大模型接口透传为 OpenAI 兼容 API）。**拿到会话服务地址后，你可以使用任何支持 OpenAI 兼容协议的第三方大模型客户端**——如各类 ChatGPT 客户端、IDE 插件、自建应用等——直接调用该会话所配置的大模型接口，无需关心底层供应商、API 地址与密钥细节。

### 启动服务

1. 在应用设置中找到 **本地 HTTP 服务**

   {{< figure src="images/session-service/step1-open-settings.png" caption="在应用设置中进入「本地 HTTP 服务」" >}}

2. 配置服务参数：

   {{< figure src="images/session-service/step2-config-params.png" caption="配置监听端口、HTTPS、外部访问与 API Key 认证等参数" >}}

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 监听端口 | HTTP 服务端口号 | `80` |
| 启用 HTTPS | 是否启用加密传输 | 否 |
| 允许外部访问 | 是否允许局域网内其他设备调用 | 是 |
| API Key 认证 | 是否要求调用方提供密钥 | 可选 |

### 会话级服务配置

在会话设置页面，可针对单个会话配置以下服务参数：

- **服务地址**：本会话独立的 HTTP/HTTPS 服务地址，点击即可复制到剪贴板，供第三方客户端调用
- **API Key**：会话独立的请求密钥，可复制，也支持一键重置（重置后会生成新密钥）
- **免授权访问**：开关。开启后无需密钥即可使用本会话的模型接口（建议仅在可信内网开启）
- **禁用会话**：开关。开启后该会话的任何调用（包括应用内与外部 HTTP 调用）都会被拒绝

{{< figure src="images/session-service/step-session-config.png" caption="会话设置 - 服务配置：服务地址、API Key、免授权与禁用开关" >}}

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

{{< figure src="images/session-service/step3-copy-address.png" caption="在会话设置中查看并复制本会话的服务地址" >}}
