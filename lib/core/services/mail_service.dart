import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../models/system_setting.dart';

class MailService {
  const MailService._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// 支持英文逗号和中文逗号分隔的收件人列表。
  static List<String> parseRecipients(String value) => value
      .split(RegExp(r'[,，]'))
      .map((email) => email.trim())
      .where((email) => email.isNotEmpty)
      .toList(growable: false);

  static bool isValidRecipientList(String value) {
    final recipients = parseRecipients(value);
    return recipients.isNotEmpty && recipients.every(_emailPattern.hasMatch);
  }

  static Future<void> sendSessionApiKey({
    required SystemSetting settings,
    required String recipients,
    required String sessionName,
    required String apiKey,
  }) async {
    final security = settings.smtpSecurity.value;
    final server = SmtpServer(
      settings.smtpHost.value.trim(),
      port: settings.smtpPort.value,
      username:
          settings.smtpUsername.value.trim().isEmpty
              ? null
              : settings.smtpUsername.value.trim(),
      password:
          settings.smtpPassword.value.isEmpty
              ? null
              : settings.smtpPassword.value,
      ssl: security == 'ssl',
      allowInsecure: security == 'none',
    );
    final senderEmail = settings.smtpSenderEmail.value.trim();
    final senderName = settings.smtpSenderName.value.trim();
    final message =
        Message()
          ..from = Address(
            senderEmail,
            senderName.isEmpty ? 'LLMate' : senderName,
          )
          ..recipients.addAll(parseRecipients(recipients))
          ..subject = 'LLMate 会话密钥 - $sessionName'
          ..text = '会话：$sessionName\nAPI 密钥：$apiKey\n\n请妥善保管此密钥，不要转发给不可信的人。';
    await send(message, server);
  }
}
