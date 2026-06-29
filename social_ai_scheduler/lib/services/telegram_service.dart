import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramService {
  final String botToken;
  final String chatId;

  TelegramService({required this.botToken, required this.chatId});

  String get _baseUrl => 'https://api.telegram.org/bot$botToken';

  Future<bool> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/getMe'));
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
