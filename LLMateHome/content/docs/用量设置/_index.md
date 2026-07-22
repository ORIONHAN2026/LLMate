---
title: 用量设置
type: docs
prev: docs/会话设置/07-session-service
next: docs/用量设置/08-session-usage-quota
weight: 6
---

用量设置用于对本会话的 AI 资源消耗进行**限制与监控**，防止单个会话被滥用导致成本失控。包含以下模块：

- **[用量配额](/docs/用量设置/08-session-usage-quota/)**：Token / 费用 / 请求次数上限、重置周期与用量监控
- **[用量查询](/docs/用量设置/09-session-billing/)**：本会话的实时用量与费用统计（只读）

> 用量配额用于"设定上限"，用量查询用于"核对费用"，两者配合形成"设定上限 → 监控消耗 → 核对费用"的闭环管理。
