import 'package:flutter/material.dart';
import '../services/token_usage_tracker.dart';

/// Session token/price meter. Place it directly above any text box:
///
///     Column(children: [TokenUsageBar(), TextField(...)])
///
/// Tap it to edit the per-million prices.
class TokenUsageBar extends StatelessWidget {
  final TokenUsageTracker tracker;

  TokenUsageBar({Key? key, TokenUsageTracker? tracker})
      : tracker = tracker ?? TokenUsageTracker.instance,
        super(key: key);

  static String _n(int v) => v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  static String _usd(double v) =>
      '\$${v.toStringAsFixed(v != 0 && v.abs() < 0.01 ? 6 : 4)}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tracker,
      builder: (context, _) {
        final p = tracker.pricing;
        final style = Theme.of(context).textTheme.bodySmall;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _editPricing(context),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Session tokens: ${_n(tracker.totalTokens)}',
                          style: style?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Cost: ${_usd(tracker.totalCost)}',
                          style: style?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In ${_n(tracker.inputTokens)} (${_usd(tracker.inputCost)})'
                    '  ·  Out ${_n(tracker.outputTokens)} (${_usd(tracker.outputCost)})'
                    '  ·  ${tracker.requests} requests',
                    style: style,
                  ),
                  Text(
                    'API price per 1M tokens: in \$${p.inputPerMillion}'
                    '  ·  out \$${p.outputPerMillion}',
                    style: style,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editPricing(BuildContext context) async {
    final inCtrl =
        TextEditingController(text: tracker.pricing.inputPerMillion.toString());
    final outCtrl = TextEditingController(
        text: tracker.pricing.outputPerMillion.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API price per 1M tokens (USD)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: inCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Input'),
            ),
            TextField(
              controller: outCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Output'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    final i = double.tryParse(inCtrl.text);
    final o = double.tryParse(outCtrl.text);
    if (ok == true && i != null && o != null && i >= 0 && o >= 0) {
      tracker.pricing = TokenPricing(inputPerMillion: i, outputPerMillion: o);
    }
  }
}
