import 'package:flutter/foundation.dart';

/// API price per one million tokens, in USD.
class TokenPricing {
  final double inputPerMillion;
  final double outputPerMillion;

  const TokenPricing({
    required this.inputPerMillion,
    required this.outputPerMillion,
  });

  /// Placeholder rates. Edit them from the meter (tap it) or set the real
  /// rates of the model your backend uses.
  static const TokenPricing defaults =
      TokenPricing(inputPerMillion: 3.0, outputPerMillion: 15.0);
}

/// Counts the tokens used in the current app session and prices them.
///
/// A single instance ([TokenUsageTracker.instance]) lives for the whole app
/// run, so the count starts at zero in every new session and accumulates
/// across all screens.
class TokenUsageTracker extends ChangeNotifier {
  TokenUsageTracker({TokenPricing pricing = TokenPricing.defaults})
      : _pricing = pricing;

  static final TokenUsageTracker instance = TokenUsageTracker();

  TokenPricing _pricing;
  int _inputTokens = 0;
  int _outputTokens = 0;
  int _requests = 0;

  TokenPricing get pricing => _pricing;
  int get inputTokens => _inputTokens;
  int get outputTokens => _outputTokens;
  int get totalTokens => _inputTokens + _outputTokens;
  int get requests => _requests;

  double get inputCost => _inputTokens / 1000000 * _pricing.inputPerMillion;
  double get outputCost => _outputTokens / 1000000 * _pricing.outputPerMillion;
  double get totalCost => inputCost + outputCost;

  set pricing(TokenPricing value) {
    _pricing = value;
    notifyListeners();
  }

  void record({required int inputTokens, required int outputTokens}) {
    _inputTokens += inputTokens;
    _outputTokens += outputTokens;
    _requests++;
    notifyListeners();
  }

  /// Records usage from an API response body's `usage` object.
  /// Understands Anthropic (`input_tokens`/`output_tokens`) and OpenAI
  /// (`prompt_tokens`/`completion_tokens`) field names. Returns false when
  /// the response carries no usage data.
  bool recordFromUsageJson(Object? usage) {
    if (usage is! Map) return false;
    final input = usage['input_tokens'] ?? usage['prompt_tokens'];
    final output = usage['output_tokens'] ?? usage['completion_tokens'];
    if (input is! num && output is! num) return false;
    record(
      inputTokens: input is num ? input.toInt() : 0,
      outputTokens: output is num ? output.toInt() : 0,
    );
    return true;
  }

  /// Rough fallback (~4 characters per token) for when the backend does not
  /// report usage.
  static int estimateTokens(String text) =>
      text.isEmpty ? 0 : (text.length / 4).ceil();

  void reset() {
    _inputTokens = 0;
    _outputTokens = 0;
    _requests = 0;
    notifyListeners();
  }
}
