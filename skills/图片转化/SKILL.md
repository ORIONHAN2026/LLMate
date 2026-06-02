---
name: 图片转化
description: 识别并转换图片格式，支持 JPG/JPEG 转 PNG、PNG 转 JPG 等多种格式互转。自动识别源图片格式并转换为目标格式。
agent_created: true
---

# 图片转化

## 技能说明

本技能用于图片格式转换。当用户提供一张图片并要求转换格式时（如 JPG 转 PNG、PNG 转 JPG 等），按以下流程操作。

## 执行流程

### 第 1 步：读取源图片信息

使用 `image_read` 工具读取用户提供的源图片，获取图片的格式、尺寸等基本信息。

```
调用 image_read：
- filePath: 用户提供的源图片路径
```

### 第 2 步：确认转换参数

根据用户需求确定以下参数：

- **源图片路径**（sourcePath）：用户提供的图片路径
- **目标格式**：用户要求的输出格式（如 png、jpg、webp 等）
- **输出路径**（filePath）：将源文件扩展名替换为目标格式扩展名，保存在同目录下
- **压缩质量**（quality）：默认 85，用户可指定 0-100 的值

格式映射规则：
- jpg / jpeg → 输出扩展名使用 `.jpg`
- png → 输出扩展名使用 `.png`
- webp → 输出扩展名使用 `.webp`
- bmp → 输出扩展名使用 `.bmp`
- gif → 输出扩展名使用 `.gif`

输出文件命名规则：
- 在原文件名后追加 `_converted`，再使用目标格式扩展名
- 例如：`photo.jpg` → `photo_converted.png`

### 第 3 步：执行格式转换

使用 `image_write` 工具进行格式转换：

```
调用 image_write：
- sourcePath: 源图片路径
- filePath: 输出图片路径（扩展名决定输出格式）
- action: "convert"
- quality: 压缩质量（默认 85）
```

### 第 4 步：验证转换结果

使用 `image_read` 读取转换后的图片，确认格式、尺寸等信息是否正确。

### 第 5 步：向用户汇报结果

汇报内容包括：
- ✅ 转换成功/失败状态
- 📐 图片尺寸（宽 × 高）
- 📄 源格式 → 目标格式
- 📁 输出文件保存路径
- 💾 文件大小变化（如有）

## 支持的转换场景

| 源格式 | 目标格式 | 说明 |
|--------|----------|------|
| JPG/JPEG | PNG | 常见需求，转为无损格式 |
| PNG | JPG/JPEG | 减小文件体积 |
| JPG/JPEG | WebP | 现代网页格式 |
| PNG | WebP | 现代网页格式 |
| BMP | PNG/JPG | 压缩位图 |
| WebP | PNG/JPG | 转为通用格式 |

## 注意事项

1. 如果用户未指定目标格式，主动询问用户需要转换为哪种格式
2. 如果源图片包含透明通道（如 PNG），转换为 JPG 时透明区域将变为白色背景，需提前告知用户
3. 转换操作不会修改或删除源图片
4. 输出文件默认保存在与源图片相同的目录下

## 示例对话

**用户**：帮我把 /Users/example/photo.jpg 转成 PNG 格式

**助手执行**：
1. `image_read` 读取 photo.jpg，确认格式为 JPEG
2. `image_write` 执行转换：action=convert，输出为 photo_converted.png
3. `image_read` 验证输出文件
4. 向用户汇报转换结果
