---
name: 图片转化
description: 识别并转换图片格式，支持 JPG/JPEG 转 PNG、PNG 转 JPG 等多种格式互转。通过 python_execute 调用 Pillow 库完成转换。
agent_created: true
---

# 图片转化

## 技能说明

本技能用于图片格式转换。当用户提供一张图片并要求转换格式时（如 JPG 转 PNG、PNG 转 JPG 等），使用 `python_execute` 工具调用 Pillow 库完成转换。

## 执行流程

### 第 1 步：确认源图片路径和目标格式

从用户消息中提取：
- **源图片路径**（source_path）：用户提供的图片路径
- **目标格式**：用户要求的输出格式（如 png、jpg、webp 等）

如果用户未指定目标格式，主动询问用户需要转换为哪种格式。

输出文件命名规则：
- 在原文件名后追加 `_converted`，再使用目标格式扩展名
- 例如：`photo.jpg` → `photo_converted.png`
- 输出文件保存在源图片相同目录下

### 第 2 步：执行格式转换

使用 `python_execute` 工具，调用 Pillow 库执行转换：

```xml
<invoke name="python_execute">
<arguments>
{
  "script": "from PIL import Image\n\nsrc = '/path/to/source.jpg'\ndst = '/path/to/source_converted.png'\nimg = Image.open(src)\n# 如果是 PNG 转 JPG，需要处理透明通道\nif img.mode in ('RGBA', 'LA'):\n    background = Image.new('RGB', img.size, (255, 255, 255))\n    background.paste(img, mask=img.split()[-1] if img.mode=='RGBA' else None)\n    background.save(dst, 'PNG')\nelse:\n    img.save(dst, 'PNG')\nprint(f'转换完成：{dst}')\nprint(f'原格式：{Image.open(src).format}')\nprint(f'新格式：PNG')",
  "requirements": ["Pillow"]
}
</arguments>
</invoke>
</tool_calls>
```

参数说明：
- `script`：Python 脚本内容，使用 Pillow 的 `Image.open()` 读取、`save()` 保存
- `requirements`：`["Pillow"]`，执行前自动安装
- 根据源格式和目标格式调整 `img.save(dst, '格式')` 中的格式参数

格式映射：
- JPG/JPEG → `save(dst, 'JPEG')`
- PNG → `save(dst, 'PNG')`
- WebP → `save(dst, 'WEBP')`
- BMP → `save(dst, 'BMP')`
- GIF → `save(dst, 'GIF')`

### 第 3 步：验证转换结果

再次使用 `python_execute` 读取转换后的图片，确认格式和尺寸：

```xml
<invoke name="python_execute">
<arguments>
{
  "script": "from PIL import Image\nimport os\n\ndst = '/path/to/source_converted.png'\nimg = Image.open(dst)\nfsize = os.path.getsize(dst) / 1024\nprint(f'格式：{img.format}')\nprint(f'尺寸：{img.size[0]} × {img.size[1]}')\nprint(f'文件大小：{fsize:.1f} KB')"
}
</arguments>
</invoke>
</tool_calls>
```

### 第 4 步：向用户汇报结果

汇报内容包括：
- ✅ 转换成功/失败状态
- 📐 图片尺寸（宽 × 高）
- 🔄 源格式 → 目标格式
- 📁 输出文件保存路径
- 💾 文件大小变化（如有）

## 注意事项

1. PNG 转 JPG 时，透明通道将变为白色背景，需提前告知用户
2. 转换操作不会修改或删除源图片
3. 输出文件默认保存在与源图片相同的目录下
4. 如果系统未安装 Pillow，通过 `requirements: ["Pillow"]` 自动安装

## 示例对话

**用户**：帮我把 /Users/example/photo.jpg 转成 PNG 格式

**助手执行**：
1. `python_execute` 调用 Pillow 执行转换：src=`photo.jpg`，dst=`photo_converted.png`，格式=PNG
2. `python_execute` 验证输出文件：确认格式为 PNG，尺寸正确
3. 向用户汇报转换结果：✅ 转换成功，📁 保存路径：`/Users/example/photo_converted.png`
