class SeruPeer {
  const SeruPeer({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.unread = 0,
  });

  final int id;
  final String name;
  final String? username;
  final String? avatar;
  final int unread;

  factory SeruPeer.fromJson(Map<dynamic, dynamic> json) {
    return SeruPeer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'member',
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString(),
      unread: (json['unread'] as num?)?.toInt() ?? 0,
    );
  }

  String get handle => username == null || username!.isEmpty ? name : '@$username';
}

class ThreadCard {
  const ThreadCard({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String author;
  final String? createdAt;

  factory ThreadCard.fromJson(Map<dynamic, dynamic> json) {
    final author = json['author'];
    final name = author is Map ? author['name']?.toString() : null;
    return ThreadCard(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      author: name ?? 'member',
      createdAt: json['created_at']?.toString(),
    );
  }
}

class ZibaAssets {
  const ZibaAssets({
    required this.balance,
    this.payCode,
    this.locked = false,
  });

  final String balance;
  final String? payCode;
  final bool locked;
}
