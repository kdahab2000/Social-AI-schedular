import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Meter } from '../types'

const empty: Meter = {
  tokens: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  usd: null,
  limits: [],
}
const meter = atom({ plugin: 'usage-meter', key: 'meter' } as const, empty)

const fmt = (n: number) =>
  n >= 1e6 ? `${(n / 1e6).toFixed(2)}M` : n >= 1e3 ? `${(n / 1e3).toFixed(1)}k` : `${n}`

const until = (iso: string | undefined, now: number) => {
  if (!iso) return ''
  const mins = Math.max(0, Math.round((Date.parse(iso) - now) / 60000))
  const d = Math.floor(mins / 1440)
  const h = Math.floor((mins % 1440) / 60)
  const m = mins % 60
  return d > 0 ? ` resets ${d}d${h}h` : h > 0 ? ` resets ${h}h${m}m` : ` resets ${m}m`
}

const PANE = 'usage-meter'
const name = (k: string) => (k === 'five_hour' ? '5h' : k === 'seven_day' ? 'week' : k)

const line = (m: Meter, now: number) => {
  const t = m.tokens
  const total = t.input + t.output + t.cacheRead + t.cacheWrite
  return (
    `tokens ${fmt(total)} (in ${fmt(t.input)} · out ${fmt(t.output)} · cache ${fmt(t.cacheRead + t.cacheWrite)})` +
    (m.usd !== null ? ` · $${m.usd.toFixed(2)}` : '') +
    m.limits
      .map(l => ` · ${name(l.kind)} ${Math.max(0, 100 - l.percentUsed).toFixed(0)}% left${until(l.resetsAt, now)}`)
      .join('')
  )
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const u = await $.session.usage()
    const m = await update($, meter, m => ({ ...m, usd: u.cost?.usd ?? null, limits: u.rateLimits }))
    $.ui.status(line(m, await $.clock.now()))
    await $.command.register({ name: 'usage-meter', description: 'Show token usage, cost and limits in a pane' })
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const u = e.usage
    if (u) {
      const m = await update($, meter, m => ({
        ...m,
        tokens: {
          input: m.tokens.input + u.input_tokens,
          output: m.tokens.output + u.output_tokens,
          cacheRead: m.tokens.cacheRead + u.cache_read_input_tokens,
          cacheWrite: m.tokens.cacheWrite + u.cache_creation_input_tokens,
        },
      }))
      $.ui.status(line(m, await $.clock.now()))
    }
    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    const m = await update($, meter, m => ({ ...m, usd: e.cost?.usd ?? m.usd, limits: e.rateLimits }))
    $.ui.status(line(m, await $.clock.now()))
    return next(e)
  })

  on('command.run', { command: 'usage-meter' }, async $ => {
    void $.ui.open({ id: PANE, title: 'Usage' })
    const m = await read($, meter)
    const now = await $.clock.now()
    const t = m.tokens
    const rows = [
      `Tokens   in ${fmt(t.input)} · out ${fmt(t.output)} · cache read ${fmt(t.cacheRead)} · cache write ${fmt(t.cacheWrite)}`,
      `Cost     ${m.usd !== null ? `$${m.usd.toFixed(2)}` : 'n/a'}`,
      ...(m.limits.length === 0
        ? ['Limits   no 5h / week data reported yet (needs a subscription plan and one finished turn)']
        : m.limits.map(l => `${name(l.kind).padEnd(8)} ${Math.max(0, 100 - l.percentUsed).toFixed(0)}% left (${l.percentUsed}% used)${until(l.resetsAt, now)}`)),
    ]
    return { text: rows.join('\n') }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const m = await read($, meter)
    const now = await $.clock.now()
    const { Box, Text } = $.ui.resolve(e)
    const t = m.tokens
    return (
      <Box flexDirection="column">
        <Text>Tokens in: {fmt(t.input)}</Text>
        <Text>Tokens out: {fmt(t.output)}</Text>
        <Text>Cache read / write: {fmt(t.cacheRead)} / {fmt(t.cacheWrite)}</Text>
        <Text>Cost: {m.usd !== null ? `$${m.usd.toFixed(2)}` : 'n/a'}</Text>
        {m.limits.length === 0 && <Text dimColor>No 5h / week limit data (needs a subscription plan).</Text>}
        {m.limits.map(l => (
          <Text>
            {name(l.kind)}: {Math.max(0, 100 - l.percentUsed).toFixed(0)}% left{until(l.resetsAt, now)}
          </Text>
        ))}
      </Box>
    )
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)
    const m = await read($, meter)
    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box>
        <Text dimColor>{line(m, await $.clock.now())}</Text>
      </Box>
    )
  })
}
