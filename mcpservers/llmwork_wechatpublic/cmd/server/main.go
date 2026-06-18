package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"

	"llmwork_wechatpublic/pkg/config"
	"llmwork_wechatpublic/pkg/mcp"
	_ "llmwork_wechatpublic/pkg/tools"
)

func main() {
	config.Init()

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}
	host := os.Getenv("HOST")
	if host == "" {
		host = "0.0.0.0"
	}

	http.HandleFunc("/mcp", handleMCP)
	http.HandleFunc("/health", handleHealth)

	addr := host + ":" + port
	log.Printf("[llmwork_wechatpublic] 微信公众号 MCP 服务已启动")
	log.Printf("[llmwork_wechatpublic] 监听地址: http://%s", addr)
	log.Printf("[llmwork_wechatpublic] MCP 端点:     http://%s/mcp", addr)
	log.Printf("[llmwork_wechatpublic] 健康检查:     http://%s/health", addr)
	log.Println("")
	log.Println("[llmwork_wechatpublic] 配置信息:")
	log.Printf("  - 云函数名:   %s", config.CloudFunctionName)
	log.Printf("  - API 地址:   %s", config.APIBase)
	log.Printf("  - TCB Token:  %s", maskStr(config.TCBToken))
	log.Println("")
	log.Println("[llmwork_wechatpublic] 可用工具:")
	log.Println("  - get_access_token:      获取/刷新 access_token")
	log.Println("  - send_template_message: 发送模板消息")
	log.Println("")
	log.Println("[llmwork_wechatpublic] 客户端配置示例:")
	log.Printf("{")
	log.Printf("  \"mcpServers\": {")
	log.Printf("    \"llmwork_wechatpublic\": {")
	log.Printf("      \"url\": \"http://%s/mcp\",", addr)
	log.Printf("      \"headers\": {")
	log.Printf("        \"X-Wechat-Appid\": \"wx1234567890\",")
	log.Printf("        \"X-Wechat-Secret\": \"your_secret\"")
	log.Printf("      }")
	log.Printf("    }")
	log.Printf("  }")
	log.Printf("}")

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("[llmwork_wechatpublic] 启动失败: %v", err)
	}
}

func handleMCP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Wechat-Appid, X-Wechat-Secret")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 从请求头提取微信公众号凭证
	appID := r.Header.Get("X-Wechat-Appid")
	secret := r.Header.Get("X-Wechat-Secret")
	if appID != "" && secret != "" {
		config.SetWechatCredentials(appID, secret)
	}

	var request mcp.MCPRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(mcp.MCPResponse{
			JSONRPC: "2.0",
			ID:      nil,
			Error:   &mcp.MCPError{Code: -32700, Message: "Parse error"},
		})
		return
	}

	if request.ID == nil {
		w.WriteHeader(http.StatusAccepted)
		return
	}

	var response mcp.MCPResponse
	switch request.Method {
	case "initialize":
		response = mcp.HandleInitialize(request)
	case "tools/list":
		response = mcp.ListTools()
	case "tools/call":
		result, err := mcp.CallTool(request.Params)
		if err != nil {
			response = mcp.ErrorResponse(err.Error())
		} else {
			response = result
		}
	default:
		response = mcp.ErrorResponse("Unknown method: " + request.Method)
	}

	response.JSONRPC = "2.0"
	response.ID = request.ID

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func handleHealth(w http.ResponseWriter, _ *http.Request) {
	response := map[string]interface{}{
		"status":           "ok",
		"service":          "llmwork_wechatpublic",
		"version":          "1.0.0",
		"tcbReady":         config.TCBToken != "" && config.APIBase != "",
		"functionName":     config.CloudFunctionName,
		"wechatConfigured": config.GetWechatAppID() != "" && config.GetWechatAppSecret() != "",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func maskStr(s string) string {
	if s == "" {
		return "(未设置)"
	}
	if len(s) <= 16 {
		return "***"
	}
	return s[:8] + "..." + s[len(s)-8:]
}
