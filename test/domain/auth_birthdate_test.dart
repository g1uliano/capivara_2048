import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';

void main() {
  group('FakeAuthService birthDate', () {
    test('getBirthDate null por padrão', () async {
      final svc = FakeAuthService();
      expect(await svc.getBirthDate(), isNull);
    });

    test('saveBirthDate persiste e getBirthDate devolve', () async {
      final svc = FakeAuthService();
      await svc.saveBirthDate(DateTime(2008, 3, 15));
      expect(await svc.getBirthDate(), DateTime(2008, 3, 15));
    });

    test('initialBirthDate é respeitado', () async {
      final svc = FakeAuthService(initialBirthDate: DateTime(1990, 1, 1));
      expect(await svc.getBirthDate(), DateTime(1990, 1, 1));
    });
  });
}
