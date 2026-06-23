import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 通用的本地文件存储工具
///
/// 所有读写都是原子性的（先写临时文件再重命名），防止数据损坏。
class FileStorage {
  FileStorage._();

  // ── JSON 读写 ──

  /// 读取 JSON 文件，解析为 Map；文件不存在或解析失败返回 null
  static Future<Map<String, dynamic>?> readJson(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ FileStorage.readJson($path) 失败: $e');
      return null;
    }
  }

  /// 读取 JSON 文件，解析为 List
  static Future<List<dynamic>?> readJsonList(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      return jsonDecode(content) as List<dynamic>;
    } catch (e) {
      debugPrint('⚠️ FileStorage.readJsonList($path) 失败: $e');
      return null;
    }
  }

  /// 写入 JSON Map 到文件（原子写入）
  static Future<void> writeJson(String path, Map<String, dynamic> data) async {
    await _atomicWrite(path, const JsonEncoder.withIndent('  ').convert(data));
  }

  /// 写入 JSON List 到文件（原子写入）
  static Future<void> writeJsonList(String path, List<dynamic> data) async {
    await _atomicWrite(path, const JsonEncoder.withIndent('  ').convert(data));
  }

  // ── 纯文本读写 ──

  /// 读取纯文本文件
  static Future<String?> readText(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      debugPrint('⚠️ FileStorage.readText($path) 失败: $e');
      return null;
    }
  }

  /// 写入纯文本文件（原子写入）
  static Future<void> writeText(String path, String content) async {
    await _atomicWrite(path, content);
  }

  // ── 删除 ──

  /// 删除单个文件（静默失败）
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 删除整个目录（递归，静默失败）
  static Future<void> deleteDir(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  // ── 原子写入 ──

  static Future<void> _atomicWrite(String path, String content) async {
    final file = File(path);
    // 确保目标目录存在
    await file.parent.create(recursive: true);
    // 写入临时文件（临时文件与目标文件在同一目录下）
    final tmp = File('$path.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(content);
    // 重命名（同分区下是原子操作）
    try {
      await tmp.rename(path);
    } catch (_) {
      // fallback：确保目标目录存在后再 copy
      await file.parent.create(recursive: true);
      await tmp.copy(path);
      await tmp.delete();
    }
  }
}
