import { test, expect } from 'claude-code/testing'
import { priceFor, requestCost } from './prices'

test('longest prefix picks the right model price', () => {
  expect(priceFor('claude-opus-5-5')).toEqual({ input: 4, output: 20 })
  expect(priceFor('claude-opus-5')).toEqual({ input: 5, output: 25 })
  expect(priceFor('claude-sonnet-5-5')).toEqual({ input: 2, output: 10 })
  expect(priceFor('claude-haiku-5-5')).toEqual({ input: 0.1, output: 0.5 })
  expect(priceFor('gpt-x')).toBeNull()
})

test('request cost prices input, output and cache', () => {
  const p = { input: 4, output: 20 }
  expect(Math.round(requestCost(p, { input: 1e6, output: 1e6, cacheRead: 0, cacheWrite: 0 }) * 1e6)).toBe(24e6)
  expect(Math.round(requestCost(p, { input: 0, output: 0, cacheRead: 1e6, cacheWrite: 1e6 }) * 1e6)).toBe(5.4e6)
})
