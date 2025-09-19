import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiClient {
  // set your deployed domain:
  static const String baseUrl = 'https://api.sentient-rewrite.xyz';

  static Future<String> sendChat(
    List<Message> history, {
    String? modelId,
  }) async {
    final url = Uri.parse('$baseUrl/chat');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': history.map((m) => m.toJson()).toList(),
        if (modelId != null) 'modelId': modelId,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['reply'] as String?) ?? '';
    }
    throw Exception('API ${res.statusCode}: ${res.body}');
  }
}
