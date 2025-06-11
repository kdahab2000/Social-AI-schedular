import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/scheduler_screen.dart';

void main() {
  runApp(SocialMediaApp());
}

class SocialMediaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Scheduler',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/create-post': (context) => CreatePostScreen(),
        '/schedule': (context) => SchedulerScreen(),
      },
    );
  }
}