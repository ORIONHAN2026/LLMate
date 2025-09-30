// 使用示例：如何在其他页面中使用 SnackBarUtils

import 'package:flutter/material.dart';
import '../utils/snackbar_utils.dart';

class ExampleUsage extends StatelessWidget {
  const ExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SnackBarUtils 使用示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // 显示成功提示
                SnackBarUtils.showSuccess(context, '操作成功完成！');
              },
              child: const Text('显示成功提示'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 显示错误提示
                SnackBarUtils.showError(context, '操作失败，请重试');
              },
              child: const Text('显示错误提示'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 显示信息提示
                SnackBarUtils.showInfo(context, '这是一条信息提示');
              },
              child: const Text('显示信息提示'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 显示警告提示
                SnackBarUtils.showWarning(context, '请注意这个操作');
              },
              child: const Text('显示警告提示'),
            ),
          ],
        ),
      ),
    );
  }
}
