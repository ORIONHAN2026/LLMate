import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:chathub/main.dart';
import 'package:chathub/controllers/theme_controller.dart';

void main() {
  group('Theme System Tests', () {
    late ThemeController themeController;

    setUp(() {
      // 在每个测试前重置Get容器
      Get.reset();
      themeController = Get.put(ThemeController());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('App should start with light theme by default', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // 等待初始化完成
      await tester.pumpAndSettle();
      
      // 验证默认是浅色主题
      expect(themeController.isDarkMode.value, false);
    });

    testWidgets('Theme toggle should work', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // 初始状态应该是浅色主题
      expect(themeController.isDarkMode.value, false);
      
      // 切换到暗色主题
      themeController.toggleTheme();
      await tester.pumpAndSettle();
      
      // 验证已切换到暗色主题
      expect(themeController.isDarkMode.value, true);
      
      // 再次切换回浅色主题
      themeController.toggleTheme();
      await tester.pumpAndSettle();
      
      // 验证已切换回浅色主题
      expect(themeController.isDarkMode.value, false);
    });

    test('ThemeController should initialize correctly', () {
      // 验证控制器正确初始化
      expect(themeController.isDarkMode.value, false);
    });

    test('Theme toggle should change isDarkMode value', () {
      // 初始状态
      expect(themeController.isDarkMode.value, false);
      
      // 切换主题
      themeController.toggleTheme();
      expect(themeController.isDarkMode.value, true);
      
      // 再次切换
      themeController.toggleTheme();
      expect(themeController.isDarkMode.value, false);
    });
  });
}
