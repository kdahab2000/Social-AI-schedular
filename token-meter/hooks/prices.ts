// USD per 1M tokens, Anthropic API list prices (cached 2026-10-06).
// Cache reads bill at 0.1x input and 5-minute cache writes at 1.25x input
// (assumed multiples); the engine's own "session billed" figure is exact.
export type Price = { input: number; output: number }

const PRICES: Array<[prefix: string, price: Price]> = [
  ['claude-fable-5', { input: 10, output: 50 }],
  ['claude-mythos-5', { input: 10, output: 50 }],
  ['claude-opus-5-5', { input: 4, output: 20 }],
  ['claude-opus-5', { input: 5, output: 25 }],
  ['claude-opus-4', { input: 5, output: 25 }],
  ['claude-sonnet-5', { input: 2, output: 10 }],
  ['claude-sonnet-4', { input: 3, output: 15 }],
  ['claude-haiku-5', { input: 0.1, output: 0.5 }],
  ['claude-haiku-4', { input: 1, output: 5 }],
]

/** Longest matching prefix wins; null for a model not in the table. */
export function priceFor(model: string): Price | null {
  let best: [string, Price] | null = null
  for (const entry of PRICES) {
    if (model.startsWith(entry[0]) && (!best || entry[0].length > best[0].length)) {
      best = entry
    }
  }
  return best ? best[1] : null
}

export function requestCost(
  p: Price,
  u: { input: number; output: number; cacheRead: number; cacheWrite: number },
): number {
  return (
    ((u.input + u.cacheRead * 0.1 + u.cacheWrite * 1.25) * p.input +
      u.output * p.output) /
    1e6
  )
}
