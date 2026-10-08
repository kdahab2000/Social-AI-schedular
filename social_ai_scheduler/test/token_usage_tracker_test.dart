import 'package:flutter_test/flutter_test.dart';
import 'package:social_ai_scheduler/services/token_usage_tracker.dart';

void main() {
  test('accumulates tokens and prices per million', () {
    final t = TokenUsageTracker(
        pricing: const TokenPricing(inputPerMillion: 3, outputPerMillion: 15));
    t.record(inputTokens: 1000000, outputTokens: 500000);
    expect(t.totalTokens, 1500000);
    expect(t.inputCost, closeTo(3.0, 1e-9));
    expect(t.outputCost, closeTo(7.5, 1e-9));
    expect(t.totalCost, closeTo(10.5, 1e-9));
  });

  test('parses Anthropic and OpenAI usage shapes', () {
    final t = TokenUsageTracker();
    expect(t.recordFromUsageJson({'input_tokens': 10, 'output_tokens': 5}), true);
    expect(t.recordFromUsageJson({'prompt_tokens': 2, 'completion_tokens': 1}), true);
    expect(t.recordFromUsageJson(null), false);
    expect(t.inputTokens, 12);
    expect(t.outputTokens, 6);
    expect(t.requests, 2);
  });
}
