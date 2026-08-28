import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/core/http/sensitive_masker.dart';

void main() {
  test('masks configured sensitive types with hash mode', () {
    final options = SensitiveMaskOptions(
      types: {SensitiveInfoType.email, SensitiveInfoType.bankCard},
      mode: SensitiveMaskMode.hash,
    );
    final result = SensitiveMasker.maskText(
      '邮箱 a@example.com，卡号 6222021234567890123',
      options,
    );
    expect(result, isNot(contains('a@example.com')));
    expect(result, isNot(contains('6222021234567890123')));
  });

  test('hash preserves deterministic equality', () {
    final hash = SensitiveMasker.maskText(
      'a@example.com',
      const SensitiveMaskOptions(
        types: {SensitiveInfoType.email},
        mode: SensitiveMaskMode.hash,
      ),
    );
    final secondHash = SensitiveMasker.maskText(
      'a@example.com a@example.com',
      const SensitiveMaskOptions(
        types: {SensitiveInfoType.email},
        mode: SensitiveMaskMode.hash,
      ),
    );
    expect(hash, startsWith('sha256:'));
    expect(secondHash.split(' ').first, equals(secondHash.split(' ').last));
  });
}
