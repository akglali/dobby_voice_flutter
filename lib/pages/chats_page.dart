import 'package:flutter/material.dart';
import '../services/chat_store.dart';
import '../models/conversation.dart';
import 'voice_chat_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<Conversation> _convos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _convos = ChatStore.I.list());

  void _newChat() {
    final c = ChatStore.I.create();
    _load();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoiceChatPage(conversationId: c.id)),
    ).then((_) => _load());
  }

  void _open(Conversation c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoiceChatPage(conversationId: c.id)),
    ).then((_) => _load());
  }

  Future<void> _delete(String id) async {
    await ChatStore.I.remove(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dobby Voice — Chats')),
      body: _convos.isEmpty
          ? const Center(child: Text('No chats yet. Tap + to start.'))
          : ListView.builder(
              itemCount: _convos.length,
              itemBuilder: (_, i) {
                final c = _convos[i];
                return Dismissible(
                  key: Key(c.id),
                  background: Container(color: Colors.redAccent),
                  onDismissed: (_) => _delete(c.id),
                  child: ListTile(
                    title: Text(c.title),
                    subtitle: Text(
                      '${c.messages.length} messages • ${c.updatedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _open(c),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newChat,
        child: const Icon(Icons.add),
      ),
    );
  }
}
