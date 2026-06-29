# core/skills/ - 技能管理

## 职责

管理 AI 技能（基于 SKILL.md 文件的提示词能力），包括加载、缓存、CRUD 和文件系统持久化。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `skill_service.dart` | 317 | 技能业务逻辑：内存缓存、文件系统 CRUD、技能提示词注入会话、内置技能检测 |
| `skill_storage_service.dart` | 224 | 技能文件系统：管理 `~/.llmwork/skills/` 目录，从 Flutter assets 复制内置技能 |

## 技能文件结构

```
~/.llmwork/skills/
└── {skill-name}/
    ├── SKILL.md          # 技能定义（frontmatter + 提示词内容）
    └── references/       # 可选的参考文件
```

## SKILL.md 格式

```markdown
---
name: 技能名称
description: 技能描述
tools:
  - name: tool_name
    description: 工具描述
---

# 提示词内容

在此编写技能的提示词...
```
