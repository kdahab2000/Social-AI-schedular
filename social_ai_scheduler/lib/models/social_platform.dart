import 'package:flutter/material.dart';

/// A social network the app can publish to.
///
/// The `id` is the value sent to the backend (see [ApiService]); the backend
/// uses it to route the post to the correct platform API.
class SocialPlatform {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const SocialPlatform({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  /// Every platform the README advertises. Facebook and X (Twitter) are
  /// included here so they show up in the connect/login and create-post
  /// screens and can actually receive updates.
  static const List<SocialPlatform> all = [
    SocialPlatform(
      id: 'facebook',
      name: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
    ),
    SocialPlatform(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: Icons.alternate_email,
      color: Color(0xFF000000),
    ),
    SocialPlatform(
      id: 'instagram',
      name: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE4405F),
    ),
    SocialPlatform(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: Icons.work,
      color: Color(0xFF0A66C2),
    ),
    SocialPlatform(
      id: 'youtube',
      name: 'YouTube',
      icon: Icons.play_circle_fill,
      color: Color(0xFFFF0000),
    ),
    SocialPlatform(
      id: 'tiktok',
      name: 'TikTok',
      icon: Icons.music_note,
      color: Color(0xFF010101),
    ),
  ];
}
