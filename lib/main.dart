import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:llmate/l10n/app_localizations.dart';
import './controllers/model_controller.dart';
import './controllers/session_controller.dart';
import './controllers/message_controller.dart';
import './controllers/settings_controller.dart';
import './controllers/mcp_controller.dart';
import './controllers/audit_controller.dart';
import './features/chat/pages/home.dart';
import 'features/loading_page.dart';
import './core/http/local_http_service.dart';
import 'theme/app_theme.dart';

import 'core/services/storage_paths.dart';

// 最小窗口宽度组成: 左侧边栏最小 150 + 中间聊天区最小 520 + 右侧面板最小 260 + 额外缓冲 40
const double kMinLeftSidebarWidth = 150;
const double kMinChatAreaWidth = 520;
const double kMinRightSidebarWidth = 260;
const double kWindowExtraPadding = 40;
const double kMinWindowWidth =
    kMinLeftSidebarWidth +
    kMinChatAreaWidth +
    kMinRightSidebarWidth +
    kWindowExtraPadding; // = 1040
const double kMinWindowHeight = 640; // 依据布局中顶部栏/输入区等高度需要，留出足够空间

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 抑制 macOS 上 Caps Lock 等键导致的 Flutter 框架键盘断言错误（已知 bug）
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('_pressedKeys.containsKey') ||
        msg.contains('HardwareKeyboard') ||
        msg.contains('KeyUpEvent is dispatched')) {
      return; // 静默忽略
    }
    FlutterError.presentError(details);
  };

  // 桌面平台设定最小窗口尺寸，防止布局被压缩溢出
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      minimumSize: Size(kMinWindowWidth, kMinWindowHeight),
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 保险：部分平台在 waitUntilReadyToShow 里再显式设置一次最小尺寸
      await windowManager.setMinimumSize(
        const Size(kMinWindowWidth, kMinWindowHeight),
      );
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 初始化文件存储（必须在 SettingsController 之前）
  await StoragePaths.ensureRoot();

  // 初始化 SettingsController（统一设置：主题 / 域名 / 语言）
  final settingsController = Get.put(SettingsController());

  // 确保域名配置加载完成
  await Future.delayed(const Duration(milliseconds: 100));

  // 初始化 LocalHttpServiceController（本地服务控制）
  Get.put(LocalHttpServiceController());

  // 初始化审计控制器（DuckDB 审计存储，失败不致命）
  try {
    await AuditController.instance.ensureInitialized();
  } catch (e) {
    debugPrint('⚠️ [Audit] 初始化失败（审计功能暂不可用）: $e');
  }

  // 启动 HTTP 服务（使用配置的 HTTP 端口，默认 80）
  final port = settingsController.httpPort.value;
  LocalHttpService.start(port: port, allowExternal: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (themeController) {
        final settings = Get.find<SettingsController>();
        return Obx(
          () => GetMaterialApp(
            title: 'LLMate',
            debugShowCheckedModeBanner: false,
            locale: settings.locale.value,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh'),
              Locale('en'),
              Locale('ja'),
              Locale('th'),
              Locale('vi'),
              Locale('ko'),
              Locale('fr'),
              Locale('de'),
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            home: const AppInitializer(),
          ),
        );
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 初始化全局GetX控制器
      Get.put(ModelController());
      Get.put(MessageController());
      final sessionController = Get.put(SessionController());
      final mcpController = Get.put(McpController());

      // 初始化 MCP 配置数据
      await mcpController.loadAll();

      // 加载会话数据（首次启动会由 SessionController 自动 seed 默认会话）
      await sessionController.loadAll();

      // 确保加载页面至少显示500ms，避免闪烁
      await Future.delayed(const Duration(milliseconds: 500));

      // 跳转到主页面
      if (mounted) {
        Get.offAll(() => const CodeChatHomePage());
      }
    } catch (e) {
      // 如果初始化失败，仍然跳转到主页面
      if (mounted) {
        Get.offAll(() => const CodeChatHomePage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingPage();
  }
}
