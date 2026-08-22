import 'package:flutter_test/flutter_test.dart';
import 'package:seru/core/local_messages.dart';

void main() {
  test('friend send persists the body locally', () {
    final store = LocalMessageStore();
    final msg = store.sendToFriend(
      relationshipState: 'friends',
      peerId: 9,
      body: 'secret stays on device',
      clientId: '11111111-2222-4333-a444-555555555555',
    );
    expect(msg.body, 'secret stays on device');
    expect(store.lastBody(9), 'secret stays on device');
    expect(store.conversation(9).single.body, 'secret stays on device');
  });
}
