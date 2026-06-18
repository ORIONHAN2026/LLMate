package mcp

import (
	"encoding/json"
	"fmt"
	"log"
	"time"
)

// ToolHandler 工具处理函数类型
type ToolHandler func(args map[string]interface{}) (ToolResult, error)

// toolRegistry 工具注册表（由 tools 包初始化）
var toolRegistry struct {
	tools    []Tool
	handlers map[string]ToolHandler
}

// RegisterToolForMCP 供 tools 包注册工具（避免循环依赖）
func RegisterToolForMCP(tool Tool, handler ToolHandler) {
	toolRegistry.tools = append(toolRegistry.tools, tool)
	if toolRegistry.handlers == nil {
		toolRegistry.handlers = make(map[string]ToolHandler)
	}
	toolRegistry.handlers[tool.Name] = handler
}

// ListTools 列出所有可用工具
func ListTools() MCPResponse {
	return MCPResponse{
		Result: map[string]interface{}{
			"tools": toolRegistry.tools,
		},
	}
}

// CallTool 调用工具
func CallTool(params map[string]interface{}) (MCPResponse, error) {
	// 获取工具名称
	name, ok := params["name"].(string)
	if !ok {
		log.Printf("[MCP] [ERROR] 缺少工具名称")
		return MCPResponse{}, fmt.Errorf("缺少工具名称")
	}

	// 获取工具参数
	args := make(map[string]interface{})
	if a, ok := params["arguments"].(map[string]interface{}); ok {
		args = a
	}

	// 查找工具处理函数
	handler, exists := toolRegistry.handlers[name]
	if !exists {
		log.Printf("[MCP] [ERROR] 未知工具: %s", name)
		return MCPResponse{
			Result: ToolResult{
				Content: []Content{
					{Type: "text", Text: fmt.Sprintf("❌ 未知工具: %s", name)},
				},
				IsError: true,
			},
		}, nil
	}

	// 记录工具调用开始
	startTime := time.Now()
	argsJSON, _ := json.Marshal(args)
	log.Printf("[MCP] [TOOL] 调用工具: %s, 参数: %s", name, string(argsJSON))

	// 声明结果变量（用于在 defer 中修改）
	var result ToolResult
	var err error

	// 调用工具处理函数（添加 panic 恢复）
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[MCP] [TOOL] 工具执行 panic: %s, 错误: %v", name, r)
			result = FormatErrorResult(fmt.Errorf("工具执行失败: %v", r))
			err = nil
		}
	}()

	result, err = handler(args)

	// 记录工具调用结束
	duration := time.Since(startTime)
	if err != nil {
		log.Printf("[MCP] [TOOL] 工具执行失败: %s, 耗时: %v, 错误: %v", name, duration, err)
		// 将 Go 错误转换为 MCP 错误响应（放在 result 中，而不是 error 字段）
		result = FormatErrorResult(err)
	}

	// 检查结果是否有错误
	if result.IsError {
		log.Printf("[MCP] [TOOL] 工具返回错误: %s, 耗时: %v", name, duration)
	} else {
		log.Printf("[MCP] [TOOL] 工具执行成功: %s, 耗时: %v", name, duration)
	}

	return MCPResponse{
		Result: result,
	}, nil
}

// HandleInitialize 处理 initialize 方法
func HandleInitialize(request MCPRequest) MCPResponse {
	return MCPResponse{
		JSONRPC: "2.0",
		ID:      request.ID,
		Result: map[string]interface{}{
			"protocolVersion": "2024-11-05",
			"capabilities": map[string]interface{}{
				"tools": map[string]interface{}{},
			},
		"serverInfo": map[string]interface{}{
			"name":    "llmwork_wechatpublic",
			"version": "1.0.0",
		},
		},
	}
}

// ErrorResponse 创建错误响应
func ErrorResponse(message string) MCPResponse {
	return MCPResponse{
		Error: &MCPError{
			Code:    -1,
			Message: message,
		},
	}
}

// FormatTextResult 格式化文本结果
func FormatTextResult(text string) ToolResult {
	return ToolResult{
		Content: []Content{
			{Type: "text", Text: text},
		},
	}
}

// FormatErrorResult 格式化错误结果
func FormatErrorResult(err error) ToolResult {
	return ToolResult{
		Content: []Content{
			{Type: "text", Text: fmt.Sprintf("❌ 错误: %s", err.Error())},
		},
		IsError: true,
	}
}

// SuccessResponse 创建成功响应
func SuccessResponse(text string) MCPResponse {
	return MCPResponse{
		Result: ToolResult{
			Content: []Content{
				{Type: "text", Text: text},
			},
		},
	}
}
