import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';

class WorldCupService {
  static const String _baseUrl = 'https://api.football-data.org/v4';
  // Competition code for FIFA World Cup 2026 on football-data.org
  static const String _competitionCode = 'WC';

  final String apiKey;

  WorldCupService({required this.apiKey});

  Map<String, String> get _headers => {'X-Auth-Token': apiKey};

  Future<List<WorldCupMatch>> getTodayMatches() async {
    final today = DateTime.now();
    return _fetchMatches(dateFrom: today, dateTo: today);
  }

  Future<List<WorldCupMatch>> getUpcomingMatches({int days = 7}) async {
    final from = DateTime.now();
    final to = from.add(Duration(days: days));
    return _fetchMatches(dateFrom: from, dateTo: to, status: 'SCHEDULED,TIMED');
  }

  Future<List<WorldCupMatch>> getLiveMatches() async {
    return _fetchMatches(status: 'IN_PLAY,PAUSED');
  }

  Future<List<WorldCupMatch>> _fetchMatches({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
  }) async {
    final params = <String, String>{};
    if (dateFrom != null) params['dateFrom'] = _formatDate(dateFrom);
    if (dateTo != null) params['dateTo'] = _formatDate(dateTo);
    if (status != null) params['status'] = status;

    final uri = Uri.parse('$_baseUrl/competitions/$_competitionCode/matches')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('فشل جلب المباريات: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final matches = (data['matches'] as List<dynamic>? ?? [])
        .map((m) => WorldCupMatch.fromJson(m as Map<String, dynamic>))
        .toList();

    matches.sort((a, b) => a.matchTime.compareTo(b.matchTime));
    return matches;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<bool> testApiKey() async {
    try {
      final uri = Uri.parse('$_baseUrl/competitions/$_competitionCode');
      final response = await http.get(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
