/// Server-authoritative Seru friendship states the APK may see.
/// Chat send is allowed only when [state] is `friends`.
class FriendGate {
  static const friends = 'friends';

  static bool canSend(String state) => state == friends;

  static String rejectReason(String state) {
    switch (state) {
      case friends:
        return '';
      case 'outgoing_pending':
        return 'Waiting for them to accept your Seru request.';
      case 'incoming_pending':
        return 'They asked to connect — accept first.';
      case 'i_blocked':
        return 'You blocked this person.';
      case 'blocked_by_peer':
        return 'This person has blocked your Seru request.';
      default:
        return 'You can only message your Seru friends.';
    }
  }
}

class FriendGateException implements Exception {
  FriendGateException(this.message);
  final String message;

  @override
  String toString() => message;
}
