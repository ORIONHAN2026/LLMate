---
name: 会议通知
description: 生成标准格式的会议通知Word文档。收集会议信息后调用系统内置工具 word_create_document 创建文档。输出文件保存至 /Users/orion/Documents/WorkBuddy工作空间/会议通知/，文件名格式：会议通知单_【主题】.docx。触发词：会议通知、会议通知单、生成会议通知、创建会议通知。
agent_created: true
---

# 会议通知单生成技能

根据用户提供的会议信息，调用系统内置工具 `word_create_document` 生成标准格式的会议通知Word文档。

## 执行流程

### Step 1: 收集信息

从用户输入中提取以下字段。如果用户未提供某些字段，主动询问：

| 字段 | 说明 | 示例 |
|------|------|------|
| 会议主题 | 会议名称 | 电商产品讨论会 |
| 时间 | 日期+星期+时间段 | 2026年5月16日（周六）下午 13:00 |
| 地点 | 会议室或地址 | 1号会议室 |
| 会议议程 | 多个议题用分号或换行分隔 | 议题1：现状分析；议题2：方案讨论 |
| 参会人员 | 部门或人员名单 | 产品部门、技术部门 |
| 联系人 | 姓名+电话 | 娜姐，电话：2222222 |

### Step 2: 调用 word_create_document 生成文档

使用系统内置工具 `word_create_document` 创建文档，参数规则如下：

```
工具名：word_create_document
参数：
  title: "会议通知单"
  fileName: "会议通知单_【主题】"
  outputDirectory: "/Users/orion/Documents/WorkBuddy工作空间/会议通知"
  paragraphs:
    - {text: "主题：【会议主题】", bold: true}
  tables:
    - headers: ["项目", "详情"]
      rows:
        - ["时间", "【时间】"]
        - ["地点", "【地点】"]
        - ["参会人员", "【参会人员】"]
        - ["联系人", "【联系人】"]
  sections:
    - heading: "会议议程"
      level: 2
      paragraphs:
        - {text: "【议题1】", listType: "number"}
        - {text: "【议题2】", listType: "number"}
```

**参数说明**：

- `title`：固定为 `"会议通知单"`
- `fileName`：格式为 `会议通知单_【主题】`（不需要写 .docx 后缀，系统自动添加）
- `outputDirectory`：固定为 `/Users/orion/Documents/WorkBuddy工作空间/会议通知`
- `paragraphs`：用 `{text, bold:true}` 加粗显示会议主题
- `tables`：用表格呈现时间、地点、参会人员、联系人等字段（key-value 形式）
- `sections`：单独一个"会议议程"章节，level=2（二级标题），议程项用 `listType: "number"` 有序列表
- 未提供的字段填 `"（待定）"`

### Step 3: 输出

文档创建成功后，告知用户文件保存路径。

## 格式建议

1. 时间格式：「YYYY年M月D日（周X）[上午/下午] HH:MM」
2. 联系人格式：「姓名，电话：XXXXXXX」
3. 会议议程多个议题用有序列表（listType: number）
4. 未提供的字段标注为"（待定）"，用户可后续在Word中补充

## 调用示例

用户输入："给我生成一个6月5号关于大都会项目优化的会议单，地点资产公司5楼，议题项目优化，时间全天"

应调用：
```json
{
  "title": "会议通知单",
  "fileName": "会议通知单_大都会项目优化",
  "outputDirectory": "/Users/orion/Documents/WorkBuddy工作空间/会议通知",
  "paragraphs": [
    {"text": "主题：大都会项目优化", "bold": true}
  ],
  "tables": [
    {
      "headers": ["项目", "详情"],
      "rows": [
        ["时间", "2026年6月5日（周五）全天"],
        ["地点", "资产公司5楼"],
        ["参会人员", "（待定）"],
        ["联系人", "（待定）"]
      ]
    }
  ],
  "sections": [
    {
      "heading": "会议议程",
      "level": 2,
      "paragraphs": [
        {"text": "项目优化", "listType": "number"}
      ]
    }
  ]
}
```
