import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/invites/invite_service.dart';

void main() {
  group('FakeInviteService', () {
    test('generateInviteLink returns correct URL', () async {
      final svc = FakeInviteService();
      final link = await svc.generateInviteLink('user123');
      expect(link, 'https://bichim-prd.web.app/invite?ref=user123');
    });

    test('registerInvite links invitee to inviter', () async {
      final svc = FakeInviteService();
      await svc.registerInvite(
          inviterId: 'alice', inviteeId: 'bob', inviteeDisplayName: 'Bob');
      final result = await svc.completeInviteReward(
          inviteeId: 'bob', inviteeDisplayName: 'Bob');
      expect(result, isTrue);
    });

    test('second registerInvite for same inviteeId is no-op', () async {
      final svc = FakeInviteService();
      await svc.registerInvite(
          inviterId: 'alice', inviteeId: 'bob', inviteeDisplayName: 'Bob');
      await svc.registerInvite(
          inviterId: 'carol', inviteeId: 'bob', inviteeDisplayName: 'Bob');
      // bob still linked to alice — complete returns true
      final result = await svc.completeInviteReward(
          inviteeId: 'bob', inviteeDisplayName: 'Bob');
      expect(result, isTrue);
      expect(svc.lastCompleteResult, isTrue);
    });

    test('completeInviteReward returns false with no pending invite', () async {
      final svc = FakeInviteService();
      final result = await svc.completeInviteReward(
          inviteeId: 'nobody', inviteeDisplayName: 'Nobody');
      expect(result, isFalse);
    });
  });
}
