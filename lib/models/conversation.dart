import 'message.dart';

class Conversation {
  String id;
  String title; // first user message or "New chat"
  List<Message> messages;
  DateTime createdAt;
  DateTime updatedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "messages": messages.map((m) => m.toJson()).toList(),
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j["id"] as String,
    title: j["title"] as String,
    messages: ((j["messages"] as List?) ?? [])
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    createdAt: DateTime.parse(j["createdAt"] as String),
    updatedAt: DateTime.parse(j["updatedAt"] as String),
  );
}
