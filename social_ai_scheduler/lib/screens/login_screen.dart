import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Backend base URL. The README documents the server running at
/// http://localhost:3000 during development.
const String kBackendBaseUrl = 'http://localhost:3000';

/// A single social platform the user can connect.
class SocialPlatform {
  const SocialPlatform(this.name, this.icon);

  final String name;
  final IconData icon;
}

/// First screen: lets the user "connect" their social accounts before
/// moving on to generate and schedule posts.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const List<SocialPlatform> _platforms = [
    SocialPlatform('Facebook', Icons.facebook),
    SocialPlatform('Instagram', Icons.camera_alt),
    SocialPlatform('Twitter', Icons.alternate_email),
    SocialPlatform('LinkedIn', Icons.business),
    SocialPlatform('YouTube', Icons.play_circle_fill),
    SocialPlatform('TikTok', Icons.music_note),
  ];

  final Set<String> _connected = <String>{};

  Future<void> _connect(SocialPlatform platform) async {
    // Kick off the backend OAuth flow for this platform. If the URL can't be
    // launched (e.g. no browser configured) we still mark it connected so the
    // demo flow can proceed, but we surface the failure to the user.
    final uri = Uri.parse(
      '$kBackendBaseUrl/auth/${platform.name.toLowerCase()}',
    );

    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launched = false;
    }

    if (!mounted) return;
    setState(() => _connected.add(platform.name));

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the ${platform.name} login page.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Accounts')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Connect the social accounts you want to post to, '
              'then continue to create a post.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _platforms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final platform = _platforms[index];
                final connected = _connected.contains(platform.name);
                return ListTile(
                  leading: Icon(platform.icon, color: Colors.deepPurple),
                  title: Text(platform.name),
                  trailing: connected
                      ? const Chip(
                          label: Text('Connected'),
                          avatar: Icon(Icons.check, size: 18),
                        )
                      : OutlinedButton(
                          onPressed: () => _connect(platform),
                          child: const Text('Connect'),
                        ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _connected.isEmpty
                      ? null
                      : () => Navigator.pushNamed(context, '/create-post'),
                  child: Text(
                    _connected.isEmpty
                        ? 'Connect an account to continue'
                        : 'Continue',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
