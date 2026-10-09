import 'platform_rules.dart';
import 'preflight_issue.dart';

/// Pre-flight checks and normalization for hashtags.
class HashtagPreflight {
  /// Hashtags that platforms suppress or that signal spam. Lower-case, no `#`.
  static const Set<String> blocked = {
    'followforfollow',
    'f4f',
    'like4like',
    'l4l',
    'followback',
    'likeforlike',
    'sfs',
    'spamfollow',
  };

  static const int maxTagLength = 100;

  // Letters, digits and underscore in any script (Arabic, French accents...).
  static final RegExp _valid = RegExp(r'^[\p{L}\p{N}_]+$', unicode: true);
  static final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _inText =
      RegExp(r'#[\p{L}\p{N}_]+', unicode: true);

  /// Extracts hashtags from free text, e.g. a caption.
  static List<String> extract(String text) =>
      _inText.allMatches(text).map((m) => m.group(0)!).toList();

  /// Returns the tag without a leading `#`, trimmed.
  static String strip(String tag) {
    var t = tag.trim();
    while (t.startsWith('#')) {
      t = t.substring(1);
    }
    return t;
  }

  /// Canonical form used for comparing/de-duplicating (lower-case, no `#`).
  static String key(String tag) => strip(tag).toLowerCase();

  /// Validates [hashtags] for [platform]. Returns issues only.
  static List<PreflightIssue> validate(
      List<String> hashtags, SocialPlatform platform) {
    final rules = PlatformRules.of(platform);
    final issues = <PreflightIssue>[];
    final seen = <String>{};
    var validCount = 0;

    for (final raw in hashtags) {
      final body = strip(raw);
      final k = body.toLowerCase();

      if (body.isEmpty) {
        issues.add(const PreflightIssue.error(
            'hashtag.empty', 'Empty hashtag found.'));
        continue;
      }
      if (!_valid.hasMatch(body)) {
        issues.add(PreflightIssue.error('hashtag.invalid_chars',
            '#$body contains spaces or special characters.'));
        continue;
      }
      if (!_hasLetter.hasMatch(body)) {
        issues.add(PreflightIssue.error('hashtag.numbers_only',
            '#$body has no letters; platforms ignore number-only hashtags.'));
        continue;
      }
      if (body.length > maxTagLength) {
        issues.add(PreflightIssue.error('hashtag.too_long',
            '#${body.substring(0, 20)}… exceeds $maxTagLength characters.'));
        continue;
      }
      if (!seen.add(k)) {
        issues.add(PreflightIssue.warning(
            'hashtag.duplicate', '#$body is duplicated.'));
        continue;
      }
      if (blocked.contains(k)) {
        issues.add(PreflightIssue.warning('hashtag.blocked',
            '#$body is flagged as spam and may reduce reach.'));
      }
      validCount++;
    }

    if (validCount > rules.maxHashtags) {
      issues.add(PreflightIssue.error('hashtag.too_many',
          '$validCount hashtags exceeds the ${rules.maxHashtags} allowed on ${platform.name}.'));
    } else if (validCount > rules.maxRecommendedHashtags) {
      issues.add(PreflightIssue.warning('hashtag.above_recommended',
          '$validCount hashtags; ${platform.name} performs best with at most ${rules.maxRecommendedHashtags}.'));
    } else if (validCount < rules.minRecommendedHashtags) {
      issues.add(PreflightIssue.warning('hashtag.below_recommended',
          'Only $validCount hashtag(s); ${platform.name} performs best with at least ${rules.minRecommendedHashtags}.'));
    }
    return issues;
  }

  /// Produces a clean list: `#`-prefixed, de-duplicated (case-insensitive,
  /// first spelling wins), invalid and blocked tags dropped, and capped at the
  /// platform hard maximum.
  static List<String> clean(List<String> hashtags, SocialPlatform platform) {
    final rules = PlatformRules.of(platform);
    final seen = <String>{};
    final out = <String>[];
    for (final raw in hashtags) {
      final body = strip(raw);
      final k = body.toLowerCase();
      if (body.isEmpty ||
          body.length > maxTagLength ||
          !_valid.hasMatch(body) ||
          !_hasLetter.hasMatch(body) ||
          blocked.contains(k) ||
          !seen.add(k)) {
        continue;
      }
      out.add('#$body');
      if (out.length == rules.maxHashtags) break;
    }
    return out;
  }
}
