#!/bin/bash

# 编译 MCP 服务器为原生可执行文件
# 用法: ./build_mcp_servers.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVERS_DIR="$PROJECT_ROOT/lib/mcp_builtins/servers"
BUILD_DIR="$PROJECT_ROOT/build/mcp_servers"

echo "🔨 开始编译 MCP 服务器..."
echo "📁 项目根目录: $PROJECT_ROOT"
echo ""

# 清理旧的构建
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 创建临时编译目录
TEMP_BUILD=$(mktemp -d)
cp "$SERVERS_DIR"/*.dart "$TEMP_BUILD/"

cd "$TEMP_BUILD"

# 编译每个服务器
SERVERS=(
  "filesystem_server.dart:filesystem"
  "git_server.dart:git"
  "shell_server.dart:shell"
  "fetch_server.dart:fetch"
  "sqlite_server.dart:sqlite"
  "email_server.dart:email"
  "writepage_server.dart:writepage"
)

for item in "${SERVERS[@]}"; do
  IFS=':' read -r source_file output_name <<< "$item"

  if [ ! -f "$source_file" ]; then
    echo "⚠️  跳过: $source_file 不存在"
    continue
  fi

  echo "📦 编译: $source_file → $output_name"

  # 编译
  dart compile exe "$source_file" -o "$BUILD_DIR/$output_name" 2>&1 || {
    echo "⚠️  编译失败: $source_file"
    continue
  }

  echo "✅ 完成: $output_name"
done

cd "$PROJECT_ROOT"
rm -rf "$TEMP_BUILD"

# 设置可执行权限
chmod +x "$BUILD_DIR"/*

echo ""
echo "🎉 编译完成！"
ls -la "$BUILD_DIR"
