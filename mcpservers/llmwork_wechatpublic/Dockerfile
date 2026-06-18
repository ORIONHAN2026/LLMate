# 多阶段构建 Dockerfile for llmwork_wechatpublic MCP Server
# 阶段 1：构建
FROM golang:1.21-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制 go.mod（利用 Docker 缓存）
COPY go.mod ./

# 下载依赖
RUN go mod download || true

# 复制源代码
COPY . .

# 编译为静态二进制文件（禁用 CGO，静态链接）
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o llmwork-wechatpublic ./cmd/server/

# 阶段 2：运行
FROM alpine:latest

# 安装 CA 证书（用于 HTTPS 请求）
RUN apk --no-cache add ca-certificates tzdata

# 设置时区为上海
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /app/

# 从构建阶段复制二进制文件
COPY --from=builder /app/llmwork-wechatpublic ./

# 暴露端口（云托管默认使用 80 端口）
EXPOSE 80

# 设置环境变量
ENV PORT=80
ENV HOST=0.0.0.0

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

# 启动服务
CMD ["./llmwork-wechatpublic"]
