import 'package:flutter/material.dart';
import 'services/chat_store.dart';
import 'pages/chats_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChatStore.I.init(); // Hive ready
  runApp(const DobbyVoiceApp());
}

class DobbyVoiceApp extends StatelessWidget {
  const DobbyVoiceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dobby Voice',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
      home: const ChatsPage(),
    );
  }
}
