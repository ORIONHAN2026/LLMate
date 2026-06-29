# utils/ - 通用工具函数

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `snackbar_utils.dart` | 238 | 自定义 SnackBar 通知：顶部弹出式 Toast，支持成功/错误/信息/加载状态 |
| `responsive_utils.dart` | 168 | 响应式布局工具：设备类型检测（移动端/平板/桌面）、断点常量、自适应间距/字体/布局 |

## SnackBar 使用

```dart
SnackBarUtils.success('操作成功');
SnackBarUtils.error('操作失败');
SnackBarUtils.info('提示信息');
SnackBarUtils.showLoading('加载中...');
```

## 响应式断点

| 设备类型 | 宽度范围 |
|----------|----------|
| 移动端 | < 600px |
| 平板 | 600px - 1024px |
| 桌面 | > 1024px |
