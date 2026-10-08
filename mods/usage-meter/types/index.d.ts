export type Tokens = { input: number; output: number; cacheRead: number; cacheWrite: number }
export type Limit = { kind: string; percentUsed: number; resetsAt?: string }
export type Meter = { tokens: Tokens; usd: number | null; limits: Limit[] }

declare module 'claude-code' {
  interface PluginState {
    'usage-meter': { meter: Meter }
  }
}
