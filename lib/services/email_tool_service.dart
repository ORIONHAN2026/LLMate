import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// 邮件读写内置工具
///
/// - `email_read`：通过 IMAP 读取邮件（列出、搜索、读取）
/// - `email_write`：通过 SMTP 发送邮件（支持 HTML 正文和附件）
class EmailToolService {
  // ── 入口 ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> execute({
    required String action,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    switch (action) {
      case 'read':
        return await _read(callId, arguments);
      case 'write':
        return await _write(callId, arguments);
      default:
        return _error(callId, arguments, '不支持的操作: $action，可用: read/write');
    }
  }

  // ── 读取邮件 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _read(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final host = _stringArg(args, 'host');
    final port = args['port'] ?? 993;
    final username = _stringArg(args, 'username');
    final password = _stringArg(args, 'password');
    final useSSL = args['useSSL'] != false;
    final readAction = _stringArg(args, 'action', 'list');
    final folder = _stringArg(args, 'folder', 'INBOX');
    final limit = (args['limit'] ?? 10) as int;
    final emailId = _stringArg(args, 'emailId');
    final query = _stringArg(args, 'query');

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      return _error(callId, args, 'IMAP 需要提供 host、username、password');
    }

    try {
      final socket = useSSL
          ? await SecureSocket.connect(host, port as int, timeout: const Duration(seconds: 15))
          : await Socket.connect(host, port as int, timeout: const Duration(seconds: 15));

      // 读取服务器问候
      final greeting = await _imapRead(socket);
      if (!greeting.contains('OK')) {
        socket.destroy();
        return _error(callId, args, 'IMAP 连接失败: $greeting');
      }

      // 登录
      socket.writeln('A001 LOGIN $username $password');
      final loginResp = await _imapRead(socket);
      if (!loginResp.contains('OK')) {
        socket.destroy();
        return _error(callId, args, 'IMAP 登录失败: $loginResp');
      }

      Map<String, dynamic> result;

      switch (readAction) {
        case 'list':
          result = await _listEmails(socket, folder, limit);
        case 'fetch':
          if (emailId.isEmpty) {
            socket.destroy();
            return _error(callId, args, 'fetch 操作需要 emailId 参数');
          }
          result = await _fetchEmail(socket, folder, emailId);
        case 'search':
          if (query.isEmpty) {
            socket.destroy();
            return _error(callId, args, 'search 操作需要 query 参数');
          }
          result = await _searchEmails(socket, folder, query, limit);
        default:
          socket.destroy();
          return _error(callId, args, '不支持的 email_read action: $readAction');
      }

      socket.writeln('A999 LOGOUT');
      socket.destroy();

      return _ok(callId, args, result);
    } catch (e) {
      return _error(callId, args, '邮件读取失败: $e');
    }
  }

  // ── 发送邮件 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _write(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final host = _stringArg(args, 'host');
    final port = args['port'] ?? 465;
    final username = _stringArg(args, 'username');
    final password = _stringArg(args, 'password');
    final useSSL = args['useSSL'] != false;
    final to = args['to'];
    final cc = args['cc'];
    final bcc = args['bcc'];
    final subject = _stringArg(args, 'subject');
    final body = _stringArg(args, 'body');
    final htmlBody = _stringArg(args, 'htmlBody');
    final attachments = args['attachments'];

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      return _error(callId, args, 'SMTP 需要提供 host、username、password');
    }
    if (to == null) {
      return _error(callId, args, '发送邮件需要 to 参数（收件人）');
    }

    try {
      final smtpServer = useSSL
          ? SmtpServer(host, port: port as int, username: username, password: password, ssl: true)
          : SmtpServer(host, port: port as int, username: username, password: password, ssl: false);

      final message = Message()
        ..from = Address(username)
        ..subject = subject;

      // 收件人
      if (to is List) {
        message.recipients.addAll(to.map((e) => Address(e.toString())));
      } else {
        message.recipients.add(Address(to.toString()));
      }

      // 抄送
      if (cc is List) {
        message.ccRecipients.addAll(cc.map((e) => Address(e.toString())));
      } else if (cc is String && cc.isNotEmpty) {
        message.ccRecipients.add(Address(cc));
      }

      // 密送
      if (bcc is List) {
        message.bccRecipients.addAll(bcc.map((e) => Address(e.toString())));
      } else if (bcc is String && bcc.isNotEmpty) {
        message.bccRecipients.add(Address(bcc));
      }

      // 正文
      if (body.isNotEmpty) {
        message.text = body;
      }
      if (htmlBody.isNotEmpty) {
        message.html = htmlBody;
      }

      // 附件
      if (attachments is List) {
        for (final att in attachments) {
          final attPath = att.toString();
          final file = File(attPath);
          if (file.existsSync()) {
            message.attachments.add(FileAttachment(file));
          }
        }
      }

      await send(message, smtpServer);

      if (kDebugMode) {
        debugPrint('📧 [EmailTool] 发送成功: $subject → $to');
      }

      return _ok(callId, args, {
        'action': 'send',
        'to': to.toString(),
        'subject': subject,
        'message': '邮件已发送: $subject',
      });
    } catch (e) {
      return _error(callId, args, '发送邮件失败: $e');
    }
  }

  // ── IMAP 操作 ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> _listEmails(
    Socket socket,
    String folder,
    int limit,
  ) async {
    socket.writeln('A010 SELECT $folder');
    await _imapRead(socket);

    socket.writeln('A020 SEARCH ALL');
    final searchResp = await _imapRead(socket);

    final ids = _parseSearchIds(searchResp);
    if (ids.isEmpty) {
      return {'emails': [], 'total': 0, 'message': '邮箱 $folder 为空'};
    }

    final recentIds = ids.reversed.take(limit).toList();
    final emails = <Map<String, dynamic>>[];

    for (int i = 0; i < recentIds.length; i++) {
      socket.writeln('A0${30 + i} FETCH ${recentIds[i]} (ENVELOPE)');
      final fetchResp = await _imapRead(socket);
      emails.add(_parseEnvelope(fetchResp, recentIds[i].toString()));
    }

    return {
      'folder': folder,
      'emails': emails,
      'total': ids.length,
      'message': '共 ${ids.length} 封邮件，显示最近 ${emails.length} 封',
    };
  }

  static Future<Map<String, dynamic>> _fetchEmail(
    Socket socket,
    String folder,
    String emailId,
  ) async {
    socket.writeln('A010 SELECT $folder');
    await _imapRead(socket);

    socket.writeln('A020 FETCH $emailId (BODY[])');
    final fetchResp = await _imapRead(socket);

    return {
      'folder': folder,
      'emailId': emailId,
      'rawContent': fetchResp,
      'message': '已读取邮件 #$emailId',
    };
  }

  static Future<Map<String, dynamic>> _searchEmails(
    Socket socket,
    String folder,
    String query,
    int limit,
  ) async {
    socket.writeln('A010 SELECT $folder');
    await _imapRead(socket);

    socket.writeln('A020 SEARCH SUBJECT "$query"');
    final searchResp = await _imapRead(socket);

    final ids = _parseSearchIds(searchResp);
    if (ids.isEmpty) {
      return {'emails': [], 'total': 0, 'query': query, 'message': '未找到匹配 "$query" 的邮件'};
    }

    final recentIds = ids.reversed.take(limit).toList();
    final emails = <Map<String, dynamic>>[];

    for (int i = 0; i < recentIds.length; i++) {
      socket.writeln('A0${30 + i} FETCH ${recentIds[i]} (ENVELOPE)');
      final fetchResp = await _imapRead(socket);
      emails.add(_parseEnvelope(fetchResp, recentIds[i].toString()));
    }

    return {
      'folder': folder,
      'query': query,
      'emails': emails,
      'total': ids.length,
      'message': '搜索到 ${ids.length} 封匹配 "$query" 的邮件',
    };
  }

  // ── IMAP 底层 ─────────────────────────────────────────────

  static Future<String> _imapRead(Socket socket) async {
    final completer = Completer<String>();
    final buf = <int>[];

    StreamSubscription? sub;
    Timer? timer;

    timer = Timer(const Duration(seconds: 10), () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(utf8.decode(buf, allowMalformed: true));
    });

    sub = socket.listen(
      (data) {
        buf.addAll(data);
        final text = utf8.decode(buf, allowMalformed: true);
        if (RegExp(r'A\d{3}\s+(OK|NO|BAD)').hasMatch(text) || text.startsWith('*')) {
          // 等待 tagged response
          if (RegExp(r'A\d{3}\s+(OK|NO|BAD)').hasMatch(text)) {
            timer?.cancel();
            sub?.cancel();
            if (!completer.isCompleted) completer.complete(text);
          }
        }
      },
      onDone: () {
        timer?.cancel();
        if (!completer.isCompleted) completer.complete(utf8.decode(buf, allowMalformed: true));
      },
      onError: (e) {
        timer?.cancel();
        if (!completer.isCompleted) completer.complete('ERROR: $e');
      },
    );

    return completer.future;
  }

  static List<int> _parseSearchIds(String response) {
    final match = RegExp(r'\* SEARCH (.+)').firstMatch(response);
    if (match == null) return [];
    return match.group(1)!
        .split(' ')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((n) => n > 0)
        .toList();
  }

  static Map<String, dynamic> _parseEnvelope(String response, String id) {
    String subject = '';
    final subjectMatch = RegExp(r'SUBJECT\s+\{(\d+)\}').firstMatch(response);
    if (subjectMatch != null) {
      final len = int.parse(subjectMatch.group(1)!);
      final startIdx = response.indexOf('}\r\n', subjectMatch.end);
      if (startIdx != -1 && startIdx + 2 + len <= response.length) {
        subject = response.substring(startIdx + 2, startIdx + 2 + len);
      }
    }
    if (subject.isEmpty) {
      final simpleMatch = RegExp(r'"SUBJECT"\s+"([^"]*)"').firstMatch(response);
      if (simpleMatch != null) subject = simpleMatch.group(1) ?? '';
    }

    return {'id': id, 'subject': subject, 'from': '', 'date': ''};
  }

  // ── 辅助 ──────────────────────────────────────────────────

  static String _stringArg(Map<String, dynamic> args, String key, [String defaultValue = '']) {
    final value = args[key];
    return value == null ? defaultValue : value.toString();
  }

  static Map<String, dynamic> _ok(String callId, Map<String, dynamic> args, Map<String, dynamic> data) {
    return {'id': callId, 'name': 'email_read', 'args': args, 'result': jsonEncode(data), 'isError': false};
  }

  static Map<String, dynamic> _error(String callId, Map<String, dynamic> args, String message) {
    return {'id': callId, 'name': 'email_read', 'args': args, 'result': message, 'isError': true};
  }
}
