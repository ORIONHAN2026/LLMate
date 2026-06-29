import 'package:get/get.dart';

import '../data/storage_service.dart';

/// 工作模式枚举
enum WorkMode {
  /// 商务
  business,

  /// 财务
  finance,

  /// 法务
  legal,

  /// 市场
  marketing,
}

/// 工作模式控制器，负责读写全局工作模式配置
class WorkModeController extends GetxController {
  static const _settingsKey = 'workMode';

  var workMode = WorkMode.business.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = StorageService.instance.store;
      final setting = await store.isarSettings.getByKey(_settingsKey);
      if (setting != null) {
        final mode = WorkMode.values.cast<WorkMode?>().firstWhere(
              (m) => m?.name == setting['value'],
              orElse: () => null,
            );
        if (mode != null) {
          workMode.value = mode;
        }
      }
    } catch (e) {
      // 忽略加载错误，使用默认值
    }
  }

  Future<void> setWorkMode(WorkMode mode) async {
    workMode.value = mode;
    try {
      final store = StorageService.instance.store;
      await store.isarSettings.put(_settingsKey, mode.name);
    } catch (e) {
      // 忽略保存错误
    }
  }
}
