// lib/models/message.dart

class Message {
  final String id;
  final String senderPhone;
  final String senderName;
  final String content;       // text content OR image filename
  final String messageType;   // 'text' | 'image'
  final DateTime timestamp;
  final String dateLabel;     // 'Today', 'Yesterday', 'DD Mon YYYY'

  const Message({
    required this.id,
    required this.senderPhone,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.timestamp,
    required this.dateLabel,
  });

  bool get isImage => messageType == 'image';

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id:           json['id']           as String,
      senderPhone:  json['sender_phone'] as String,
      senderName:   json['sender_name']  as String,
      content:      json['content']      as String,
      messageType:  json['message_type'] as String? ?? 'text',
      timestamp:    DateTime.parse(json['timestamp'] as String).toLocal(),
      dateLabel:    json['date_label']   as String? ?? '',
    );
  }

  Message copyWith({String? id, String? dateLabel}) => Message(
        id:          id          ?? this.id,
        senderPhone: senderPhone,
        senderName:  senderName,
        content:     content,
        messageType: messageType,
        timestamp:   timestamp,
        dateLabel:   dateLabel   ?? this.dateLabel,
      );
}
