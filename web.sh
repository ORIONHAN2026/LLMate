#!/bin/bash

cd "$(dirname "$0")/LLMWorkHome-hexo"

# 停止占用 4000 端口的进程
PORT=4000
PID=$(lsof -ti:$PORT)
if [ -n "$PID" ]; then
    echo "Stopping process on port $PORT (PID: $PID)..."
    kill -9 $PID 2>/dev/null
    sleep 1
fi

echo "Starting Hexo blog server..."
echo "Visit: http://localhost:$PORT"
echo "Press Ctrl+C to stop"
echo ""

npx hexo server -p $PORT
