import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../core/http/local_http_service.dart';
import '../core/services/address_detector.dart';
import '../controllers/settings_controller.dart';

/// 访问地址检测控制器。
///
/// 负责在服务启动后自动检测内网地址（局域网 IP）与外网地址（公网 IP），
/// 供「服务管理」页面的访问地址区域展示。
class AddressDetectorController extends GetxController {
  AddressDetectorController({this.detector});

  final AddressDetector? detector;

  final _detector = AddressDetector();

  final localAddress = RxnString();
  final externalAddress = RxnString();
  final isDetecting = false.obs;

  /// 是否已检测过（用于区分「未检测到」与「尚未检测」）。
  final hasDetected = false.obs;

  Future<void> detect({bool force = false}) async {
    // 服务未启动时不检测
    if (!LocalHttpService.isRunning) {
      localAddress.value = null;
      externalAddress.value = null;
      hasDetected.value = false;
      return;
    }
    if (isDetecting.value && !force) return;

    isDetecting.value = true;
    try {
      final d = detector ?? _detector;
      final localFuture = AddressDetector.getLocalIp();
      final externalFuture = d.getExternalIp();
      final results = await Future.wait<String?>([
        localFuture,
        externalFuture,
      ]);
      localAddress.value = results[0];
      externalAddress.value = results[1];
      hasDetected.value = true;
      // 持久化到系统配置，供会话页等处直接读取
      try {
        await Get.find<SettingsController>().saveAddresses(
          lanIp: results[0],
          publicIp: results[1],
        );
      } catch (e) {
        debugPrint('[AddressDetector] save addresses failed: $e');
      }
    } catch (e) {
      debugPrint('[AddressDetector] detect failed: $e');
    } finally {
      isDetecting.value = false;
    }
  }

  void clear() {
    localAddress.value = null;
    externalAddress.value = null;
    hasDetected.value = false;
  }
}
