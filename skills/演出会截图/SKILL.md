---
name: 演出会截图
description: 从Excel文件读取演出场次数据，自动识别表头行和目标列（序号/日期/区域/排数/号数/售价），将每个Sheet渲染为带样式的PNG图片
agent_created: true
---

# 演出会截图

## 功能概述

从工作目录中的 Excel 文件读取演出场次表，自动定位表头行、匹配目标列，将每个 Sheet 的数据渲染为 PNG 图片文件。

## 执行流程

### 1. 安装依赖

使用 `python_execute` 安装必要库：
```
requirements: ["Pillow", "openpyxl"]
```

### 2. 读取 Excel 并智能定位表头

- 使用 `openpyxl.load_workbook(path, data_only=True)` 读取
- **关键**：表头不一定在第1行，需扫描前30行找到包含最多目标关键词的行作为表头
- 目标列及别名映射：
  - 序号 → ["序号"]
  - 日期 → ["日期"]
  - 区域 → ["区域"]
  - 排数 → ["排数"]
  - 号数 → ["号数", "座位号", "座号"]
  - 售价 → ["售价"]
- 至少匹配3个目标列才处理该Sheet

### 3. 渲染 PNG 图片

使用 Pillow 绘制表格图片，样式规范：
- **表头**：蓝色背景(41,98,255)，白色文字，字号18
- **数据行**：斑马纹交替（白色/浅蓝），字号16
- **边框**：浅灰色(200,200,200)
- **内边距**：水平16px，垂直10px
- **字体**：优先加载系统中文字体（PingFang.ttc / STHeiti / Hiragino Sans GB）
- **注意**：Pillow 的 `getlength()` 可能返回浮点数，所有尺寸计算需用 `int(math.ceil(...))` 取整

### 4. 输出规范

- 输出目录：与工作目录相同
- 命名规则：`演出场次_{Sheet名称}.png`（特殊字符替换为下划线）
- 跳过空Sheet、列匹配不足3个的Sheet、无数据行的Sheet

## 核心代码模板

```python
import os, re, math
from openpyxl import load_workbook
from PIL import Image, ImageDraw, ImageFont

def text_width(font, text):
    """兼容新旧版Pillow"""
    try:
        bbox = font.getbbox(text)
        return int(math.ceil(bbox[2] - bbox[0]))
    except:
        return int(math.ceil(font.getlength(text)))

def find_header_row(all_rows, max_scan=30):
    """扫描前max_scan行，找包含最多目标关键词的行"""
    best_idx, best_score = -1, 0
    for r_idx, row in enumerate(all_rows[:max_scan]):
        cells = [str(c).strip() for c in row if c is not None]
        score = sum(1 for aliases in TARGET_COLS.values()
                    if any(a in cell for a in aliases for cell in cells))
        if score > best_score:
            best_score, best_idx = score, r_idx
    return best_idx, best_score
```

## 注意事项

- Excel 中可能有合并单元格、空行、标题行等干扰，必须智能定位表头
- 不同Sheet的表头位置可能不同（如第3行、第4行等）
- 列名可能有变体（如"座位号"="号数"），需做别名映射
- 生成大量数据行的PNG时图片会很长，属正常现象
