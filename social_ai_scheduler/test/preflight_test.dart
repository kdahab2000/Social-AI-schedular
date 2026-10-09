import 'package:flutter_test/flutter_test.dart';
import 'package:social_ai_scheduler/preflight/post_preflight.dart';

bool has(List<PreflightIssue> issues, String code) =>
    issues.any((i) => i.code == code);

void main() {
  group('HashtagPreflight', () {
    test('flags duplicates case-insensitively', () {
      final i = HashtagPreflight.validate(
          ['#ICU', 'icu', '#health'], SocialPlatform.instagram);
      expect(has(i, 'hashtag.duplicate'), isTrue);
    });

    test('flags invalid characters and number-only tags', () {
      final i = HashtagPreflight.validate(
          ['#bad-tag', '#123', '#ok'], SocialPlatform.instagram);
      expect(has(i, 'hashtag.invalid_chars'), isTrue);
      expect(has(i, 'hashtag.numbers_only'), isTrue);
    });

    test('accepts Arabic and accented tags', () {
      final i = HashtagPreflight.validate(
          ['#الرعاية_المركزة', '#santé', '#icu'], SocialPlatform.instagram);
      expect(i.where((x) => x.severity == PreflightSeverity.error), isEmpty);
    });

    test('errors above hard max, warns above recommended', () {
      final many = List.generate(11, (n) => '#tag${String.fromCharCode(97 + n)}');
      expect(has(HashtagPreflight.validate(many, SocialPlatform.twitter),
          'hashtag.too_many'), isTrue);
      expect(
          has(HashtagPreflight.validate(
              ['#a1b', '#c2d', '#e3f'], SocialPlatform.twitter),
              'hashtag.above_recommended'),
          isTrue);
    });

    test('warns on blocked spam tags', () {
      expect(
          has(HashtagPreflight.validate(
              ['#f4f', '#a', '#b'], SocialPlatform.instagram),
              'hashtag.blocked'),
          isTrue);
    });

    test('clean normalizes, dedupes, drops bad and caps', () {
      final c = HashtagPreflight.clean(
          ['icu', '#ICU', '##health', '#bad tag', '#f4f', ''],
          SocialPlatform.twitter);
      expect(c, ['#icu', '#health']);
    });

    test('extract finds inline tags', () {
      expect(HashtagPreflight.extract('Hi #ICU and #صحة!'), ['#ICU', '#صحة']);
    });
  });

  group('CaptionPreflight', () {
    test('empty caption is an error', () {
      expect(has(CaptionPreflight.validate('  \n ', SocialPlatform.facebook),
          'caption.empty'), isTrue);
    });

    test('twitter limit counts URLs as 23 chars', () {
      final withUrl = 'a' * 250 + ' https://example.com/very/long/path/that/is/long';
      expect(CaptionPreflight.effectiveLength(withUrl, SocialPlatform.twitter),
          251 + 23);
      expect(has(CaptionPreflight.validate(withUrl, SocialPlatform.twitter),
          'caption.too_long'), isFalse);
      expect(has(CaptionPreflight.validate('a' * 281, SocialPlatform.twitter),
          'caption.too_long'), isTrue);
    });

    test('appended hashtags count toward the limit', () {
      final i = CaptionPreflight.validate('a' * 275, SocialPlatform.twitter,
          hashtags: ['#icu']);
      expect(has(i, 'caption.too_long'), isTrue);
    });

    test('warns on all caps and Instagram links', () {
      final i = CaptionPreflight.validate(
          'THIS IS A VERY LOUD CAPTION https://x.co', SocialPlatform.instagram);
      expect(has(i, 'caption.all_caps'), isTrue);
      expect(has(i, 'caption.link_not_clickable'), isTrue);
    });

    test('clean tidies whitespace', () {
      expect(CaptionPreflight.clean('  Hello   world \r\n\r\n\r\n\r\nBye  '),
          'Hello world\n\nBye');
    });
  });

  group('PostPreflight', () {
    test('valid post can be scheduled', () {
      final r = PostPreflight.run(
          caption: 'Great day in the ICU',
          hashtags: ['#icu', '#health', '#care'],
          platform: SocialPlatform.instagram);
      expect(r.canSchedule, isTrue);
      expect(r.cleanedHashtags, ['#icu', '#health', '#care']);
    });

    test('inline caption hashtags count toward limits and are not re-appended',
        () {
      final r = PostPreflight.run(
          caption: 'Shift done #ICU',
          hashtags: ['#icu', '#care', '#health'],
          platform: SocialPlatform.twitter);
      expect(r.cleanedHashtags, ['#care', '#health']);
      expect(has(r.issues, 'caption.hashtag_repeated'), isTrue);
    });

    test('errors block scheduling', () {
      final r = PostPreflight.run(
          caption: '', hashtags: ['#a b'], platform: SocialPlatform.facebook);
      expect(r.canSchedule, isFalse);
    });
  });
}
