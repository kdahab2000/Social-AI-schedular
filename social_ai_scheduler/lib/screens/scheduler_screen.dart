import 'package:flutter/material.dart';
import 'create_post_screen.dart';

/// Placeholder scheduler: shows the post that passed pre-flight.
/// Date/time picking and backend submission are not implemented yet.
class SchedulerScreen extends StatelessWidget {
  const SchedulerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final draft = ModalRoute.of(context)?.settings.arguments as DraftPost?;
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: draft == null
            ? const Text('No post selected.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform: ${draft.platform.name}'),
                  const SizedBox(height: 8),
                  Text(draft.caption),
                  const SizedBox(height: 8),
                  Text(draft.hashtags.join(' ')),
                ],
              ),
      ),
    );
  }
}
