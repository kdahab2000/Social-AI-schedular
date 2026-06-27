import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin client around the backend described in the README
/// (`http://localhost:3000`).
///
/// The screens were previously empty, so nothing ever called the backend —
/// which is why no posts (Facebook, X, or anything else) were ever sent.
/// This service centralises every network call so each screen just awaits a
/// future.
class ApiService {
  ApiService({http.Client? client, this.baseUrl = 'http://localhost:3000'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json',
      };

  /// Generate an AI-written post from a short prompt/topic.
  ///
  /// Returns the generated caption text. Falls back to throwing so the UI can
  /// surface the error rather than silently showing nothing.
  Future<String> generatePost(String prompt) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/generate'),
      headers: _jsonHeaders,
      body: jsonEncode({'prompt': prompt}),
    );

    if (res.statusCode != 200) {
      throw ApiException('Failed to generate post (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['text'] ?? body['content'] ?? '').toString();
  }

  /// Schedule a post to one or more platforms.
  ///
  /// [platformIds] are the [SocialPlatform.id] values, e.g.
  /// `['facebook', 'twitter']`. [scheduledAt] is sent as an ISO-8601 string;
  /// pass `null` to publish immediately.
  Future<void> schedulePost({
    required String content,
    required List<String> platformIds,
    DateTime? scheduledAt,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/schedule'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'content': content,
        'platforms': platformIds,
        'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException('Failed to schedule post (${res.statusCode})');
    }
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
