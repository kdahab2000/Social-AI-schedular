import 'package:flutter/material.dart';
import '../models/social_platform.dart';

/// Entry screen: lets the user "connect" their social accounts before
/// creating posts. Facebook and X are listed first so they are clearly
/// available to receive updates.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Set<String> _connected = <String>{};

  void _toggle(String platformId) {
    setState(() {
      if (_connected.contains(platformId)) {
        _connected.remove(platformId);
      } else {
        _connected.add(platformId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Accounts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Connect the platforms you want to publish to:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...SocialPlatform.all.map((p) {
            final connected = _connected.contains(p.id);
            return Card(
              child: ListTile(
                leading: Icon(p.icon, color: p.color),
                title: Text(p.name),
                trailing: connected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.add_circle_outline),
                onTap: () => _toggle(p.id),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _connected.isEmpty
            ? null
            : () => Navigator.pushNamed(context, '/create-post'),
        backgroundColor: _connected.isEmpty ? Colors.grey : null,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Create Post'),
      ),
    );
  }
}
