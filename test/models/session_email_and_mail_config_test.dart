import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/models/chat/session.dart';
import 'package:llmate/models/system_setting.dart';
import 'package:llmate/core/services/mail_service.dart';

void main() {
  test('会话邮箱可序列化并可清除', () {
    final session = ChatSession(
      sessionId: 'session-test',
      name: '测试会话',
      createdAt: DateTime(2026),
      messages: const [],
      email: 'user@example.com',
    );

    final restored = ChatSession.fromJson(session.toJson());
    expect(restored.email, 'user@example.com');
    expect(restored.copyWith(clearEmail: true).email, isNull);
  });

  test('SMTP 配置可在系统设置中往返序列化', () {
    final setting = SystemSetting();
    setting.smtpHost.value = 'smtp.example.com';
    setting.smtpPort.value = 465;
    setting.smtpUsername.value = 'mailer';
    setting.smtpPassword.value = 'secret';
    setting.smtpSenderEmail.value = 'sender@example.com';
    setting.smtpSenderName.value = 'LLMate Server';
    setting.smtpSecurity.value = 'ssl';

    final restored = SystemSetting.fromJson(setting.toJson());
    expect(restored.smtpHost.value, 'smtp.example.com');
    expect(restored.smtpPort.value, 465);
    expect(restored.smtpUsername.value, 'mailer');
    expect(restored.smtpPassword.value, 'secret');
    expect(restored.smtpSenderEmail.value, 'sender@example.com');
    expect(restored.smtpSenderName.value, 'LLMate Server');
    expect(restored.smtpSecurity.value, 'ssl');
  });

  test('多个收件邮箱可用中英文逗号分隔', () {
    const value = 'first@example.com, second@example.com，third@example.com';
    expect(MailService.isValidRecipientList(value), isTrue);
    expect(MailService.parseRecipients(value), [
      'first@example.com',
      'second@example.com',
      'third@example.com',
    ]);
    expect(
      MailService.isValidRecipientList('ok@example.com, invalid-address'),
      isFalse,
    );
  });
}
