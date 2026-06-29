import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/scheduler_screen.dart';

void main() {
  runApp(const SocialMediaApp());
}

class SocialMediaApp extends StatelessWidget {
  const SocialMediaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Scheduler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/schedule': (context) => const SchedulerScreen(),
      },
    );
  }
}
