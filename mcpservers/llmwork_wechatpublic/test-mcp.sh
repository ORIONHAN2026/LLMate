#!/bin/bash

# llmwork_wechatpublic MCP 服务测试脚本
BASE_URL="${BASE_URL:-http://localhost:3000}"

# 公众号凭证（通过 header 传入，不在工具参数中）
WECHAT_APPID="${WECHAT_APPID:-}"
WECHAT_SECRET="${WECHAT_SECRET:-}"

echo "=============================================="
echo "  llmwork_wechatpublic MCP 服务测试"
echo "  目标: $BASE_URL"
echo "=============================================="
echo ""

echo "===== 1. 测试健康检查 ====="
curl -s "$BASE_URL/health" | jq .
echo ""

echo "===== 2. 测试 MCP initialize ====="
curl -s -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize"
  }' | jq .
echo ""

echo "===== 3. 测试 tools/list ====="
curl -s -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }' | jq .
echo ""

echo "===== 4. 测试 get_access_token ====="
if [ -z "$WECHAT_APPID" ] || [ -z "$WECHAT_SECRET" ]; then
  echo "请先设置 WECHAT_APPID 和 WECHAT_SECRET 环境变量"
  echo "示例: WECHAT_APPID=wx123 WECHAT_SECRET=abc ./test-mcp.sh"
else
  curl -s -X POST "$BASE_URL/mcp" \
    -H "Content-Type: application/json" \
    -H "X-Wechat-Appid: $WECHAT_APPID" \
    -H "X-Wechat-Secret: $WECHAT_SECRET" \
    -d '{
      "jsonrpc": "2.0",
      "id": 3,
      "method": "tools/call",
      "params": {
        "name": "get_access_token",
        "arguments": {}
      }
    }' | jq .
fi
echo ""

echo "===== 5. 测试 send_template_message ====="
if [ -z "$WECHAT_APPID" ] || [ -z "$WECHAT_SECRET" ]; then
  echo "请先设置 WECHAT_APPID 和 WECHAT_SECRET 环境变量"
else
  echo "请修改下方 OPENID 和 TEMPLATE_ID 后取消注释运行"
  # curl -s -X POST "$BASE_URL/mcp" \
  #   -H "Content-Type: application/json" \
  #   -H "X-Wechat-Appid: $WECHAT_APPID" \
  #   -H "X-Wechat-Secret: $WECHAT_SECRET" \
  #   -d '{
  #     "jsonrpc": "2.0",
  #     "id": 4,
  #     "method": "tools/call",
  #     "params": {
  #       "name": "send_template_message",
  #       "arguments": {
  #         "touser": "OPENID",
  #         "template_id": "TEMPLATE_ID",
  #         "data": {
  #           "first": {"value": "测试消息", "color": "#173177"},
  #           "keyword1": {"value": "模板消息测试"},
  #           "remark": {"value": "这是一条测试消息"}
  #         }
  #       }
  #     }
  #   }' | jq .
fi
echo ""

echo "=============================================="
echo "  测试完成"
echo "=============================================="
