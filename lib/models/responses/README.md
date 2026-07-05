# models/responses/ - API 响应 DTO

## 职责

定义各 LLM 厂商的 SSE 流式响应数据结构，用于解析 Chat Completion Chunk 格式。

## 文件说明

| 文件 | 行数 | 对应厂商 |
|------|------|----------|
| `openai_response.dart` | 170 | OpenAI (兼容格式) |

## 结构说明

所有响应 DTO 结构相似（均兼容 OpenAI 格式），包含：

```dart
class XxxResponse {
  String id;
  List<XxxChoice> choices;
}

class XxxChoice {
  int index;
  XxxDelta delta;
  String finishReason;
}

class XxxDelta {
  String role;
  String content;
  List<XxxToolCall> toolCalls;
}
```

## 注意

这些 DTO 结构高度相似，未来可考虑合并为统一的响应解析器。
