import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/social_platform.dart';
import '../services/api_service.dart';

/// Pick a date/time and push the post to the backend, which fans it out to
/// each selected platform (Facebook, X, ...). This is the step that was
/// missing before — without it, nothing was ever sent, so no platform got
/// updates.
class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({Key? key}) : super(key: key);

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final ApiService _api = ApiService();
  DateTime? _scheduledAt;
  bool _submitting = false;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit(String content, List<String> platforms) async {
    setState(() => _submitting = true);
    try {
      await _api.schedulePost(
        content: content,
        platformIds: platforms,
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      final when = _scheduledAt == null
          ? 'now'
          : DateFormat.yMMMd().add_jm().format(_scheduledAt!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheduled for $when')),
      );
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>? ??
        const {};
    final content = (args['content'] ?? '') as String;
    final platforms =
        ((args['platforms'] ?? const []) as List).cast<String>();

    final names = platforms
        .map((id) => SocialPlatform.all
            .firstWhere((p) => p.id == id,
                orElse: () => SocialPlatform.all.first)
            .name)
        .join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(content.isEmpty ? '(no content)' : content),
            ),
          ),
          const SizedBox(height: 8),
          Text('Platforms: ${names.isEmpty ? '(none)' : names}'),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(_scheduledAt == null
                ? 'Publish immediately'
                : DateFormat.yMMMd().add_jm().format(_scheduledAt!)),
            trailing: TextButton(
              onPressed: _pickDateTime,
              child: const Text('Pick time'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : () => _submit(content, platforms),
        icon: _submitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
        label: Text(_submitting ? 'Sending...' : 'Confirm'),
      ),
    );
  }
}
