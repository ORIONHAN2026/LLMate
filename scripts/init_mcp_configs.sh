#!/bin/bash

# 初始化内置 MCP 配置
# 创建 ~/.llmwork/mcps/{name}/server.json 和 config.json

set -e

MCPS_DIR="$HOME/.llmwork/mcps"
BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)/build/mcp_servers"

echo "📁 初始化 MCP 配置: $MCPS_DIR"

# 内置 MCP 列表
BUILTIN_MCPS=(
  "filesystem:文件系统访问服务，读取、写入和管理本地文件"
  "git:Git 仓库操作，支持状态查看、提交、分支管理"
  "shell:执行任意 shell 命令和脚本"
  "fetch:获取网页内容和 JSON API 数据"
  "sqlite:SQLite 数据库操作，支持查询、修改、导出"
  "email:邮件收发服务，支持主流邮箱"
)

for item in "${BUILTIN_MCPS[@]}"; do
  IFS=':' read -r name description <<< "$item"
  
  mkdir -p "$MCPS_DIR/$name"
  
  # 复制可执行文件（如果存在）
  if [ -f "$BUILD_DIR/$name" ]; then
    cp "$BUILD_DIR/$name" "$MCPS_DIR/$name/$name"
    chmod +x "$MCPS_DIR/$name/$name"
  fi
  
  # 创建 server.json
  cat > "$MCPS_DIR/$name/server.json" << EOF
{
  "mcpServers": {
    "$name": {
      "command": "./$name",
      "args": []
    }
  }
}
EOF

  # 创建 config.json
  cat > "$MCPS_DIR/$name/config.json" << EOF
{
  "name": "$name",
  "description": "$description",
  "tools": [],
  "lastUpdated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  echo "✅ $name"
done

echo ""
echo "📁 目录结构:"
find "$MCPS_DIR" -type f | sort
