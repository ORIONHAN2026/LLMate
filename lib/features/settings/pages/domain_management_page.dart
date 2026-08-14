import 'package:llmate/features/widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../l10n/app_localizations.dart';
import '../../../controllers/settings_controller.dart';
import '../../../controllers/address_detector_controller.dart';
import '../../../core/http/local_http_service.dart';

/// 服务管理页面
class DomainManagementPage extends StatefulWidget {
  const DomainManagementPage({super.key});

  @override
  State<DomainManagementPage> createState() => _DomainManagementPageState();
}

class _DomainManagementPageState extends State<DomainManagementPage> {
  late final SettingsController _controller;
  late final TextEditingController _httpPortController;
  bool _isStarting = false;

  late final AddressDetectorController _addressController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
    _httpPortController = TextEditingController(
      text: _controller.httpPort.value.toString(),
    );

    _addressController = Get.put(AddressDetectorController());
    // 若服务已运行，则首帧绘制后自动检测地址，避免 build 期间触发 Rx 通知
    if (LocalHttpService.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addressController.detect();
      });
    }
  }

  @override
  void dispose() {
    _httpPortController.dispose();
    Get.delete<AddressDetectorController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: StandardAppBar(title: l10n.domainManagement),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 服务状态区域
            _buildSectionTitle(l10n.serviceStatus, colorScheme),
            const SizedBox(height: 8),
            _buildServiceStatus(colorScheme, l10n),

            const SizedBox(height: 32),

            // 访问地址区域（内网 / 外网自动检测）
            _buildSectionTitle(l10n.accessAddress, colorScheme),
            const SizedBox(height: 8),
            _buildAccessAddressSection(colorScheme, l10n),

            const SizedBox(height: 32),

            // 端口设置区域
            _buildSectionTitle(l10n.portSettings, colorScheme),
            const SizedBox(height: 8),
            _buildPortSection(colorScheme, l10n),

            const SizedBox(height: 32),

            // 说明
            _buildInfoSection(colorScheme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatus(ColorScheme colorScheme, AppLocalizations l10n) {
    final running = LocalHttpService.isRunning;

    String statusText;
    if (_isStarting) {
      statusText = l10n.serviceStarting;
    } else if (running) {
      statusText = l10n.serviceRunning;
    } else {
      statusText = l10n.serviceStopped;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // 状态指示灯
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _isStarting
                      ? Colors.orange
                      : (running
                          ? Colors.green
                          : colorScheme.onSurface.withValues(alpha: 0.3)),
              boxShadow:
                  (_isStarting || running)
                      ? [
                        BoxShadow(
                          color: (_isStarting ? Colors.orange : Colors.green)
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.localService,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _isStarting
                            ? Colors.orange
                            : (running
                                ? Colors.green
                                : colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          if (running)
            TextButton.icon(
              onPressed: _restartService,
              icon: Icon(Icons.refresh, size: 16, color: colorScheme.onSurface),
              label: Text(
                l10n.restart,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccessAddressSection(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final running = LocalHttpService.isRunning;

    return Obx(() {
      final detector = _addressController;
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内网地址
            _buildAddressRow(
              colorScheme,
              l10n,
              icon: Icons.router,
              label: l10n.localAddress,
              address: detector.localAddress.value,
              loading:
                  detector.isDetecting.value &&
                  detector.localAddress.value == null,
              running: running,
            ),
            const SizedBox(height: 14),
            // 外网地址
            _buildAddressRow(
              colorScheme,
              l10n,
              icon: Icons.public,
              label: l10n.externalAddress,
              address: detector.externalAddress.value,
              loading:
                  detector.isDetecting.value &&
                  detector.externalAddress.value == null,
              running: running,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    running ? l10n.addressDesc : l10n.serviceNotRunningHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (running)
                  TextButton.icon(
                    onPressed:
                        detector.isDetecting.value
                            ? null
                            : () => detector.detect(force: true),
                    icon:
                        detector.isDetecting.value
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(
                              Icons.refresh,
                              size: 16,
                              color: colorScheme.onSurface,
                            ),
                    label: Text(
                      detector.isDetecting.value
                          ? l10n.detecting
                          : l10n.reDetect,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAddressRow(
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    required IconData icon,
    required String label,
    required String? address,
    required bool loading,
    required bool running,
  }) {
    final hasAddress = address != null && address.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              if (loading)
                Text(
                  l10n.detecting,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                )
              else if (hasAddress)
                SelectableText(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                )
              else
                Text(
                  running ? l10n.detecting : l10n.serviceNotRunningHint,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
        if (hasAddress)
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: address));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.copied),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              Icons.copy,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            tooltip: l10n.copyAddress,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
      ],
    );
  }

  Future<void> _restartService() async {
    try {
      setState(() {
        _isStarting = true;
      });
      final controller = Get.find<LocalHttpServiceController>();
      await controller.restart();
      // 重启后重新检测地址
      _addressController.detect(force: true);
      setState(() {
        _isStarting = false;
      });
    } catch (e) {
      debugPrint('重启服务失败: $e');
      setState(() {
        _isStarting = false;
      });
    }
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildPortSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTTP 端口
          Text(
            l10n.httpPort,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _httpPortController,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _autoSave(),
            decoration: InputDecoration(
              hintText: '80',
              hintStyle: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.onSurface, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.portDesc,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 18, color: colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.domainInfoDesc,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _autoSave() async {
    final httpPort = int.tryParse(_httpPortController.text.trim()) ?? 80;

    await _controller.saveConfig(domain: _controller.domain.value, httpPort: httpPort);
  }
}
