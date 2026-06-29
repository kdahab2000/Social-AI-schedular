import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import 'telegram_service.dart';
import 'world_cup_service.dart';

class WorldCupNotificationService {
  static const String _keyBotToken = 'telegram_bot_token';
  static const String _keyChatId = 'telegram_chat_id';
  static const String _keyFootballApiKey = 'football_api_key';
  static const String _keyNotificationsEnabled = 'wc_notifications_enabled';
  static const String _keyNotifyMinutesBefore = 'notify_minutes_before';

  Timer? _checkTimer;
  final Set<String> _sentNotifications = {};

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<Map<String, String?>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'botToken': prefs.getString(_keyBotToken),
      'chatId': prefs.getString(_keyChatId),
      'footballApiKey': prefs.getString(_keyFootballApiKey),
      'minutesBefore': prefs.getInt(_keyNotifyMinutesBefore)?.toString() ?? '30',
    };
  }

  Future<void> saveSettings({
    required String botToken,
    required String chatId,
    required String footballApiKey,
    int minutesBefore = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBotToken, botToken);
    await prefs.setString(_keyChatId, chatId);
    await prefs.setString(_keyFootballApiKey, footballApiKey);
    await prefs.setInt(_keyNotifyMinutesBefore, minutesBefore);
    await prefs.setBool(_keyNotificationsEnabled, true);
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  Future<void> start() async {
    if (_isRunning) return;
    final settings = await loadSettings();
    if (settings['botToken'] == null || settings['chatId'] == null || settings['footballApiKey'] == null) {
      throw Exception('يجب ضبط الإعدادات أولاً');
    }
    _isRunning = true;
    await _checkAndNotify();
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) => _checkAndNotify());
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isRunning = false;
  }

  Future<void> _checkAndNotify() async {
    try {
      final settings = await loadSettings();
      final botToken = settings['botToken']!;
      final chatId = settings['chatId']!;
      final footballApiKey = settings['footballApiKey']!;
      final minutesBefore = int.tryParse(settings['minutesBefore'] ?? '30') ?? 30;

      final telegram = TelegramService(botToken: botToken, chatId: chatId);
      final worldCup = WorldCupService(apiKey: footballApiKey);

      final matches = await worldCup.getTodayMatches();
      final now = DateTime.now();

      for (final match in matches) {
        _checkMatchNotifications(match, now, minutesBefore, telegram);
      }
    } catch (_) {
      // Silent fail - will retry in 5 minutes
    }
  }

  void _checkMatchNotifications(
    WorldCupMatch match,
    DateTime now,
    int minutesBefore,
    TelegramService telegram,
  ) {
    final minutesToStart = match.matchTime.difference(now).inMinutes;

    // Notify X minutes before kick-off
    if (match.isScheduled && minutesToStart <= minutesBefore && minutesToStart > minutesBefore - 5) {
      final key = 'before_${match.id}';
      if (!_sentNotifications.contains(key)) {
        _sentNotifications.add(key);
        _sendPreMatchNotification(match, minutesToStart, telegram);
      }
    }

    // Notify at kick-off
    if (match.isScheduled && minutesToStart <= 0 && minutesToStart > -5) {
      final key = 'kickoff_${match.id}';
      if (!_sentNotifications.contains(key)) {
        _sentNotifications.add(key);
        _sendKickoffNotification(match, telegram);
      }
    }

    // Notify when match goes live (catches delayed starts)
    if (match.isLive) {
      final key = 'live_${match.id}';
      if (!_sentNotifications.contains(key)) {
        _sentNotifications.add(key);
        _sendLiveNotification(match, telegram);
      }
    }

    // Notify at full time
    if (match.isFinished) {
      final key = 'finished_${match.id}';
      if (!_sentNotifications.contains(key)) {
        _sentNotifications.add(key);
        _sendFinalScoreNotification(match, telegram);
      }
    }
  }

  Future<void> _sendPreMatchNotification(
    WorldCupMatch match,
    int minutesLeft,
    TelegramService telegram,
  ) async {
    final message = '''
⚽ <b>كأس العالم 2026 - تنبيه مباراة</b>

🕐 المباراة ستبدأ خلال <b>$minutesLeft دقيقة</b>

🏴 ${match.homeTeam}
🆚
🏴 ${match.awayTeam}

📍 ${match.stageLabel}
🕒 ${_formatTime(match.matchTime)}
''';
    await telegram.sendMessage(message);
  }

  Future<void> _sendKickoffNotification(
    WorldCupMatch match,
    TelegramService telegram,
  ) async {
    final message = '''
🚀 <b>انطلقت المباراة!</b>

⚽ ${match.homeTeam} 🆚 ${match.awayTeam}

📍 ${match.stageLabel} - كأس العالم 2026
''';
    await telegram.sendMessage(message);
  }

  Future<void> _sendLiveNotification(
    WorldCupMatch match,
    TelegramService telegram,
  ) async {
    final message = '''
🔴 <b>مباراة مباشرة الآن!</b>

⚽ <b>${match.homeTeam} ${match.scoreText} ${match.awayTeam}</b>

📍 ${match.stageLabel} - كأس العالم 2026
''';
    await telegram.sendMessage(message);
  }

  Future<void> _sendFinalScoreNotification(
    WorldCupMatch match,
    TelegramService telegram,
  ) async {
    final message = '''
✅ <b>نهاية المباراة - كأس العالم 2026</b>

🏆 <b>${match.homeTeam} ${match.scoreText} ${match.awayTeam}</b>

📍 ${match.stageLabel}
''';
    await telegram.sendMessage(message);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
