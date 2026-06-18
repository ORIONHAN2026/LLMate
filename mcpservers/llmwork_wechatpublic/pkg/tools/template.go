package tools

import (
	"encoding/json"
	"fmt"
	"strings"

	"llmwork_wechatpublic/pkg/cloudbase"
	"llmwork_wechatpublic/pkg/config"
	"llmwork_wechatpublic/pkg/mcp"
)

func init() {
	mcp.RegisterToolForMCP(
		mcp.Tool{
			Name:        "send_template_message",
			Description: "向指定微信用户发送模板消息。appid 和 secret 通过 MCP 客户端配置的 header 传入。需要提供接收者 openid、模板 ID 和模板数据。支持可选的跳转 URL 和小程序跳转。",
			InputSchema: mcp.InputSchema{
				Type: "object",
				Properties: map[string]mcp.Property{
					"touser": {
						Type:        "string",
						Description: "接收者的 openid（必填）",
					},
					"template_id": {
						Type:        "string",
						Description: "模板消息 ID（必填）",
					},
					"data": {
						Type:        "object",
						Description: "模板数据，JSON 对象格式。key 为模板中的变量名（如 first, keyword1, remark），value 为包含 value 和可选 color 字段的对象。\n示例: {\"first\": {\"value\": \"你好\", \"color\": \"#173177\"}, \"keyword1\": {\"value\": \"测试\"}}",
					},
					"url": {
						Type:        "string",
						Description: "点击模板消息后跳转的 URL（可选）",
					},
					"miniprogram_appid": {
						Type:        "string",
						Description: "跳转小程序的 appid（可选，需与 miniprogram_pagepath 同时提供）",
					},
					"miniprogram_pagepath": {
						Type:        "string",
						Description: "跳转小程序的页面路径（可选，需与 miniprogram_appid 同时提供）",
					},
				},
				Required: []string{"touser", "template_id", "data"},
			},
		},
		handleSendTemplateMessage,
	)
}

func handleSendTemplateMessage(args map[string]interface{}) (mcp.ToolResult, error) {
	appid := config.GetWechatAppID()
	secret := config.GetWechatAppSecret()
	if appid == "" || secret == "" {
		return mcp.FormatErrorResult(fmt.Errorf("未配置微信公众号凭证，请在 MCP 客户端配置中设置 X-Wechat-Appid 和 X-Wechat-Secret header")), nil
	}

	touser := getStringArg(args, "touser", "")
	templateID := getStringArg(args, "template_id", "")

	if touser == "" {
		return mcp.FormatErrorResult(fmt.Errorf("缺少参数: touser")), nil
	}
	if templateID == "" {
		return mcp.FormatErrorResult(fmt.Errorf("缺少参数: template_id")), nil
	}

	rawData, ok := args["data"]
	if !ok {
		return mcp.FormatErrorResult(fmt.Errorf("缺少参数: data")), nil
	}
	dataMap, ok := rawData.(map[string]interface{})
	if !ok {
		return mcp.FormatErrorResult(fmt.Errorf("data 参数格式错误，应为 JSON 对象")), nil
	}

	templateData := make(map[string]interface{})
	for key, val := range dataMap {
		templateData[key] = val
	}
	if len(templateData) == 0 {
		return mcp.FormatErrorResult(fmt.Errorf("模板数据不能为空")), nil
	}

	cfParams := map[string]interface{}{
		"action":      "sendTemplateMessage",
		"appid":       appid,
		"secret":      secret,
		"touser":      touser,
		"template_id": templateID,
		"data":        templateData,
	}

	if url := getStringArg(args, "url", ""); url != "" {
		cfParams["url"] = url
	}

	miniAppID := getStringArg(args, "miniprogram_appid", "")
	miniPath := getStringArg(args, "miniprogram_pagepath", "")
	if miniAppID != "" && miniPath != "" {
		cfParams["miniprogram"] = map[string]string{
			"appid":    miniAppID,
			"pagepath": miniPath,
		}
	}

	result, err := cloudbase.CallCloudFunction(config.CloudFunctionName, cfParams)
	if err != nil {
		return mcp.FormatErrorResult(err), nil
	}

	msg := getStringFromMap(result, "msg", "")

	var sb strings.Builder
	sb.WriteString("✅ **模板消息发送成功**\n\n")
	sb.WriteString(fmt.Sprintf("- **状态**: %s\n", msg))
	sb.WriteString(fmt.Sprintf("- **接收者**: `%s`\n", touser))
	sb.WriteString(fmt.Sprintf("- **模板 ID**: `%s`\n", templateID))

	if data, ok := result["data"].(map[string]interface{}); ok {
		if msgID, ok := data["msgid"].(float64); ok {
			sb.WriteString(fmt.Sprintf("- **消息 ID**: `%.0f`\n", msgID))
		}
	}

	sb.WriteString("\n**发送的数据**:\n")
	dataJSON, _ := json.MarshalIndent(templateData, "", "  ")
	sb.WriteString(fmt.Sprintf("```json\n%s\n```\n", string(dataJSON)))

	if url := getStringArg(args, "url", ""); url != "" {
		sb.WriteString(fmt.Sprintf("\n- **跳转 URL**: %s\n", url))
	}
	if miniAppID != "" && miniPath != "" {
		sb.WriteString(fmt.Sprintf("\n- **小程序跳转**: appid=%s, path=%s\n", miniAppID, miniPath))
	}

	return mcp.FormatTextResult(sb.String()), nil
}

// ---------- 工具函数 ----------

func getStringArg(args map[string]interface{}, key, defaultVal string) string {
	if v, ok := args[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return defaultVal
}

func getStringFromMap(m map[string]interface{}, key, defaultVal string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
		return fmt.Sprintf("%v", v)
	}
	return defaultVal
}
