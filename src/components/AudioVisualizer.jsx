/**
 * AudioVisualizer — animated frequency-bar canvas.
 *
 * Props:
 *   isPlaying   bool    — drives animation
 *   songId      string  — triggers phase reset on track change
 *   color       string  — accent hex/rgb from current song
 *   mode        'bars' | 'wave' | 'mirror'   (default: 'bars')
 *   height      number  — canvas height in px (default: 64)
 *   className   string
 */
import { useRef, useEffect, useState } from 'react'
import { useVisualizer, BAR_COUNT } from '../hooks/useVisualizer'

const MODES = ['bars', 'wave', 'mirror']
const MODE_LABELS = { bars: '▌▌', wave: '∿', mirror: '⬡' }

function hexToRgb(hex) {
  const clean = hex.replace('#', '')
  const r = parseInt(clean.slice(0, 2), 16)
  const g = parseInt(clean.slice(2, 4), 16)
  const b = parseInt(clean.slice(4, 6), 16)
  return isNaN(r) ? '34,211,238' : `${r},${g},${b}`
}

export default function AudioVisualizer({
  isPlaying,
  songId,
  color     = '#22d3ee',
  height    = 64,
  className = '',
}) {
  const canvasRef          = useRef(null)
  const { barHeights }     = useVisualizer(isPlaying, songId)
  const [mode, setMode]    = useState('bars')
  const modeRef            = useRef('bars')

  /* Keep modeRef in sync so the draw loop always sees latest */
  useEffect(() => { modeRef.current = mode }, [mode])

  /* Draw loop — runs whenever barHeights array reference changes */
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx    = canvas.getContext('2d')
    const W      = canvas.width
    const H      = canvas.height
    const rgb    = hexToRgb(color.startsWith('#') ? color : '#22d3ee')

    ctx.clearRect(0, 0, W, H)

    if (modeRef.current === 'bars') {
      /* ── Vertical bars ── */
      const gap     = 2
      const barW    = (W - gap * (BAR_COUNT - 1)) / BAR_COUNT
      for (let i = 0; i < BAR_COUNT; i++) {
        const v    = barHeights[i]
        const barH = Math.max(3, v * H)
        const x    = i * (barW + gap)
        const y    = H - barH

        /* Gradient: accent at top, dimmer at bottom */
        const grad = ctx.createLinearGradient(0, y, 0, H)
        grad.addColorStop(0, `rgba(${rgb}, ${0.85 + v * 0.15})`)
        grad.addColorStop(1, `rgba(${rgb}, 0.18)`)

        ctx.fillStyle = grad
        ctx.beginPath()
        ctx.roundRect(x, y, barW, barH, [2, 2, 0, 0])
        ctx.fill()
      }

    } else if (modeRef.current === 'wave') {
      /* ── Smooth waveform ── */
      ctx.beginPath()
      ctx.moveTo(0, H / 2)
      for (let i = 0; i < BAR_COUNT; i++) {
        const x = (i / (BAR_COUNT - 1)) * W
        const y = H / 2 - barHeights[i] * (H / 2 - 4)
        if (i === 0) ctx.moveTo(x, y)
        else {
          const prevX = ((i - 1) / (BAR_COUNT - 1)) * W
          const prevY = H / 2 - barHeights[i - 1] * (H / 2 - 4)
          const cpX   = (prevX + x) / 2
          ctx.bezierCurveTo(cpX, prevY, cpX, y, x, y)
        }
      }
      /* Mirror bottom half */
      for (let i = BAR_COUNT - 1; i >= 0; i--) {
        const x = (i / (BAR_COUNT - 1)) * W
        const y = H / 2 + barHeights[i] * (H / 2 - 4)
        const nextX = ((i + 1) / (BAR_COUNT - 1)) * W
        const nextY = H / 2 + (i < BAR_COUNT - 1 ? barHeights[i + 1] : barHeights[i]) * (H / 2 - 4)
        if (i === BAR_COUNT - 1) ctx.lineTo(x, y)
        else {
          const cpX = (nextX + x) / 2
          ctx.bezierCurveTo(cpX, nextY, cpX, y, x, y)
        }
      }
      ctx.closePath()
      const wGrad = ctx.createLinearGradient(0, 0, 0, H)
      wGrad.addColorStop(0, `rgba(${rgb}, 0.70)`)
      wGrad.addColorStop(0.5, `rgba(${rgb}, 0.30)`)
      wGrad.addColorStop(1, `rgba(${rgb}, 0.70)`)
      ctx.fillStyle = wGrad
      ctx.fill()

      /* Stroke outline */
      ctx.beginPath()
      for (let i = 0; i < BAR_COUNT; i++) {
        const x = (i / (BAR_COUNT - 1)) * W
        const y = H / 2 - barHeights[i] * (H / 2 - 4)
        if (i === 0) ctx.moveTo(x, y)
        else {
          const prevX = ((i - 1) / (BAR_COUNT - 1)) * W
          const prevY = H / 2 - barHeights[i - 1] * (H / 2 - 4)
          const cpX   = (prevX + x) / 2
          ctx.bezierCurveTo(cpX, prevY, cpX, y, x, y)
        }
      }
      ctx.strokeStyle = `rgba(${rgb}, 0.90)`
      ctx.lineWidth   = 1.5
      ctx.stroke()

    } else if (modeRef.current === 'mirror') {
      /* ── Mirror bars (up + down) ── */
      const gap  = 2
      const barW = (W - gap * (BAR_COUNT - 1)) / BAR_COUNT
      for (let i = 0; i < BAR_COUNT; i++) {
        const v    = barHeights[i]
        const half = Math.max(2, v * (H / 2 - 2))
        const x    = i * (barW + gap)
        const grad = ctx.createLinearGradient(0, H / 2 - half, 0, H / 2 + half)
        grad.addColorStop(0,   `rgba(${rgb}, 0.20)`)
        grad.addColorStop(0.5, `rgba(${rgb}, ${0.75 + v * 0.25})`)
        grad.addColorStop(1,   `rgba(${rgb}, 0.20)`)
        ctx.fillStyle = grad
        ctx.beginPath()
        ctx.roundRect(x, H / 2 - half, barW, half * 2, 2)
        ctx.fill()
      }
    }
  }, [barHeights, color])

  const cycleMode = () => {
    setMode(m => MODES[(MODES.indexOf(m) + 1) % MODES.length])
  }

  return (
    <div
      className={className}
      style={{
        position: 'relative',
        borderRadius: 12,
        overflow: 'hidden',
        background: 'rgba(255,255,255,0.03)',
        border: '1px solid rgba(255,255,255,0.06)',
      }}
    >
      <canvas
        ref={canvasRef}
        width={260}
        height={height}
        style={{ display: 'block', width: '100%', height: height }}
      />

      {/* Mode toggle button — top-right corner */}
      <button
        onClick={cycleMode}
        title={`Switch visualizer mode (${mode})`}
        style={{
          position: 'absolute', top: 5, right: 6,
          background: 'rgba(0,0,0,0.45)',
          border: '1px solid rgba(255,255,255,0.12)',
          borderRadius: 6,
          color: `rgba(${hexToRgb(color.startsWith('#') ? color : '#22d3ee')}, 0.9)`,
          fontSize: 11,
          padding: '2px 6px',
          cursor: 'pointer',
          lineHeight: 1.4,
          letterSpacing: '0.04em',
          transition: 'background 0.18s',
          fontFamily: 'var(--font-body)',
        }}
        onMouseEnter={e => e.currentTarget.style.background = 'rgba(0,0,0,0.65)'}
        onMouseLeave={e => e.currentTarget.style.background = 'rgba(0,0,0,0.45)'}
      >
        {MODE_LABELS[mode]}
      </button>

      {/* "not playing" dim overlay */}
      {!isPlaying && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'rgba(8,12,20,0.38)',
          pointerEvents: 'none',
          borderRadius: 12,
          transition: 'opacity 0.4s',
        }} />
      )}
    </div>
  )
}
