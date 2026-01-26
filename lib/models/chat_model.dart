import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String? id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessageModel> messages;

  ChatModel({
    this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return ChatModel(
      id: id ?? json['id'],
      title: json['title'] ?? 'New Chat',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  ChatModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessageModel>? messages,
  }) {
    return ChatModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatAttachmentModel> attachments;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachments = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((a) => ChatAttachmentModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }
}

class ChatAttachmentModel {
  final String type;
  final String name;
  final String? content;

  ChatAttachmentModel({
    required this.type,
    required this.name,
    this.content,
  });

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentModel(
      type: json['type'] ?? 'file',
      name: json['name'] ?? '',
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      if (content != null) 'content': content,
    };
  }
}
