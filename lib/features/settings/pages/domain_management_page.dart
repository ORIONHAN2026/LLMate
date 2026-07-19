import 'dart:io' show File;
import '../../../widgets/standard_app_bar.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../services/storage_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../../controllers/settings_controller.dart';
import '../../../core/http/local_http_service.dart';

/// 域名管理页面
///
/// 支持域名设置、证书设置、HTTPS 开关。
/// 上传证书（crt/cert + key）后自动开启 HTTPS。
class DomainManagementPage extends StatefulWidget {
  const DomainManagementPage({super.key});

  @override
  State<DomainManagementPage> createState() => _DomainManagementPageState();
}

class _DomainManagementPageState extends State<DomainManagementPage> {
  late final SettingsController _controller;
  late final TextEditingController _domainController;
  late final TextEditingController _httpPortController;
  late final TextEditingController _httpsPortController;
  String? _certPath;
  String? _keyPath;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
    _domainController = TextEditingController(text: _controller.domain.value);
    _httpPortController =
        TextEditingController(text: _controller.httpPort.value.toString());
    _httpsPortController =
        TextEditingController(text: _controller.httpsPort.value.toString());
    _certPath = _controller.certPath.value;
    _keyPath = _controller.keyPath.value;
  }

  @override
  void dispose() {
    _domainController.dispose();
    _httpPortController.dispose();
    _httpsPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: StandardAppBar(
        title: l10n.domainManagement,
      ),
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

            // 域名设置区域
            _buildSectionTitle(l10n.domainSettings, colorScheme),
            const SizedBox(height: 8),
            _buildDomainSection(colorScheme, l10n),

            const SizedBox(height: 32),

            // 端口设置区域
            _buildSectionTitle(l10n.portSettings, colorScheme),
            const SizedBox(height: 8),
            _buildPortSection(colorScheme, l10n),

            const SizedBox(height: 32),

            // 证书设置区域
            _buildSectionTitle(l10n.certificateSettings, colorScheme),
            const SizedBox(height: 8),
            _buildCertificateSection(colorScheme, l10n),

            const SizedBox(height: 32),

            // HTTPS 状态
            _buildSectionTitle(l10n.httpsStatus, colorScheme),
            const SizedBox(height: 8),
            _buildHttpsSection(colorScheme, l10n),

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
              color: _isStarting ? Colors.orange : (running ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.3)),
              boxShadow: (_isStarting || running)
                  ? [
                      BoxShadow(
                        color: (_isStarting ? Colors.orange : Colors.green).withValues(alpha: 0.4),
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
                    color: _isStarting
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
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: colorScheme.primary,
              ),
              label: Text(
                l10n.restart,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _restartService() async {
    try {
      setState(() {
        _isStarting = true;
      });
      final controller = Get.find<LocalHttpServiceController>();
      await controller.restart();
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

  Widget _buildDomainSection(ColorScheme colorScheme, AppLocalizations l10n) {
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
          Text(
            l10n.domainAddress,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _domainController,
            onSubmitted: (_) => _autoSave(),
            decoration: InputDecoration(
              hintText: l10n.domainHint,
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
                borderSide: BorderSide(color: colorScheme.primary, width: 1),
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
            l10n.domainDesc,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
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
                borderSide: BorderSide(color: colorScheme.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          // HTTPS 端口
          Text(
            l10n.httpsPort,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _httpsPortController,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _autoSave(),
            decoration: InputDecoration(
              hintText: '443',
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
                borderSide: BorderSide(color: colorScheme.primary, width: 1),
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

  Widget _buildCertificateSection(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // 证书文件
          _buildCertTile(
            colorScheme,
            icon: Icons.description,
            title: l10n.sslCertificate,
            subtitle: _certPath != null ? _certPath!.split('/').last : l10n.notSet,
            selected: _certPath != null,
            isFirst: true,
            isLast: false,
            onTap: () => _pickCertFile(l10n),
            onClear: _certPath != null ? () => _clearCert() : null,
          ),
          _buildDivider(colorScheme),
          // 私钥文件
          _buildCertTile(
            colorScheme,
            icon: Icons.lock,
            title: l10n.sslPrivateKey,
            subtitle: _keyPath != null ? _keyPath!.split('/').last : l10n.notSet,
            selected: _keyPath != null,
            isFirst: false,
            isLast: true,
            onTap: () => _pickKeyFile(l10n),
            onClear: _keyPath != null ? () => _clearKey() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCertTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                size: 22,
                color: colorScheme.primary,
              ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.cancel,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHttpsSection(ColorScheme colorScheme, AppLocalizations l10n) {
    final hasCert = _certPath != null && _keyPath != null;
    final httpsOn = hasCert; // 上传证书后自动开启

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
          Icon(
            httpsOn ? Icons.lock : Icons.lock_open,
            size: 20,
            color: httpsOn ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.httpsEnabled,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCert
                      ? l10n.httpsEnabledDesc
                      : l10n.httpsDisabledDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: httpsOn
                  ? Colors.green.withValues(alpha: 0.1)
                  : colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              httpsOn ? l10n.enabled : l10n.disabled,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: httpsOn ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info,
            size: 18,
            color: colorScheme.primary,
          ),
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

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
    );
  }

  Future<void> _pickCertFile(AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['crt', 'cert', 'pem', 'cer'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final srcPath = result.files.single.path;
        if (srcPath != null) {
          await StoragePaths.ensureSslDir();
          final destPath = p.join(StoragePaths.sslDir, 'server.crt');
          await File(srcPath).copy(destPath);
          setState(() {
            _certPath = destPath;
          });
          _autoSave();
        }
      }
    } catch (e) {
      debugPrint('选择证书文件失败: $e');
    }
  }

  Future<void> _pickKeyFile(AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['key', 'pem'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final srcPath = result.files.single.path;
        if (srcPath != null) {
          await StoragePaths.ensureSslDir();
          final destPath = p.join(StoragePaths.sslDir, 'server.key');
          await File(srcPath).copy(destPath);
          setState(() {
            _keyPath = destPath;
          });
          _autoSave();
        }
      }
    } catch (e) {
      debugPrint('选择私钥文件失败: $e');
    }
  }

  void _clearCert() {
    if (_certPath != null) {
      try {
        File(_certPath!).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _certPath = null;
    });
    _autoSave();
  }

  void _clearKey() {
    if (_keyPath != null) {
      try {
        File(_keyPath!).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _keyPath = null;
    });
    _autoSave();
  }

  Future<void> _autoSave() async {
    final domain = _domainController.text.trim();

    // 去除可能的协议前缀
    final cleanDomain = domain
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r':\d+$'), '')
        .replaceFirst(RegExp(r'/$'), '');

    final httpPort = int.tryParse(_httpPortController.text.trim()) ?? 80;
    final httpsPort = int.tryParse(_httpsPortController.text.trim()) ?? 443;

    final hasCert =
        _certPath != null &&
        _certPath!.isNotEmpty &&
        _keyPath != null &&
        _keyPath!.isNotEmpty;

    await _controller.saveConfig(
      domain: cleanDomain,
      certPath: _certPath,
      keyPath: _keyPath,
      httpsEnabled: hasCert,
      httpPort: httpPort,
      httpsPort: httpsPort,
    );
  }
}
