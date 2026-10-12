import 'package:flutter/material.dart';
import '../preflight/post_preflight.dart';

/// Arguments passed to the scheduler screen once a post passes pre-flight.
class DraftPost {
  final String caption;
  final List<String> hashtags;
  final SocialPlatform platform;

  const DraftPost(this.caption, this.hashtags, this.platform);
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _caption = TextEditingController();
  final _hashtags = TextEditingController();
  SocialPlatform _platform = SocialPlatform.instagram;

  @override
  void dispose() {
    _caption.dispose();
    _hashtags.dispose();
    super.dispose();
  }

  /// Splits the hashtag field on whitespace and commas.
  List<String> get _hashtagList => _hashtags.text
      .split(RegExp(r'[\s,]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  PreflightResult get _result => PostPreflight.run(
        caption: _caption.text,
        hashtags: _hashtagList,
        platform: _platform,
      );

  void _applyFixes(PreflightResult r) {
    setState(() {
      _caption.text = r.cleanedCaption;
      _hashtags.text = r.cleanedHashtags.join(' ');
    });
  }

  void _schedule(PreflightResult r) {
    Navigator.pushNamed(
      context,
      '/schedule',
      arguments: DraftPost(r.cleanedCaption, r.cleanedHashtags, _platform),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final rules = PlatformRules.of(_platform);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<SocialPlatform>(
            value: _platform,
            decoration: const InputDecoration(labelText: 'Platform'),
            items: [
              for (final p in SocialPlatform.values)
                DropdownMenuItem(value: p, child: Text(p.name)),
            ],
            onChanged: (p) => setState(() => _platform = p ?? _platform),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Caption',
              border: const OutlineInputBorder(),
              helperText:
                  '${CaptionPreflight.effectiveLength(_caption.text, _platform)} / ${rules.maxCaption}',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hashtags,
            decoration: InputDecoration(
              labelText: 'Hashtags (space or comma separated)',
              border: const OutlineInputBorder(),
              helperText:
                  'Recommended ${rules.minRecommendedHashtags}-${rules.maxRecommendedHashtags}, max ${rules.maxHashtags}',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (result.issues.isEmpty)
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Pre-flight passed'),
            ),
          for (final issue in result.issues)
            ListTile(
              dense: true,
              leading: Icon(
                issue.severity == PreflightSeverity.error
                    ? Icons.error
                    : Icons.warning_amber,
                color: issue.severity == PreflightSeverity.error
                    ? Colors.red
                    : Colors.orange,
              ),
              title: Text(issue.message),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _applyFixes(result),
                child: const Text('Apply fixes'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: result.canSchedule ? () => _schedule(result) : null,
                  child: const Text('Schedule'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
