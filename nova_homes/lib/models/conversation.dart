class Conversation {
  const Conversation({
    required this.id,
    required this.hostName,
    required this.propertyTitle,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
  });

  final String id;
  final String hostName;
  final String propertyTitle;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;

  Conversation copyWith({
    String? id,
    String? hostName,
    String? propertyTitle,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastTimestamp,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      hostName: hostName ?? this.hostName,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
