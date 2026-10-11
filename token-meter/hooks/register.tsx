import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Tally } from '../types'
import { priceFor, requestCost } from './prices'

const empty: Tally = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, steps: 0, cost: 0, model: '' }
const tally = atom({ plugin: 'token-meter', key: 'tally' } as const, empty)

const n = (v: number) => v.toLocaleString('en-US')
const usd = (v: number) => '$' + v.toFixed(v !== 0 && v < 0.01 ? 5 : 4)

export const register: Register = (on, options) => {
  const inRate = Number(options.inputPerMillion ?? 3)
  const outRate = Number(options.outputPerMillion ?? 15)

  // Every model request (main thread and subagents) adds its reported usage.
  on('turn.step', async function* ($, e, next) {
    const result = yield* next(e)
    const u = result?.usage

    if (u) {
      const price = priceFor(u.model) ?? { input: inRate, output: outRate }
      const spent = requestCost(price, {
        input: u.input_tokens,
        output: u.output_tokens,
        cacheRead: u.cache_read_input_tokens,
        cacheWrite: u.cache_creation_input_tokens,
      })
      await update($, tally, t => ({
        input: t.input + u.input_tokens,
        output: t.output + u.output_tokens,
        cacheRead: t.cacheRead + u.cache_read_input_tokens,
        cacheWrite: t.cacheWrite + u.cache_creation_input_tokens,
        steps: t.steps + 1,
        cost: t.cost + spent,
        model: u.model,
      }))
    }

    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const t = await read($, tally)

    if (e.props.hasSurvey) {
      return next(e)
    }

    const usage = await $.session.usage()
    const billed = usage.cost?.usd
    const ctx = usage.context
    const context =
      ctx.percent === undefined
        ? ''
        : `Context: ${ctx.percent}% (${n(ctx.tokens ?? 0)} / ${n(ctx.window)}) · `

    const price = priceFor(t.model) ?? { input: inRate, output: outRate }

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box flexDirection="column">
        <Text dimColor>
          Tokens: {n(t.input + t.cacheRead + t.cacheWrite + t.output)} (in{' '}
          {n(t.input)} · cache {n(t.cacheRead)}r/{n(t.cacheWrite)}w · out{' '}
          {n(t.output)}) · {t.steps} requests
        </Text>
        <Text dimColor>
          {context}{t.model || 'model'} price/1M: in ${price.input} · out ${price.output} · used {usd(t.cost)}
          {billed === undefined ? '' : ` · session billed ${usd(billed)}`}
        </Text>
      </Box>
    )
  })
}
