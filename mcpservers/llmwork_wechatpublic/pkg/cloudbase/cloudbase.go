package cloudbase

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"llmwork_wechatpublic/pkg/config"
)

// CloudFunctionResponse 云函数返回的统一结构
type CloudFunctionResponse struct {
	Code int             `json:"code"`
	Msg  string          `json:"msg"`
	Data json.RawMessage `json:"data"`
}

var httpClient = &http.Client{Timeout: 30 * time.Second}

// CallCloudFunction 调用 CloudBase 云函数
// functionName: 云函数名称
// data: 传递给云函数的 event 数据
func CallCloudFunction(functionName string, data map[string]interface{}) (map[string]interface{}, error) {
	url := fmt.Sprintf("%s/v1/functions/%s/invoke", config.APIBase, functionName)

	payload := map[string]interface{}{}
	if data != nil {
		for k, v := range data {
			payload[k] = v
		}
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("序列化请求失败: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, fmt.Errorf("创建请求失败: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+config.TCBToken)

	resp, err := httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("调用云函数网络请求失败: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取云函数响应失败: %w", err)
	}

	// 先尝试解析为云函数标准响应
	var cfResp CloudFunctionResponse
	if err := json.Unmarshal(respBody, &cfResp); err != nil {
		return nil, fmt.Errorf("解析云函数响应失败: %w", err)
	}

	if cfResp.Code != 0 {
		return nil, fmt.Errorf("云函数返回错误 [code=%d]: %s", cfResp.Code, cfResp.Msg)
	}

	// 构建返回结果
	result := map[string]interface{}{
		"msg": cfResp.Msg,
	}

	if cfResp.Data != nil {
		var dataMap map[string]interface{}
		if err := json.Unmarshal(cfResp.Data, &dataMap); err == nil {
			result["data"] = dataMap
		} else {
			result["data_raw"] = string(cfResp.Data)
		}
	}

	return result, nil
}
