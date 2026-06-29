import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../services/telegram_service.dart';
import '../services/world_cup_service.dart';
import '../services/world_cup_notification_service.dart';

class WorldCupScreen extends StatefulWidget {
  const WorldCupScreen({Key? key}) : super(key: key);

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notificationService = WorldCupNotificationService();

  final _botTokenCtrl = TextEditingController();
  final _chatIdCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  int _minutesBefore = 30;

  List<WorldCupMatch> _todayMatches = [];
  List<WorldCupMatch> _upcomingMatches = [];
  bool _loadingMatches = false;
  String? _matchError;
  bool _serviceRunning = false;
  bool _savingSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _botTokenCtrl.dispose();
    _chatIdCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _notificationService.loadSettings();
    setState(() {
      _botTokenCtrl.text = settings['botToken'] ?? '';
      _chatIdCtrl.text = settings['chatId'] ?? '';
      _apiKeyCtrl.text = settings['footballApiKey'] ?? '';
      _minutesBefore = int.tryParse(settings['minutesBefore'] ?? '30') ?? 30;
      _serviceRunning = _notificationService.isRunning;
    });
  }

  Future<void> _saveSettings() async {
    if (_botTokenCtrl.text.isEmpty || _chatIdCtrl.text.isEmpty || _apiKeyCtrl.text.isEmpty) {
      _showSnack('يرجى ملء جميع الحقول', isError: true);
      return;
    }
    setState(() => _savingSettings = true);
    try {
      await _notificationService.saveSettings(
        botToken: _botTokenCtrl.text.trim(),
        chatId: _chatIdCtrl.text.trim(),
        footballApiKey: _apiKeyCtrl.text.trim(),
        minutesBefore: _minutesBefore,
      );
      _showSnack('تم حفظ الإعدادات بنجاح ✅');
    } finally {
      setState(() => _savingSettings = false);
    }
  }

  Future<void> _testTelegram() async {
    if (_botTokenCtrl.text.isEmpty || _chatIdCtrl.text.isEmpty) {
      _showSnack('أدخل Bot Token و Chat ID أولاً', isError: true);
      return;
    }
    final telegram = TelegramService(
      botToken: _botTokenCtrl.text.trim(),
      chatId: _chatIdCtrl.text.trim(),
    );
    final ok = await telegram.testConnection();
    _showSnack(ok ? 'اتصال تيليجرام ✅ يعمل' : 'فشل الاتصال ❌ تحقق من الـ Token', isError: !ok);
  }

  Future<void> _testFootballApi() async {
    if (_apiKeyCtrl.text.isEmpty) {
      _showSnack('أدخل Football API Key أولاً', isError: true);
      return;
    }
    final service = WorldCupService(apiKey: _apiKeyCtrl.text.trim());
    final ok = await service.testApiKey();
    _showSnack(ok ? 'Football API ✅ يعمل' : 'فشل الاتصال ❌ تحقق من الـ API Key', isError: !ok);
  }

  Future<void> _toggleService() async {
    if (_notificationService.isRunning) {
      _notificationService.stop();
      setState(() => _serviceRunning = false);
      _showSnack('تم إيقاف الإشعارات');
    } else {
      try {
        await _notificationService.start();
        setState(() => _serviceRunning = true);
        _showSnack('تم تشغيل الإشعارات ✅');
      } catch (e) {
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _loadMatches() async {
    if (_apiKeyCtrl.text.isEmpty) {
      _showSnack('أدخل Football API Key في الإعدادات أولاً', isError: true);
      _tabController.animateTo(2);
      return;
    }
    setState(() {
      _loadingMatches = true;
      _matchError = null;
    });
    try {
      final service = WorldCupService(apiKey: _apiKeyCtrl.text.trim());
      final today = await service.getTodayMatches();
      final upcoming = await service.getUpcomingMatches(days: 7);
      setState(() {
        _todayMatches = today;
        _upcomingMatches = upcoming.where((m) => m.isScheduled).toList();
      });
    } catch (e) {
      setState(() => _matchError = e.toString());
    } finally {
      setState(() => _loadingMatches = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚽ إشعارات كأس العالم 2026'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'مباريات اليوم', icon: Icon(Icons.today)),
            Tab(text: 'القادمة', icon: Icon(Icons.calendar_month)),
            Tab(text: 'الإعدادات', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildUpcomingTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleService,
        backgroundColor: _serviceRunning ? Colors.red : Colors.green,
        icon: Icon(_serviceRunning ? Icons.notifications_off : Icons.notifications_active),
        label: Text(_serviceRunning ? 'إيقاف الإشعارات' : 'تشغيل الإشعارات'),
      ),
    );
  }

  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: _loadingMatches
          ? const Center(child: CircularProgressIndicator())
          : _matchError != null
              ? _buildError(_matchError!)
              : _todayMatches.isEmpty
                  ? _buildEmpty('لا توجد مباريات اليوم', Icons.sports_soccer)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _todayMatches.length,
                      itemBuilder: (ctx, i) => _buildMatchCard(_todayMatches[i]),
                    ),
    );
  }

  Widget _buildUpcomingTab() {
    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: _loadingMatches
          ? const Center(child: CircularProgressIndicator())
          : _matchError != null
              ? _buildError(_matchError!)
              : _upcomingMatches.isEmpty
                  ? _buildEmpty('لا توجد مباريات قادمة', Icons.event_busy)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _upcomingMatches.length,
                      itemBuilder: (ctx, i) => _buildMatchCard(_upcomingMatches[i]),
                    ),
    );
  }

  Widget _buildMatchCard(WorldCupMatch match) {
    final timeStr = DateFormat('hh:mm a', 'ar').format(match.matchTime);
    final dateStr = DateFormat('EEE d MMM', 'ar').format(match.matchTime);
    final isToday = _isSameDay(match.matchTime, DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: match.isLive
              ? LinearGradient(colors: [Colors.red.shade50, Colors.red.shade100])
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(match.stageLabel,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(match.statusLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(match.homeTeam,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: match.isLive ? Colors.red : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(match.scoreText,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Expanded(
                    child: Text(match.awayTeam,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  isToday ? '⏰ $timeStr' : '📅 $dateStr - $timeStr',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('🤖 إعدادات Telegram Bot'),
          const SizedBox(height: 8),
          _buildHintCard(
            'كيفية الحصول على Bot Token:',
            '1. افتح تيليجرام وابحث عن @BotFather\n'
            '2. أرسل /newbot واتبع التعليمات\n'
            '3. انسخ الـ Token وضعه هنا',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _botTokenCtrl,
            decoration: const InputDecoration(
              labelText: 'Bot Token',
              hintText: '123456:ABC-DEF...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.token),
            ),
          ),
          const SizedBox(height: 12),
          _buildHintCard(
            'كيفية الحصول على Chat ID:',
            '1. ابدأ محادثة مع الـ Bot\n'
            '2. أرسل أي رسالة\n'
            '3. افتح: api.telegram.org/bot{TOKEN}/getUpdates\n'
            '4. انسخ الـ chat.id من الـ JSON',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chatIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Chat ID',
              hintText: '-100123456789 أو 123456789',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.chat),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _testTelegram,
            icon: const Icon(Icons.send),
            label: const Text('اختبار الاتصال بتيليجرام'),
          ),
          const SizedBox(height: 24),
          _sectionTitle('⚽ إعدادات Football API'),
          const SizedBox(height: 8),
          _buildHintCard(
            'كيفية الحصول على Football API Key:',
            '1. اذهب إلى football-data.org\n'
            '2. سجل حساب مجاني\n'
            '3. انسخ الـ API Key من الداشبورد',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'Football API Key',
              hintText: 'أدخل API Key من football-data.org',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_soccer),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _testFootballApi,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('اختبار Football API'),
          ),
          const SizedBox(height: 24),
          _sectionTitle('⏰ توقيت الإشعارات'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('إشعار قبل المباراة بـ: '),
              Expanded(
                child: Slider(
                  value: _minutesBefore.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$_minutesBefore دقيقة',
                  onChanged: (v) => setState(() => _minutesBefore = v.toInt()),
                ),
              ),
              Text('$_minutesBefore د', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _savingSettings ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _savingSettings
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      );

  Widget _buildHintCard(String title, String body) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
          ],
        ),
      );

  Widget _buildError(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('حدث خطأ:', style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadMatches, child: const Text('إعادة المحاولة')),
          ],
        ),
      );

  Widget _buildEmpty(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ),
      );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
