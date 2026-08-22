import 'package:flutter_test/flutter_test.dart';
import 'package:seru/core/friend_gate.dart';
import 'package:seru/core/local_messages.dart';

void main() {
  test('rejects DM send to a non-friend', () {
    final store = LocalMessageStore();
    expect(
      () => store.sendToFriend(
        relationshipState: 'none',
        peerId: 7,
        body: 'hello',
      ),
      throwsA(isA<FriendGateException>()),
    );
    expect(store.conversation(7), isEmpty);
    expect(FriendGate.canSend('outgoing_pending'), isFalse);
    expect(FriendGate.canSend('friends'), isTrue);
  });
}
