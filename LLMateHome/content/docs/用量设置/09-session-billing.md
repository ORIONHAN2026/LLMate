---
title: 用量查询
type: docs
prev: docs/用量设置/08-session-usage-quota
next: docs/MCP设置/11-manage-mcp
weight: 9
---

用量查询展示本会话的**实时用量与费用统计**，帮助管理员核对每个会话的实际消耗（只读，无需配置）。

### 统计项

- **累计输入 Token** / **累计输出 Token**：分别统计请求与回复消耗的 Token
- **累计费用**：按当前绑定模型的定价自动计算
- **模型定价**：展示当前绑定模型的输入 / 输出单价

{{< figure src="images/session-billing/step-billing.png" caption="用量查询：Token、费用与定价" >}}

> 费用查询配合 [用量配额](/docs/用量设置/08-session-usage-quota/) 的额度策略，可形成"设定上限 → 监控消耗 → 核对费用"的闭环管理。
