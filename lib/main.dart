import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:get/get.dart';
import 'controllers/model_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/mcp_controller.dart';
import 'pages/home.dart';
import 'pages/loading_page.dart';
import 'services/model_storage_service.dart';
import 'models/bigmodel/chat_model.dart';
import 'storage/isar_service.dart';

// 最小窗口宽度组成: 左侧边栏最小 200 + 中间聊天区最小 520 + 右侧面板最小 260 + 额外缓冲 40
const double kMinLeftSidebarWidth = 200;
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
      titleBarStyle: TitleBarStyle.normal,
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

  // 初始化 Isar 数据库（必须在 ThemeController 之前）
  await IsarService.instance.initialize();

  // 在应用启动前初始化 ThemeController
  Get.put(ThemeController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder:
          (themeController) => GetMaterialApp(
            title: 'ChatHub',
            debugShowCheckedModeBanner: false, // 去掉调试横幅
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                primary: const Color(0xFF3B82F6),
                seedColor: const Color(0xFF3B82F6), // 使用更深更鲜明的蓝色 (blue-700)
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
                  fontSize: 20,
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
              primaryColor: const Color(0xFF3B82F6),

              // 按钮主题配置
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // 主按钮蓝色
                  foregroundColor: Colors.white, // 文字颜色
                  elevation: 2,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // 填充按钮蓝色
                  foregroundColor: Colors.white, // 文字颜色
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6), // 边框按钮蓝色
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6), // 文本按钮蓝色
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
                primary: const Color(0xFF3B82F6),
                seedColor: const Color(0xFF3B82F6),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF1F1F1F),
              canvasColor: const Color(0xFF1F1F1F),
              primaryColor: const Color(0xFF3B82F6),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F1F1F),
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.white,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF60A5FA),
                  side: const BorderSide(color: Color(0xFF60A5FA)),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF60A5FA),
                ),
              ),
              cardColor: const Color(0xFF262626),
              dividerColor: const Color(0xFF30363D),
              drawerTheme: const DrawerThemeData(
                elevation: 16,
                backgroundColor: Color(0xFF1F1F1F),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF262626),
              ),
            ),
            themeMode: themeController.themeMode,
            home: const AppInitializer(),
          ),
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
      final modelMaps = await ModelStorageService.loadModels();
      final models = modelMaps.map((m) => ChatModel.fromMap(m)).toList();
      modelController.setModels(models);

      // 加载 MCP 配置数据
      await mcpController.loadAll();

      // 加载会话数据
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
