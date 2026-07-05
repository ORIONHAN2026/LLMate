# core/tools/document_tools/ - 文档处理工具

## 职责

提供多格式文档的读取、创建和处理能力，供 LLM 工具调用使用。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `file_tool_service.dart` | 206 | 通用文本文件读写工具，支持代码、Markdown、配置文件 |
| `word_tool_service.dart` | 916 | Word (.docx) 创建工具：标题、段落、表格、列表、加粗/斜体、对齐 |
| `pdf_tool_service.dart` | 312 | PDF 读写工具：提取文本/元数据，创建带水印的 PDF |
| `excel_tool_service.dart` | 271 | Excel (.xlsx) 读写工具：多 Sheet、表头、样式支持 |
| `ppt_tool_service.dart` | 390 | PowerPoint (.pptx) 创建工具：多页幻灯片、标题、内容、项目符号 |
| `image_tool_service.dart` | 297 | 图片处理工具：元数据读取、缩放/裁剪/旋转/压缩/水印 |
| `ocr_tool_service.dart` | 213 | RapidOCR 文字识别：基于 ONNX 的图片转文字 |
| `paddle_ocr_service.dart` | 250 | PaddleOCR 文字识别：高精度中英文混合 OCR |
