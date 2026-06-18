package mcp

// MCPRequest MCP 请求结构
type MCPRequest struct {
	JSONRPC string                 `json:"jsonrpc"` // 必须是 "2.0"
	ID      interface{}            `json:"id"`      // 请求 ID
	Method  string                 `json:"method"`
	Params  map[string]interface{} `json:"params,omitempty"`
}

// MCPResponse MCP 响应结构
type MCPResponse struct {
	JSONRPC string      `json:"jsonrpc"` // 必须是 "2.0"
	ID      interface{} `json:"id"`      // 对应请求的 ID
	Result  interface{} `json:"result,omitempty"`
	Error   *MCPError   `json:"error,omitempty"`
}

// MCPError MCP 错误结构
type MCPError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// Tool MCP 工具定义
type Tool struct {
	Name        string      `json:"name"`
	Description string      `json:"description"`
	InputSchema InputSchema `json:"inputSchema"`
}

// InputSchema 工具输入模式
type InputSchema struct {
	Type       string              `json:"type"`
	Properties map[string]Property `json:"properties,omitempty"`
	Required   []string            `json:"required,omitempty"`
}

// Property 属性定义
type Property struct {
	Type        string   `json:"type"`
	Description string   `json:"description,omitempty"`
	Enum        []string `json:"enum,omitempty"`
	Items       *Items   `json:"items,omitempty"`
}

// Items 数组项定义
type Items struct {
	Type string `json:"type"`
}

// ToolResult 工具调用结果
type ToolResult struct {
	Content []Content `json:"content"`
	IsError bool      `json:"isError,omitempty"`
}

// Content 内容定义
type Content struct {
	Type string `json:"type"`
	Text string `json:"text"`
}
