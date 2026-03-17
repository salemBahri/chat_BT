import 'dart:convert';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MessageModel.fromMap(
      Map<String, dynamic> map, {
        required bool isMe,
      }) =>
      MessageModel(
        id: map['id'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        content: map['content'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        isMe: isMe,
      );

  String toJson() => jsonEncode(toMap());

  factory MessageModel.fromJson(String source, {required bool isMe}) =>
      MessageModel.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
        isMe: isMe,
      );
}
