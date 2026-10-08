import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/token_usage_tracker.dart';
import '../widgets/token_usage_bar.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  // Assumed backend contract: POST /generate {"prompt": "..."} ->
  // {"text": "...", "usage": {"input_tokens": n, "output_tokens": n}}.
  // Adjust to the real backend; token counts fall back to an estimate when
  // `usage` is missing.
  Future<void> _generate() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );
      final data = jsonDecode(res.body);
      final text = (data is Map ? data['text'] : null)?.toString() ?? '';
      final tracker = TokenUsageTracker.instance;
      if (!tracker.recordFromUsageJson(data is Map ? data['usage'] : null)) {
        tracker.record(
          inputTokens: TokenUsageTracker.estimateTokens(prompt),
          outputTokens: TokenUsageTracker.estimateTokens(text),
        );
      }
      if (text.isNotEmpty) _controller.text = text;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Generation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TokenUsageBar(),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe your post...',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _generate,
              child: Text(_loading ? 'Generating...' : 'Generate with AI'),
            ),
          ],
        ),
      ),
    );
  }
}
