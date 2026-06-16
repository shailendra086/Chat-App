import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    this.lastMessageTime,
    this.unreadCounts = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime,
      'unreadCounts': unreadCounts,
    };
  }

  static ChatModel fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] is Timestamp
              ? (map['lastMessageTime'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'] as int))
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  String getPeerId(String myId) {
    return participants.firstWhere(
      (id) => id != myId,
      orElse: () => '',
    );
  }
}
