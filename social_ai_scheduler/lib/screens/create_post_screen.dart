import 'package:flutter/material.dart';
import '../models/social_platform.dart';
import '../services/api_service.dart';

/// Compose a post: write or AI-generate caption text, pick the target
/// platforms (Facebook, X, etc.), then move on to scheduling.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final Set<String> _selected = <String>{};
  bool _generating = false;

  @override
  void dispose() {
    _promptController.dispose();
    _contentController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _snack('Enter a topic to generate from.');
      return;
    }
    setState(() => _generating = true);
    try {
      final text = await _api.generatePost(prompt);
      _contentController.text = text;
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _continue() {
    if (_contentController.text.trim().isEmpty) {
      _snack('Write or generate some content first.');
      return;
    }
    if (_selected.isEmpty) {
      _snack('Select at least one platform.');
      return;
    }
    Navigator.pushNamed(
      context,
      '/schedule',
      arguments: {
        'content': _contentController.text.trim(),
        'platforms': _selected.toList(),
      },
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: 'Topic / prompt for AI',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_generating ? 'Generating...' : 'Generate with AI'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Post content',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Post to:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SocialPlatform.all.map((p) {
              final selected = _selected.contains(p.id);
              return FilterChip(
                avatar: Icon(p.icon, color: p.color, size: 18),
                label: Text(p.name),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _selected.add(p.id);
                  } else {
                    _selected.remove(p.id);
                  }
                }),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _continue,
        icon: const Icon(Icons.schedule),
        label: const Text('Schedule'),
      ),
    );
  }
}
