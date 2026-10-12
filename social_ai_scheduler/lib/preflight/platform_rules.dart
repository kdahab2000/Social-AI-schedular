/// Social platforms supported by the scheduler.
enum SocialPlatform { facebook, instagram, twitter, linkedin, youtube, tiktok }

/// Posting limits used by the pre-flight checks.
///
/// `maxCaption` and `maxHashtags` are hard limits (exceeding them is an
/// error). `recommendedHashtags` is the soft range (outside it is a warning).
class PlatformRules {
  final int maxCaption;
  final int maxHashtags;
  final int minRecommendedHashtags;
  final int maxRecommendedHashtags;

  const PlatformRules({
    required this.maxCaption,
    required this.maxHashtags,
    required this.minRecommendedHashtags,
    required this.maxRecommendedHashtags,
  });

  static const Map<SocialPlatform, PlatformRules> _rules = {
    SocialPlatform.facebook: PlatformRules(
        maxCaption: 63206,
        maxHashtags: 30,
        minRecommendedHashtags: 1,
        maxRecommendedHashtags: 3),
    SocialPlatform.instagram: PlatformRules(
        maxCaption: 2200,
        maxHashtags: 30,
        minRecommendedHashtags: 3,
        maxRecommendedHashtags: 15),
    SocialPlatform.twitter: PlatformRules(
        maxCaption: 280,
        maxHashtags: 10,
        minRecommendedHashtags: 1,
        maxRecommendedHashtags: 2),
    SocialPlatform.linkedin: PlatformRules(
        maxCaption: 3000,
        maxHashtags: 30,
        minRecommendedHashtags: 3,
        maxRecommendedHashtags: 5),
    SocialPlatform.youtube: PlatformRules(
        maxCaption: 5000,
        maxHashtags: 15,
        minRecommendedHashtags: 3,
        maxRecommendedHashtags: 15),
    SocialPlatform.tiktok: PlatformRules(
        maxCaption: 2200,
        maxHashtags: 30,
        minRecommendedHashtags: 3,
        maxRecommendedHashtags: 8),
  };

  static PlatformRules of(SocialPlatform platform) => _rules[platform]!;
}
