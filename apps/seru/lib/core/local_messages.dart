import 'friend_gate.dart';

/// One local DM. The server stores only the envelope; the body lives here.
class LocalMessage {
  LocalMessage({
    required this.clientId,
    required this.peerId,
    required this.direction,
    required this.body,
    required this.createdAt,
    this.delivered = false,
  });

  final String clientId;
  final int peerId;
  final String direction; // sent | received
  final String body;
  final DateTime createdAt;
  bool delivered;
}

/// In-memory conversation store. The APK shell holds one instance for the session.
class LocalMessageStore {
  final Map<int, List<LocalMessage>> _byPeer = {};

  List<LocalMessage> conversation(int peerId) =>
      List.unmodifiable(_byPeer[peerId] ?? const []);

  void put(LocalMessage message) {
    final list = _byPeer.putIfAbsent(message.peerId, () => <LocalMessage>[]);
    final idx = list.indexWhere((m) => m.clientId == message.clientId);
    if (idx >= 0) {
      list[idx] = message;
    } else {
      list.add(message);
    }
  }

  /// Friend-gated send used by the chat composer and by unit tests.
  /// Persists the body locally; the caller posts the envelope to the server.
  LocalMessage sendToFriend({
    required String relationshipState,
    required int peerId,
    required String body,
    String? clientId,
  }) {
    if (!FriendGate.canSend(relationshipState)) {
      throw FriendGateException(FriendGate.rejectReason(relationshipState));
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw FriendGateException('Message is empty.');
    }
    final msg = LocalMessage(
      clientId: clientId ?? _newClientId(),
      peerId: peerId,
      direction: 'sent',
      body: trimmed,
      createdAt: DateTime.now(),
      delivered: false,
    );
    put(msg);
    return msg;
  }

  String? lastBody(int peerId) {
    final list = _byPeer[peerId];
    if (list == null || list.isEmpty) return null;
    return list.last.body;
  }

  static String _newClientId() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final hex = ms.toRadixString(16).padLeft(16, '0');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-'
        'a${hex.substring(1, 4)}-${hex.substring(4, 16)}';
  }
}
