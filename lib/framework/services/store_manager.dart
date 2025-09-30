import 'package:objectbox/objectbox.dart';
import '../../../objectbox.g.dart';
import 'package:path/path.dart';
import 'dart:io';

/// ObjectBox Store管理器
/// 用于管理单例Store实例
class StoreManager {
  static final Map<String, Store> _stores = {};
  static final Map<String, int> _referenceCount = {};

  /// 获取或创建Store实例
  static Store getStore(String ragId) {
    if (!_stores.containsKey(ragId)) {
      final appPath = Directory.current.path;
      final directory = join(appPath, 'objectbox_$ragId');
      _stores[ragId] = Store(getObjectBoxModel(), directory: directory);
      _referenceCount[ragId] = 1;
    } else {
      _referenceCount[ragId] = (_referenceCount[ragId] ?? 0) + 1;
    }
    return _stores[ragId]!;
  }

  /// 关闭Store实例
  static void closeStore(String ragId) {
    if (_stores.containsKey(ragId)) {
      _referenceCount[ragId] = (_referenceCount[ragId] ?? 1) - 1;
      
      if (_referenceCount[ragId]! <= 0) {
        _stores[ragId]?.close();
        _stores.remove(ragId);
        _referenceCount.remove(ragId);
      }
    }
  }

  /// 关闭所有Store实例
  static void closeAllStores() {
    for (final store in _stores.values) {
      store.close();
    }
    _stores.clear();
    _referenceCount.clear();
  }
}
