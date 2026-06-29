# l10n/ - 国际化资源

## 职责

管理应用的多语言翻译，支持中文、英文、越南语、泰语。

## 文件结构

```
l10n/
├── app_en.arb               # 英文 ARB 源文件（489 条）
├── app_zh.arb               # 中文 ARB 源文件（488 条）
├── app_vi.arb               # 越南语 ARB 源文件
├── app_th.arb               # 泰语 ARB 源文件
├── app_localizations.dart    # 自动生成的本地化基类（3040 行）
├── app_localizations_en.dart # 英文实现（1606 行）
├── app_localizations_zh.dart # 中文实现（1573 行）
├── app_localizations_vi.dart # 越南语实现
└── app_localizations_th.dart # 泰语实现
```

## 使用方式

```dart
// 在 Widget 中
AppLocalizations.of(context)!.hello

// 在非 Widget 中
AppLocalizations.instance.hello
```

## 添加新语言

1. 创建 `app_xx.arb` 源文件
2. 运行 `flutter gen-l10n` 生成 Dart 代码
3. 在 `main.dart` 的 `supportedLocales` 中添加语言
