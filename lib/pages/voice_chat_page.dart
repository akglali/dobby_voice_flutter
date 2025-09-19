import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/chat_store.dart';
import '../services/api_client.dart';

class VoiceChatPage extends StatefulWidget {
  final String conversationId;
  const VoiceChatPage({super.key, required this.conversationId});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechAvailable = false;
  bool _listening = false;
  bool _sending = false;
  bool _conversation = false; // conversation mode on/off

  String _heard = '';
  Conversation? _convo;

  final _scroll = ScrollController();
  List<Message> get _msgs => _convo?.messages ?? [];

  @override
  void initState() {
    super.initState();
    _convo = ChatStore.I.get(widget.conversationId);
    _initSpeech();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
  }

  void _jumpToEnd() {
    if (!_scroll.hasClients) return;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (e) => debugPrint('speech error: $e'),
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    // Wait until speaking finishes before continuing the loop
    await _tts.awaitSpeakCompletion(true);
  }

  void _onSpeechStatus(String status) {
    // Plugin reports: listening / notListening / done
    if (status.toLowerCase().contains('notlistening') ||
        status.toLowerCase().contains('done')) {
      if (_listening) _finalizeCurrentUtterance();
    }
  }

  Future<void> _toggleConversation() async {
    if (!_conversation) {
      // start loop
      _conversation = true;
      setState(() {});
      await _startListening();
    } else {
      // stop loop
      _conversation = false;
      await _stopAllAudio();
      setState(() {
        _listening = false;
        _sending = false;
      });
    }
  }

  Future<void> _stopAllAudio() async {
    try {
      await _speech.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Speech not available')));
      }
      return;
    }
    if (_sending) return; // don't listen while sending

    await _tts.stop(); // ensure TTS is quiet before listening
    setState(() {
      _heard = '';
      _listening = true;
    });

    await _speech.listen(
      onResult: (r) {
        setState(() => _heard = r.recognizedWords);
        if (r.finalResult && _listening) _finalizeCurrentUtterance();
      },
      partialResults: true,
      // Give a generous window and pause tolerance for natural speech
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 2),
      listenMode: stt.ListenMode.confirmation,
      localeId: 'en_US',
    );
  }

  Future<void> _finalizeCurrentUtterance() async {
    // stop mic, capture text
    await _speech.stop();
    if (!_listening) return;
    setState(() => _listening = false);

    final text = _heard.trim();
    if (text.isEmpty || _convo == null) {
      // if in conversation mode and user said nothing (timeout), re-listen
      if (_conversation) await _startListening();
      return;
    }

    // Title from first user message
    if (_convo!.title == "New chat" && text.isNotEmpty) {
      _convo!.title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      setState(() {}); // refresh AppBar title
    }

    // Save user message
    _convo!.messages.add(Message.user(text));
    await ChatStore.I.save(_convo!);
    _jumpToEnd();

    // Send to API
    setState(() => _sending = true);
    try {
      final reply = await ApiClient.sendChat(_convo!.messages);

      // Save assistant reply
      _convo!.messages.add(Message.assistant(reply));
      await ChatStore.I.save(_convo!);
      _jumpToEnd();

      setState(() => _sending = false);

      // Speak, then if still in conversation mode, listen again
      await _tts.speak(reply);
      if (_conversation) {
        await _startListening();
      }
    } catch (e) {
      _convo!.messages.add(Message.assistant('Network error: $e'));
      await ChatStore.I.save(_convo!);
      _jumpToEnd();
      setState(() => _sending = false);
      if (_conversation) {
        await _startListening();
      }
    }
  }

  @override
  void dispose() {
    _stopAllAudio();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _convo?.title ?? 'Chat';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Full conversation
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) {
                    final m = _msgs[i];
                    final isUser = m.role == "user";
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.amber.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(m.content),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_listening) const Text('Listening…'),
            if (_sending) const Text('Thinking…'),
            const SizedBox(height: 8),

            // Single control: Start/Stop Conversation
            FilledButton.icon(
              onPressed: _toggleConversation,
              icon: Icon(_conversation ? Icons.stop : Icons.play_arrow),
              label: Text(
                _conversation ? 'Stop Conversation' : 'Start Conversation',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),

            // (Optional) one-shot talk button — keep if you still want manual mode:
            // const SizedBox(height: 8),
            // OutlinedButton.icon(
            //   onPressed: _listening ? _finalizeCurrentUtterance : _startListening,
            //   icon: Icon(_listening ? Icons.stop : Icons.mic),
            //   label: Text(_listening ? 'Stop' : 'Talk once'),
            //   style: OutlinedButton.styleFrom(
            //     minimumSize: const Size(double.infinity, 48),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
