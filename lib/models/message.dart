class Message {
  final String role; // "user" | "assistant"
  final String content;

  Message(this.role, this.content);
  Message.user(String c) : this("user", c);
  Message.assistant(String c) : this("assistant", c);

  Map<String, dynamic> toJson() => {"role": role, "content": content};
  factory Message.fromJson(Map<String, dynamic> j) =>
      Message(j["role"] as String, j["content"] as String);
}
