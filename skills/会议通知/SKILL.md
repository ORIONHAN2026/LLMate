---
name: 会议通知
description: 基于会议通知单模板生成标准格式的会议通知Word文档。模板路径：/Users/orion/Documents/WorkBuddy工作空间/会议通知/会议通知单_电商产品讨论会.docx。输出文件保存至同一目录，文件名格式：会议通知单_【主题】.docx。触发词：会议通知、会议通知单、生成会议通知、创建会议通知。
agent_created: true
---

# 会议通知单生成技能

根据模板生成标准格式的会议通知Word文档，格式与模板完全一致。

## 模板信息

- 模板路径：`/Users/orion/Documents/WorkBuddy工作空间/会议通知/会议通知单_电商产品讨论会.docx`
- 输出目录：`/Users/orion/Documents/WorkBuddy工作空间/会议通知/`
- 文件名格式：`会议通知单_【主题】.docx`

## 模板格式规范

- **纸张**：A4（11906 x 16838 DXA），页边距上下左右各 1440 DXA（1英寸）
- **标题**：「会议通知单」，居中，加粗，20pt（sz=40），黑色，段前240/段后360
- **表格**：总宽 9000 DXA，2列（2000 + 7000），黑色单线边框 sz=4，单元格间距 10 DXA
- **标签列（左列 2000 DXA）**：灰色底色 #E6E6E6，居中，加粗，垂直居中，内边距 100 DXA
- **内容列（右列 7000 DXA）**：无底色，左对齐，垂直居中，内边距 100 DXA

### 各行高度
| 行 | 字段 | 行高(DXA) |
|----|------|-----------|
| 1 | 时间 | 自动 |
| 2 | 地点 | 自动 |
| 3 | 主题 | 322 |
| 4 | 会议议程 | 3391 |
| 5 | 参会人员 | 2226 |
| 6 | 联系人 | 586 |

### 字体
- 西文：Times New Roman
- 中文：主题字体（eastAsiaTheme）
- 正文字号：五号（sz=21, 10.5pt）

## 执行流程

### Step 1: 收集信息

从用户输入中提取以下字段。如果用户未提供某些字段，主动询问：

| 字段 | 说明 | 示例 |
|------|------|------|
| 会议主题 | 会议名称 | 电商产品讨论会 |
| 时间 | 日期+星期+时间段 | 2026年5月16日（周六）下午 13:00 |
| 地点 | 会议室或地址 | 1号会议室 |
| 会议议程 | 多个议题用换行分隔 | 议题1：... 议题2：... 议题3：... |
| 参会人员 | 部门或人员名单 | 产品部门、技术部门 |
| 联系人 | 姓名+电话 | 娜姐，电话：2222222 |

### Step 2: 基于模板生成文档

使用模板复制方式生成文档，确保格式与模板完全一致。

**Python 版本要求**：unpack.py 和 pack.py 必须使用 managed Python 3.13（系统 Python 3.9 不兼容 `str | None` 类型注解语法）。

```bash
PY3=/Users/orion/.workbuddy/binaries/python/versions/3.13.12/bin/python3
DOCX_SKILL=~/.workbuddy/plugins/marketplaces/cb_teams_marketplace/plugins/document-skills/skills/docx/scripts/office
TEMPLATE="/Users/orion/Documents/WorkBuddy工作空间/会议通知/会议通知单_电商产品讨论会.docx"
OUTPUT_DIR="/Users/orion/Documents/WorkBuddy工作空间/会议通知"

# 复制模板作为基础
cp "$TEMPLATE" "/tmp/meeting-output.docx"

# 解包
$PY3 $DOCX_SKILL/unpack.py "/tmp/meeting-output.docx" /tmp/meeting-output/

# 编辑 /tmp/meeting-output/word/document.xml 替换内容
# 具体替换规则见下方 XML 替换指南

# 打包
$PY3 $DOCX_SKILL/pack.py /tmp/meeting-output/ "$OUTPUT_DIR/会议通知单_【主题】.docx"
```

### Step 3: XML 替换指南

在 `/tmp/meeting-output/word/document.xml` 中替换以下文本：

| 原始模板文本 | 替换为 | XML 位置 |
|-------------|--------|---------|
| `2026年5月16日（周六）下午 13:00` | 用户提供的【时间】 | 第一个 `<w:tc>` 内容区的 `<w:t>` |
| `1号会议室` | 用户提供的【地点】 | 第二个 `<w:tc>` 内容区的 `<w:t>` |
| `电商产品讨论会` (标题下面表格中) | 用户提供的【主题】 | 第三个 `<w:tc>` 内容区的 `<w:t>` |
| `议题1：电商产品现状分析 议题2：产品优化方案讨论 议题3：技术实现方案评审` | 用户提供的【会议议程】 | 第四个 `<w:tc>` 内容区的 `<w:t>` |
| `产品部门、技术部门` | 用户提供的【参会人员】 | 第五个 `<w:tc>` 内容区的 `<w:t>` |
| `娜姐，电话：2222222` | 用户提供的【联系人】 | 第六个 `<w:tc>` 内容区的 `<w:t>` |

**重要**：使用 Edit 工具直接替换 `<w:t>` 标签内的文本，不要修改任何格式属性。

### Step 4: 输出

文件保存至：`/Users/orion/Documents/WorkBuddy工作空间/会议通知/会议通知单_【主题】.docx`

保存后使用 `open_result_view` 展示结果文件。

## 注意事项

1. 始终基于模板文件复制生成，不使用 docx-js 从零创建，确保格式完全一致
2. 会议议程如有多个议题，用空格分隔保留在一行中（与模板格式一致）
3. 时间格式建议：「YYYY年M月D日（周X）[上午/下午] HH:MM」
4. 联系人格式建议：「姓名，电话：XXXXXXX」
5. 如果议程内容较多导致单元格高度不够，适当增加会议议程行的 trHeight 值（在 `<w:trPr>` 中）
