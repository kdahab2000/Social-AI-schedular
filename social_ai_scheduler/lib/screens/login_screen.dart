import 'package:flutter/material.dart';

/// Placeholder: real social-account login is not implemented yet.
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social AI Scheduler')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/create-post'),
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
