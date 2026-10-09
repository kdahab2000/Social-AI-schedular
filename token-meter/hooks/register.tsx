import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Tally } from '../types'

const empty: Tally = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, steps: 0 }
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
      await update($, tally, t => ({
        input: t.input + u.input_tokens,
        output: t.output + u.output_tokens,
        cacheRead: t.cacheRead + u.cache_read_input_tokens,
        cacheWrite: t.cacheWrite + u.cache_creation_input_tokens,
        steps: t.steps + 1,
      }))
    }

    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const t = await read($, tally)

    if (e.props.hasSurvey || t.steps === 0) {
      return next(e)
    }

    // Price of the tokens used: cache reads bill at 0.1x input, writes at 1.25x.
    const cost =
      ((t.input + t.cacheRead * 0.1 + t.cacheWrite * 1.25) * inRate +
        t.output * outRate) /
      1e6
    const usage = await $.session.usage()
    const billed = usage.cost?.usd
    const ctx = usage.context
    const context =
      ctx.percent === undefined
        ? ''
        : `Context: ${ctx.percent}% (${n(ctx.tokens ?? 0)} / ${n(ctx.window)}) · `

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box flexDirection="column">
        <Text dimColor>
          Tokens: {n(t.input + t.cacheRead + t.cacheWrite + t.output)} (in{' '}
          {n(t.input)} · cache {n(t.cacheRead)}r/{n(t.cacheWrite)}w · out{' '}
          {n(t.output)}) · {t.steps} requests
        </Text>
        <Text dimColor>
          {context}API price/1M: in ${inRate} · out ${outRate} · used {usd(cost)}
          {billed === undefined ? '' : ` · session billed ${usd(billed)}`}
        </Text>
      </Box>
    )
  })
}
