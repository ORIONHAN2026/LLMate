package tools

import (
	"fmt"
	"strings"

	"llmwork_wechatpublic/pkg/cloudbase"
	"llmwork_wechatpublic/pkg/config"
	"llmwork_wechatpublic/pkg/mcp"
)

func init() {
	mcp.RegisterToolForMCP(
		mcp.Tool{
			Name:        "get_access_token",
			Description: "获取微信公众号 access_token。appid 和 secret 通过 MCP 客户端配置的 header 传入（X-Wechat-Appid / X-Wechat-Secret）。token 会自动缓存到云数据库中，未过期时直接返回缓存。",
			InputSchema: mcp.InputSchema{
				Type:       "object",
				Properties: map[string]mcp.Property{},
				Required:   []string{},
			},
		},
		handleGetAccessToken,
	)
}

func handleGetAccessToken(args map[string]interface{}) (mcp.ToolResult, error) {
	appid := config.GetWechatAppID()
	secret := config.GetWechatAppSecret()
	if appid == "" || secret == "" {
		return mcp.FormatErrorResult(fmt.Errorf("未配置微信公众号凭证，请在 MCP 客户端配置中设置 X-Wechat-Appid 和 X-Wechat-Secret header")), nil
	}

	result, err := cloudbase.CallCloudFunction(config.CloudFunctionName, map[string]interface{}{
		"action": "getAccessToken",
		"appid":  appid,
		"secret": secret,
	})
	if err != nil {
		return mcp.FormatErrorResult(err), nil
	}

	msg := getStringFromMap(result, "msg", "")

	var sb strings.Builder
	sb.WriteString("✅ **access_token 获取成功**\n\n")
	sb.WriteString(fmt.Sprintf("- **状态**: %s\n", msg))

	if data, ok := result["data"].(map[string]interface{}); ok {
		if token, ok := data["access_token"].(string); ok {
			displayLen := min(30, len(token))
			sb.WriteString(fmt.Sprintf("- **Token**: `%s...`\n", token[:displayLen]))
		}
		if expiredTime, ok := data["expired_time"].(float64); ok {
			sb.WriteString(fmt.Sprintf("- **过期时间戳**: %.0f\n", expiredTime))
		}
	}

	return mcp.FormatTextResult(sb.String()), nil
}
