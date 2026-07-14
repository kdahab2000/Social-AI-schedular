import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart' show kBackendBaseUrl;

/// Second screen: the user describes what they want, the backend AI generates
/// post copy, and the user can edit it before moving on to scheduling.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _postController = TextEditingController();

  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'Enter a topic or idea to generate a post.');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/generate'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (data['post'] ?? data['text'] ?? '').toString();
        setState(() {
          _postController.text = text;
          if (text.isEmpty) {
            _error = 'The server returned an empty post.';
          }
        });
      } else {
        setState(() {
          _error = 'Generation failed (HTTP ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not reach the AI server: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _continueToSchedule() {
    final post = _postController.text.trim();
    if (post.isEmpty) {
      setState(() => _error = 'Generate or write a post before scheduling.');
      return;
    }
    Navigator.pushNamed(context, '/schedule', arguments: post);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What should this post be about?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Launch announcement for our new feature',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_generating ? 'Generating...' : 'Generate with AI'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Post',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _postController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Your generated post appears here. Edit as needed.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _continueToSchedule,
              child: const Text('Next: Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
