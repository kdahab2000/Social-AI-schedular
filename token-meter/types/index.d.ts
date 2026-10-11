export type Tally = {
  input: number
  output: number
  cacheRead: number
  cacheWrite: number
  steps: number
  /** USD, each request priced at its own model's rates */
  cost: number
  /** model id of the latest request */
  model: string
}

declare module 'claude-code' {
  interface PluginState {
    'token-meter': { tally: Tally }
  }
}
