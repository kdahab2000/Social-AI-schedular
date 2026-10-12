# Social AI Scheduler

A Flutter app that allows users to:

- Connect social media accounts
- Generate AI-powered posts
- Schedule posts across platforms like Facebook, Instagram, Twitter, LinkedIn, YouTube, and TikTok.

## Setup

1. Run `flutter pub get`
2. Launch the app with `flutter run`
3. Make sure your backend server is running at `http://localhost:3000`

## Screens

- Login to social platforms
- AI post generation
- Post scheduling with date/time picker

## Pre-flight checks

`lib/preflight/` validates a caption and its hashtags before a post is scheduled:

```dart
final result = PostPreflight.run(
  caption: captionText,
  hashtags: ['#icu', '#health'],
  platform: SocialPlatform.instagram,
);
if (!result.canSchedule) { /* show result.errors */ }
// result.warnings are advisory; result.cleanedHashtags / cleanedCaption are suggested fixes.
```

- **Hashtags**: empty/invalid characters/number-only, duplicates, spam tags, per-platform hard max (error) and recommended range (warning). Arabic and accented letters are supported.
- **Caption**: empty, per-platform length (Twitter counts URLs as 23; appended hashtags count), all-caps, excess punctuation, hashtags repeated inline, non-clickable Instagram links.

Tests: `flutter test test/preflight_test.dart`
