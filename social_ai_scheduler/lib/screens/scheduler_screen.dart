import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'login_screen.dart' show kBackendBaseUrl;

/// Final screen: pick a date and time and send the post to the backend to be
/// scheduled. The post text is passed in via the route arguments.
class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({Key? key}) : super(key: key);

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  bool _scheduling = false;
  String? _message;
  bool _isError = false;

  String get _post {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is String ? args : '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  DateTime? get _scheduledDateTime {
    if (_date == null || _time == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
  }

  Future<void> _schedule() async {
    final when = _scheduledDateTime;
    if (when == null) {
      setState(() {
        _isError = true;
        _message = 'Pick both a date and a time first.';
      });
      return;
    }
    if (when.isBefore(DateTime.now())) {
      setState(() {
        _isError = true;
        _message = 'The scheduled time is in the past.';
      });
      return;
    }

    setState(() {
      _scheduling = true;
      _message = null;
      _isError = false;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/schedule'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post': _post,
          'scheduledAt': when.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isError = false;
          _message = 'Post scheduled for '
              '${DateFormat.yMMMEd().add_jm().format(when)}.';
        });
      } else {
        setState(() {
          _isError = true;
          _message = 'Scheduling failed (HTTP ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _message = 'Could not reach the scheduling server: $e';
      });
    } finally {
      if (mounted) setState(() => _scheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = _scheduledDateTime;
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Post preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _post.isEmpty ? '(No post content)' : _post,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _date == null
                    ? 'Pick a date'
                    : DateFormat.yMMMEd().format(_date!),
              ),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(
                _time == null ? 'Pick a time' : _time!.format(context),
              ),
              trailing: TextButton(
                onPressed: _pickTime,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 16),
            if (when != null)
              Text(
                'Scheduled for ${DateFormat.yMMMEd().add_jm().format(when)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _isError ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _scheduling ? null : _schedule,
              icon: _scheduling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.schedule_send),
              label: Text(_scheduling ? 'Scheduling...' : 'Schedule Post'),
            ),
          ],
        ),
      ),
    );
  }
}
