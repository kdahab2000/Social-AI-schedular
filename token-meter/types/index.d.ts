export type Tally = {
  input: number
  output: number
  cacheRead: number
  cacheWrite: number
  steps: number
}

declare module 'claude-code' {
  interface PluginState {
    'token-meter': { tally: Tally }
  }
}
