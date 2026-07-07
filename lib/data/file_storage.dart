import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 通用的本地文件存储工具
class FileStorage {
  FileStorage._();

  // ── JSON 读写 ──

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

  static Future<void> writeJson(String path, Map<String, dynamic> data) async {
    await _writeFile(path, const JsonEncoder.withIndent('  ').convert(data));
  }

  static Future<void> writeJsonList(String path, List<dynamic> data) async {
    await _writeFile(path, const JsonEncoder.withIndent('  ').convert(data));
  }

  // ── 纯文本读写 ──

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

  static Future<void> writeText(String path, String content) async {
    await _writeFile(path, content);
  }

  // ── 删除 ──

  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<void> deleteDir(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  // ── 写入文件（确保目录存在） ──

  static Future<void> _writeFile(String path, String content) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      // 原子写入：先写临时文件再 rename，避免进程中断导致目标文件半写完而损坏
      final tmp = File('$path.tmp');
      await tmp.writeAsString(content);
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('⚠️ FileStorage._writeFile($path) 失败: $e');
    }
  }
}
