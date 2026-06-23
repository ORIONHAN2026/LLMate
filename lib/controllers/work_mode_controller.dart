import 'package:get/get.dart';

import '../storage/isar_models.dart';
import '../storage/isar_service.dart';

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
      final isar = IsarService.instance.isar;
      final setting = await isar.isarSettings.getByKey(_settingsKey);
      if (setting != null) {
        final mode = WorkMode.values.cast<WorkMode?>().firstWhere(
              (m) => m?.name == setting.value,
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
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarSettings.getByKey(_settingsKey);
        if (existing != null) {
          existing.value = mode.name;
          await isar.isarSettings.put(existing);
        } else {
          await isar.isarSettings.put(IsarSettings()
            ..key = _settingsKey
            ..value = mode.name);
        }
      });
    } catch (e) {
      // 忽略保存错误
    }
  }
}
