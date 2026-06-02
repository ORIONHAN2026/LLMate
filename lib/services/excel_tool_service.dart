import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Excel 文件读写内置工具
///
/// 提供两个操作：
/// - `excel_read`：读取 .xlsx 文件内容，返回结构化 JSON
/// - `excel_write`：创建 .xlsx 文件，支持多 Sheet、表头、数据行、单元格样式
class ExcelToolService {
  // ── 入口 ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> execute({
    required String action,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    switch (action) {
      case 'read':
        return _read(callId, arguments);
      case 'write':
        return await _write(callId, arguments);
      default:
        return _error(callId, arguments, '不支持的操作: $action，可用: read/write');
    }
  }

  // ── 读取 Excel ──────────────────────────────────────────

  static Map<String, dynamic> _read(
    String callId,
    Map<String, dynamic> args,
  ) {
    final filePath = _stringArg(args, 'filePath').trim();
    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return _error(callId, args, '文件不存在: $filePath');
    }

    final ext = p.extension(filePath).toLowerCase();
    if (ext != '.xlsx') {
      return _error(callId, args, '仅支持 .xlsx 格式，当前文件: $ext');
    }

    try {
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final sheets = <Map<String, dynamic>>[];

      for (final sheetName in excel.tables.keys) {
        final table = excel.tables[sheetName]!;
        final rows = <List<dynamic>>[];

        for (final row in table.rows) {
          final cells = row.map((cell) {
            if (cell == null || cell.value == null) return '';
            final val = cell.value;
            // CellValue 转字符串
            return val.toString();
          }).toList();
          rows.add(cells);
        }

        sheets.add({
          'name': sheetName,
          'rows': rows,
          'rowCount': rows.length,
          'columnCount': rows.isNotEmpty ? rows.first.length : 0,
        });
      }

      if (kDebugMode) {
        debugPrint(
          '📊 [ExcelTool] 读取: $filePath (${sheets.length} 个 Sheet)',
        );
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'sheetCount': sheets.length,
        'sheets': sheets,
        'message': '已读取 ${sheets.length} 个 Sheet',
      });
    } catch (e) {
      return _error(callId, args, '读取 Excel 失败: $e');
    }
  }

  // ── 写入 Excel ──────────────────────────────────────────

  static Future<Map<String, dynamic>> _write(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final filePath = _stringArg(args, 'filePath').trim();
    final sheetsRaw = args['sheets'];

    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }
    if (sheetsRaw == null) {
      return _error(callId, args, 'sheets 参数不能为空');
    }

    try {
      final excel = Excel.createExcel();

      // 解析 sheets 数据
      final sheetsList = sheetsRaw is List
          ? sheetsRaw
          : (sheetsRaw is Map ? [sheetsRaw] : []);

      // 删除默认创建的 Sheet1
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      for (int i = 0; i < sheetsList.length; i++) {
        final sheetData = sheetsList[i] as Map<String, dynamic>;
        final sheetName = _stringArg(sheetData, 'name').trim();
        final displayName = sheetName.isEmpty ? 'Sheet${i + 1}' : sheetName;

        final headers = _parseStringList(sheetData['headers']);
        final rows = _parseRows(sheetData['rows']);

        final sheet = excel[displayName];

        int startRow = 0;

        // 写入表头
        if (headers.isNotEmpty) {
          for (int c = 0; c < headers.length; c++) {
            final cell = sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: c, rowIndex: 0));
            cell.value = TextCellValue(headers[c]);
            // 表头加粗
            cell.cellStyle = CellStyle(bold: true);
          }
          startRow = 1;
        }

        // 写入数据行
        for (int r = 0; r < rows.length; r++) {
          final row = rows[r];
          for (int c = 0; c < row.length; c++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: c, rowIndex: startRow + r));
            final value = row[c];
            _setCellValue(cell, value);
          }
        }
      }

      // 确保至少有一个 Sheet
      if (excel.tables.isEmpty) {
        excel['Sheet1'];
      }

      // 保存文件
      final file = File(filePath);
      final parent = file.parent;
      if (!parent.existsSync()) {
        await parent.create(recursive: true);
      }

      final bytes = excel.save();
      if (bytes == null) {
        return _error(callId, args, '生成 Excel 文件失败');
      }
      await file.writeAsBytes(bytes);

      final isOverwrite = await file.exists();

      if (kDebugMode) {
        debugPrint(
          '📊 [ExcelTool] ${isOverwrite ? "覆盖" : "创建"}: $filePath (${sheetsList.length} 个 Sheet)',
        );
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'sheetCount': sheetsList.length,
        'overwritten': isOverwrite,
        'message': '${isOverwrite ? "已覆盖" : "已创建"} $filePath（${sheetsList.length} 个 Sheet）',
      });
    } catch (e) {
      return _error(callId, args, '写入 Excel 失败: $e');
    }
  }

  // ── 辅助方法 ──────────────────────────────────────────────

  static void _setCellValue(Data cell, dynamic value) {
    if (value == null) {
      cell.value = TextCellValue('');
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is num) {
      cell.value = DoubleCellValue(value.toDouble());
    } else if (value is bool) {
      cell.value = BoolCellValue(value);
    } else {
      cell.value = TextCellValue(value.toString());
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return [];
  }

  static List<List<dynamic>> _parseRows(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((row) {
        if (row is List) return row;
        return [row];
      }).toList();
    }
    return [];
  }

  static String _stringArg(Map<String, dynamic> args, String key) {
    final value = args[key];
    return value == null ? '' : value.toString();
  }

  static Map<String, dynamic> _ok(
    String callId,
    Map<String, dynamic> args,
    Map<String, dynamic> data,
  ) {
    return {
      'id': callId,
      'name': 'excel_read',
      'args': args,
      'result': jsonEncode(data),
      'isError': false,
    };
  }

  static Map<String, dynamic> _error(
    String callId,
    Map<String, dynamic> args,
    String message,
  ) {
    return {
      'id': callId,
      'name': 'excel_read',
      'args': args,
      'result': message,
      'isError': true,
    };
  }
}
