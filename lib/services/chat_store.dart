import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';

class ChatStore {
  static final ChatStore I = ChatStore._();
  ChatStore._();

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('conversations'); // stores plain Maps
  }

  List<Conversation> list() {
    final values = _box.values
        .map((v) => Conversation.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  Conversation create() {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final convo = Conversation(
      id: id,
      title: "New chat",
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
    _box.put(id, convo.toJson());
    return convo;
  }

  Conversation? get(String id) {
    final v = _box.get(id);
    if (v == null) return null;
    return Conversation.fromJson(Map<String, dynamic>.from(v));
  }

  Future<void> save(Conversation c) async {
    c.updatedAt = DateTime.now();
    await _box.put(c.id, c.toJson());
  }

  Future<void> remove(String id) => _box.delete(id);
}
