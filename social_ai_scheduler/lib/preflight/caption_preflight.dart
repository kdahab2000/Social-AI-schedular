import 'hashtag_preflight.dart';
import 'platform_rules.dart';
import 'preflight_issue.dart';

/// Pre-flight checks for post captions.
class CaptionPreflight {
  static final RegExp _url = RegExp(r'https?://\S+', caseSensitive: false);
  static final RegExp _ws = RegExp(r'[ \t]+');
  static final RegExp _blankLines = RegExp(r'\n{3,}');

  /// Tidies whitespace without touching the wording.
  static String clean(String caption) => caption
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((l) => l.replaceAll(_ws, ' ').trim())
      .join('\n')
      .replaceAll(_blankLines, '\n\n')
      .trim();

  /// Length as the platform counts it. Twitter counts every URL as 23 chars.
  static int effectiveLength(String caption, SocialPlatform platform) {
    if (platform != SocialPlatform.twitter) return caption.runes.length;
    var text = caption;
    var urls = 0;
    text = text.replaceAllMapped(_url, (_) {
      urls++;
      return '';
    });
    return text.runes.length + urls * 23;
  }

  /// Validates [caption] for [platform]. [hashtags] are the separately
  /// supplied tags that will be appended; their length counts toward the limit.
  static List<PreflightIssue> validate(String caption, SocialPlatform platform,
      {List<String> hashtags = const []}) {
    final rules = PlatformRules.of(platform);
    final issues = <PreflightIssue>[];
    final text = clean(caption);

    if (text.isEmpty) {
      issues.add(const PreflightIssue.error(
          'caption.empty', 'Caption is empty.'));
      return issues;
    }

    // Appended hashtags are joined by spaces after a blank line.
    final tagsLen = hashtags.isEmpty
        ? 0
        : 2 + hashtags.map((t) => t.runes.length).fold(0, (a, b) => a + b) +
            (hashtags.length - 1);
    final total = effectiveLength(text, platform) + tagsLen;
    if (total > rules.maxCaption) {
      issues.add(PreflightIssue.error('caption.too_long',
          'Caption is $total characters; ${platform.name} allows ${rules.maxCaption}.'));
    } else if (total > rules.maxCaption * 0.9) {
      issues.add(PreflightIssue.warning('caption.near_limit',
          'Caption is $total of ${rules.maxCaption} characters.'));
    }

    final letters = text
        .replaceAll(_url, '')
        .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
    if (letters.length >= 20 &&
        letters == letters.toUpperCase() &&
        letters != letters.toLowerCase()) {
      issues.add(const PreflightIssue.warning(
          'caption.all_caps', 'Caption is entirely upper-case.'));
    }

    if (RegExp(r'[!?]{4,}').hasMatch(text)) {
      issues.add(const PreflightIssue.warning('caption.excess_punctuation',
          'Repeated "!" or "?" can look spammy.'));
    }

    final inline = HashtagPreflight.extract(text);
    if (inline.isNotEmpty && hashtags.isNotEmpty) {
      final extra = hashtags.map(HashtagPreflight.key).toSet();
      final dup = inline
          .map(HashtagPreflight.key)
          .where(extra.contains)
          .toSet();
      if (dup.isNotEmpty) {
        issues.add(PreflightIssue.warning('caption.hashtag_repeated',
            'Already in caption and hashtag list: ${dup.map((d) => '#$d').join(', ')}.'));
      }
    }

    if (platform == SocialPlatform.instagram && _url.hasMatch(text)) {
      issues.add(const PreflightIssue.warning('caption.link_not_clickable',
          'Links in Instagram captions are not clickable.'));
    }

    return issues;
  }
}
