---
title: 用量配额
type: docs
prev: docs/会话设置/07-session-service
next: docs/用量设置/09-session-billing
weight: 8
---

用量配额用于对本会话的 AI 资源消耗进行**限制与监控**，防止单个会话被滥用导致成本失控。

### 配置项

在会话设置页面的 **用量配额** 区域可进行以下配置：

- **启用用量限制**：总开关，开启后超额将自动拦截请求
- **Token 用量上限**：限制周期内累计使用的 Token 数量
- **费用预算上限**：限制周期内累计产生的调用费用
- **请求次数上限**：限制周期内的总请求次数
- **重置周期**：可选择**每日** / **每月** / **不重置**
- **手动重置**：一键清零当前周期的用量计数

{{< figure src="images/session-usage-quota/step-config.png" caption="用量配额：上限、重置周期与用量进度" >}}

### 用量状态监控

配置完成后，页面以**进度条**展示各项已用用量与上限的占比，超额时会高亮告警，便于实时掌握消耗情况。

{{< figure src="images/session-usage-quota/step-progress.png" caption="用量进度条展示，超额时高亮告警" >}}

> 建议按部门 / 岗位设定不同的额度策略；配合 [用量查询](/docs/用量设置/09-session-billing/) 可核对实际消耗与费用。
