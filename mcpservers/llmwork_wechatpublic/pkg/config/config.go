package config

import (
	"os"
	"sync"
)

var (
	// TCBToken CloudBase HTTP API 认证 Token
	TCBToken string

	// APIBase CloudBase HTTP API 基础地址
	APIBase string

	// CloudFunctionName 云函数名称
	CloudFunctionName string

	// wechatAppID 微信公众号 AppID（通过 MCP 客户端 header 传入）
	wechatAppID string
	// wechatAppSecret 微信公众号 AppSecret（通过 MCP 客户端 header 传入）
	wechatAppSecret string
	mu             sync.RWMutex
)

// Init 初始化配置，从环境变量读取
func Init() {
	TCBToken = os.Getenv("TCB_TOKEN")
	APIBase = os.Getenv("API_BASE")
	CloudFunctionName = os.Getenv("CLOUD_FUNCTION_NAME")

	if CloudFunctionName == "" {
		CloudFunctionName = "llmwork_wechatpublic"
	}
	if APIBase == "" {
		APIBase = "https://cloud1-1gqqkl7s9ff46343.api.tcloudbasegateway.com"
	}
}

// GetWechatAppID 获取微信公众号 AppID
func GetWechatAppID() string {
	mu.RLock()
	defer mu.RUnlock()
	return wechatAppID
}

// GetWechatAppSecret 获取微信公众号 AppSecret
func GetWechatAppSecret() string {
	mu.RLock()
	defer mu.RUnlock()
	return wechatAppSecret
}

// SetWechatCredentials 设置微信公众号凭证
func SetWechatCredentials(appID, appSecret string) {
	mu.Lock()
	defer mu.Unlock()
	wechatAppID = appID
	wechatAppSecret = appSecret
}
