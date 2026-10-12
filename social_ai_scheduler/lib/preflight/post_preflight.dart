import 'caption_preflight.dart';
import 'hashtag_preflight.dart';
import 'platform_rules.dart';
import 'preflight_issue.dart';

export 'caption_preflight.dart';
export 'hashtag_preflight.dart';
export 'platform_rules.dart';
export 'preflight_issue.dart';

/// Runs the caption and hashtag pre-flight checks for one post.
///
/// Hashtags written inline in the caption are counted together with the
/// separate [hashtags] list when checking hashtag limits.
class PostPreflight {
  static PreflightResult run({
    required String caption,
    List<String> hashtags = const [],
    required SocialPlatform platform,
  }) {
    final cleanedCaption = CaptionPreflight.clean(caption);

    final inline = HashtagPreflight.extract(cleanedCaption);
    final all = [...inline, ...hashtags];

    // Hashtags to append: drop those already inline in the caption.
    final inlineKeys = inline.map(HashtagPreflight.key).toSet();
    final cleanedHashtags = HashtagPreflight.clean(
        hashtags.where((t) => !inlineKeys.contains(HashtagPreflight.key(t))).toList(),
        platform);

    final issues = <PreflightIssue>[
      ...CaptionPreflight.validate(caption, platform, hashtags: hashtags),
      ...HashtagPreflight.validate(all, platform),
    ];

    return PreflightResult(
      issues: issues,
      cleanedHashtags: cleanedHashtags,
      cleanedCaption: cleanedCaption,
    );
  }
}
