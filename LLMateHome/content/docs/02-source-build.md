---
title: 源码编译安装
type: docs
prev: docs/01-download
next: docs/03-model-config
weight: 2
---

企业用户可根据自身需求，下载源码进行定制化修改和二次开发。

### 环境要求

- Flutter SDK >= 3.7.2
- Dart SDK >= 3.7.2
- Git

### 安装步骤

```bash
# 克隆仓库
git clone https://cnb.cool/llmhub.cc/llmchat.git

# 进入项目目录
cd llmchat

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 打包发布

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

源码采用 GPL v3.0 开源协议，企业可自由修改和分发，但需遵守协议条款。
