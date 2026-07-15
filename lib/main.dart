import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:llmate/l10n/app_localizations.dart';
import './features/models/controllers/model_controller.dart';
import './controllers/session_controller.dart';
import './controllers/theme_controller.dart';
import './controllers/locale_controller.dart';
import './controllers/domain_controller.dart';
import './controllers/mcp_controller.dart';
import './features/chat/pages/home.dart';
import './pages/loading_page.dart';
import './core/scheduler/scheduled_task_service.dart';
import './core/http/local_http_service.dart';

import './models/bigmodel/chat_model.dart';
import 'models/chat/chat_session.dart';
import './data/storage_service.dart';

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

  // 初始化文件存储（必须在 ThemeController 之前）
  await StorageService.instance.initialize();

  // 在应用启动前初始化 ThemeController
  Get.put(ThemeController());

  // 初始化 LocaleController（语言设置）
  Get.put(LocaleController());

  // 初始化 DomainController（域名管理）
  final domainController = Get.put(DomainController());

  // 确保域名配置加载完成
  await Future.delayed(const Duration(milliseconds: 100));

  // 初始化 LocalHttpServiceController（本地服务控制）
  Get.put(LocalHttpServiceController());

  // 启动 HTTP 服务（使用配置的 HTTP 端口，默认 80）
  final port = domainController.domainConfig.value.httpPort;
  LocalHttpService.start(port: port, allowExternal: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final localeController = Get.find<LocaleController>();
        return Obx(
          () => GetMaterialApp(
            title: 'LLMate',
            debugShowCheckedModeBanner: false,
            locale: localeController.locale.value,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh'),
              Locale('en'),
            ],
              theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                primary: const Color(0xFF2563EB),
                seedColor: const Color(0xFF2563EB), // 蓝色主色调
                brightness: Brightness.light,
              ).copyWith(
                surface: Colors.white,
                onSurface: const Color(0xFF1F2937),
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              canvasColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white, // 标题栏背景色
                surfaceTintColor: Colors.transparent, // 移除Material 3的色调效果
                foregroundColor: Color(0xFF1F2937), // 标题文字颜色
                titleTextStyle: TextStyle(
                  color: Color(0xFF1F2937), // 标题文字颜色
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(
                  color: Color(0xFF1F2937), // 图标颜色
                ),
                actionsIconTheme: IconThemeData(
                  color: Color(0xFF1F2937), // 操作按钮图标颜色
                ),
                elevation: 0, // 去掉阴影
                scrolledUnderElevation: 0, // 滚动时也不显示阴影
                centerTitle: false, // 标题左对齐
              ),
              cardColor: Colors.white,
              dividerColor: const Color(0xFFE5E7EB),
              primaryColor: const Color(0xFF2563EB),
              textTheme: const TextTheme(
                headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                bodyLarge: TextStyle(fontSize: 15, height: 1.6),
                bodyMedium: TextStyle(fontSize: 13, height: 1.5),
                bodySmall: TextStyle(fontSize: 11, height: 1.4),
                labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                labelMedium: TextStyle(fontSize: 12),
                labelSmall: TextStyle(fontSize: 10),
              ),

              // 按钮主题配置
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937), // 主按钮黑色
                  foregroundColor: Colors.white, // 文字颜色
                  elevation: 2,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // 填充按钮蓝色
                  foregroundColor: Colors.white, // 文字颜色
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB), // 边框按钮蓝色
                  side: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB), // 文本按钮蓝色
                ),
              ),

              // 抽屉主题 - 移动端适配
              drawerTheme: const DrawerThemeData(
                elevation: 16,
                backgroundColor: Colors.white,
              ),
              dialogTheme: DialogThemeData(backgroundColor: Colors.white),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                primary: const Color(0xFF2563EB),
                seedColor: const Color(0xFF2563EB),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF1A1B23),
              canvasColor: const Color(0xFF1A1B23),
              primaryColor: const Color(0xFF2563EB),
              textTheme: const TextTheme(
                headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                bodyLarge: TextStyle(fontSize: 15, height: 1.6),
                bodyMedium: TextStyle(fontSize: 13, height: 1.5),
                bodySmall: TextStyle(fontSize: 11, height: 1.4),
                labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                labelMedium: TextStyle(fontSize: 12),
                labelSmall: TextStyle(fontSize: 10),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1A1B23),
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.white,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: Colors.white70),
                actionsIconTheme: IconThemeData(color: Colors.white70),
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                ),
              ),
              cardColor: const Color(0xFF23242A),
              dividerColor: const Color(0xFF2D2F3A),
              drawerTheme: const DrawerThemeData(
                elevation: 16,
                backgroundColor: Color(0xFF1A1B23),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF23242A),
              ),
            ),
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
      final modelController = Get.put(ModelController());
      final sessionController = Get.put(SessionController());
      final mcpController = Get.put(McpController());

      // 加载模型数据
      final modelMaps = await modelController.loadModels();
      final models = modelMaps.map((m) => ChatModel.fromMap(m)).toList();
      modelController.setModels(models);

      // 加载 MCP 配置数据
      await mcpController.loadAll();

      // 加载会话数据
      await sessionController.loadAll();

      // 如果没有会话，自动创建一个默认会话（模拟手动按钮行为）
      if (sessionController.sessions.isEmpty) {
        // 严格模拟 home.dart 中 _createNewSession 的模型匹配逻辑
        ChatModel? selectedModelObject;
        try {
          final modelController = Get.find<ModelController>();
          final availableModels = modelController.models;
          if (availableModels.isNotEmpty) {
            const defaultModelName = 'DeepSeekR1';
            try {
              selectedModelObject = availableModels.firstWhere(
                (m) => m.name == defaultModelName,
              );
            } catch (_) {
              // 没找到 DeepSeekR1，使用第一个可用模型
              selectedModelObject = availableModels.first;
            }
          }
        } catch (_) {
          // ModelController 不可用
        }

        final defaultSession = ChatSession(
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '新对话',
          createdAt: DateTime.now(),
          messages: [],
          chatModel: selectedModelObject, // 有可用模型时自动绑定
          inputContent: '',
        );
        await sessionController.addSession(defaultSession);
      }

      // 启动定时任务调度器
      ScheduledTaskService().start();

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
