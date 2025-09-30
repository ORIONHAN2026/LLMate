import 'package:flutter/material.dart';

/// 响应式设计辅助工具类
class ResponsiveUtils {
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// 判断是否为移动端
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 判断是否为平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 判断是否为桌面端
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// 获取当前设备类型
  static DeviceType getDeviceType(BuildContext context) {
    if (isMobile(context)) return DeviceType.mobile;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 根据屏幕大小返回不同的值
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return desktop;
  }

  /// 获取侧边栏宽度
  static double getSidebarWidth(BuildContext context) {
    return responsive(
      context,
      mobile: 300.0, // 移动端侧边栏稍宽一些
      tablet: 320.0,
      desktop: 280.0,
    );
  }

  /// 获取右侧面板宽度
  static double getRightPanelWidth(BuildContext context) {
    return responsive(
      context,
      mobile: MediaQuery.of(context).size.width * 0.9, // 移动端占90%宽度
      tablet: 400.0,
      desktop: 350.0,
    );
  }

  /// 获取顶部栏高度
  static double getTopBarHeight(BuildContext context) {
    return responsive(
      context,
      mobile: 56.0, // 移动端稍矮一些
      tablet: 60.0,
      desktop: 60.0,
    );
  }

  /// 获取聊天区域的最大宽度
  static double getChatAreaMaxWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1000.0,
    );
  }

  /// 获取用户消息的最大宽度比例
  static double getUserMessageMaxWidthRatio(BuildContext context) {
    return responsive(
      context,
      mobile: 0.85, // 移动端消息占更多宽度
      tablet: 0.75,
      desktop: 0.7,
    );
  }

  /// 获取边距大小
  static EdgeInsets getPagePadding(BuildContext context) {
    return responsive(
      context,
      mobile: const EdgeInsets.all(8.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(16.0),
    );
  }

  /// 获取卡片间距
  static double getCardSpacing(BuildContext context) {
    return responsive(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  /// 检查是否应该显示紧凑版本
  static bool shouldShowCompact(BuildContext context) {
    return isMobile(context) || MediaQuery.of(context).size.height < 600;
  }
}

/// 设备类型枚举
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// 响应式 Widget Builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// 响应式断点 Widget
class ResponsiveBreakpoints extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveBreakpoints({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop;
        }
      },
    );
  }
}
