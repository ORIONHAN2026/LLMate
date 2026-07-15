import 'package:flutter/material.dart';
import 'package:llmate/l10n/app_localizations.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LLMate 标题
            Text(
              'LLMate',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // 副标题/标语
            Text(
              loc?.loadingPageSubtitle ?? 'Intelligent Enterprise AI Workspace',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            // 加载动画
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
