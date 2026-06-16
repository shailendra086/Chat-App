import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, String> reactions; // userId -> emoji
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final bool isForwarded;
  final bool isPinned;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.reactions = const {},
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.isForwarded = false,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToSenderId': replyToSenderId,
      'isForwarded': isForwarded,
      'isPinned': isPinned,
    };
  }

  static MessageModel fromMap(Map<String, dynamic> map) {
    // Cast reactions safely
    Map<String, String> parsedReactions = {};
    if (map['reactions'] != null) {
      (map['reactions'] as Map<dynamic, dynamic>).forEach((key, value) {
        parsedReactions[key.toString()] = value.toString();
      });
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is Timestamp
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int))
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      reactions: parsedReactions,
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      replyToSenderId: map['replyToSenderId'],
      isForwarded: map['isForwarded'] ?? false,
      isPinned: map['isPinned'] ?? false,
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    Map<String, String>? reactions,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    bool? isForwarded,
    bool? isPinned,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      isForwarded: isForwarded ?? this.isForwarded,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
