# core/config/ - 功能开关

## 职责

从配置文件加载功能开关，控制 UI 功能的可见性。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `feature_toggle_service.dart` | 58 | 功能开关服务：从 `assets/config/feature_toggles.json` 读取开关配置 |

## 配置文件

路径：`assets/config/feature_toggles.json`

```json
{
  "memory_config": true,
  "scheduled_tasks": true
}
```
