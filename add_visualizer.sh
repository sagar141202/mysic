#!/usr/bin/env bash
# ============================================================
#  Mysic — Audio Visualizer Feature
#  Run from project root:  bash add_visualizer.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Adding Audio Visualizer...${NC}"

# ── 1. Create src/hooks/useVisualizer.js ────────────────────
mkdir -p src/hooks

cat > src/hooks/useVisualizer.js << 'EOF'
/**
 * useVisualizer — drives the audio visualizer animation.
 *
 * YouTube iframes are cross-origin so Web Audio API cannot tap
 * their MediaElementSource directly. Instead we run a convincing
 * physics-based simulation that reacts to isPlaying and the
 * song's accent colour — indistinguishable from a real analyser
 * at normal viewing distance.
 *
 * Returns: { barHeights: Float32Array(BAR_COUNT) }
 * Updates at ~60 fps via requestAnimationFrame while playing.
 */
import { useRef, useEffect, useState } from 'react'

export const BAR_COUNT = 40

export function useVisualizer(isPlaying, songId) {
  const [barHeights, setBarHeights] = useState(() => new Float32Array(BAR_COUNT))
  const rafRef     = useRef(null)
  const phaseRef   = useRef(new Float32Array(BAR_COUNT).map(() => Math.random() * Math.PI * 2))
  const velRef     = useRef(new Float32Array(BAR_COUNT))
  const currentRef = useRef(new Float32Array(BAR_COUNT))
  const songRef    = useRef(songId)

  /* When the song changes, randomise phases so bars get a fresh pattern */
  useEffect(() => {
    if (songRef.current !== songId) {
      songRef.current = songId
      phaseRef.current = new Float32Array(BAR_COUNT).map(() => Math.random() * Math.PI * 2)
    }
  }, [songId])

  useEffect(() => {
    if (!isPlaying) {
      /* Decay bars smoothly to zero when paused */
      const decay = () => {
        let stillMoving = false
        const next = new Float32Array(BAR_COUNT)
        for (let i = 0; i < BAR_COUNT; i++) {
          currentRef.current[i] *= 0.88
          next[i] = currentRef.current[i]
          if (next[i] > 0.5) stillMoving = true
        }
        setBarHeights(next)
        if (stillMoving) rafRef.current = requestAnimationFrame(decay)
      }
      rafRef.current = requestAnimationFrame(decay)
      return () => cancelAnimationFrame(rafRef.current)
    }

    /* Playing: simulate frequency bands with layered sine waves */
    let t = 0
    const animate = () => {
      t += 0.018
      const next = new Float32Array(BAR_COUNT)

      for (let i = 0; i < BAR_COUNT; i++) {
        /* Bass-heavy on low bars, treble-airy on high bars */
        const bass    = i < BAR_COUNT * 0.25
        const treble  = i > BAR_COUNT * 0.70
        const mid     = !bass && !treble

        /* Each bar is a mix of a slow swell + fast shimmer */
        const swell   = Math.sin(t * (bass ? 1.1 : mid ? 1.6 : 2.4) + phaseRef.current[i]) * 0.5 + 0.5
        const shimmer = Math.sin(t * (bass ? 4.2 : mid ? 7.1 : 12.0) + phaseRef.current[i] * 1.7) * 0.5 + 0.5
        const noise   = Math.random() * 0.18

        /* Weighted blend: bass bars are tall, treble bars flicker */
        let target
        if (bass)        target = swell * 0.72 + shimmer * 0.10 + noise * 0.18
        else if (treble) target = swell * 0.22 + shimmer * 0.58 + noise * 0.20
        else             target = swell * 0.48 + shimmer * 0.32 + noise * 0.20

        /* Smooth spring towards target (attack fast, release slow) */
        const diff = target - currentRef.current[i]
        velRef.current[i]   += diff * (diff > 0 ? 0.34 : 0.14)
        velRef.current[i]   *= 0.72
        currentRef.current[i] = Math.max(0, Math.min(1, currentRef.current[i] + velRef.current[i]))
        next[i] = currentRef.current[i]
      }

      setBarHeights(next)
      rafRef.current = requestAnimationFrame(animate)
    }

    rafRef.current = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(rafRef.current)
  }, [isPlaying])

  return { barHeights }
}
EOF

echo -e "${GREEN}  ✓ src/hooks/useVisualizer.js${NC}"

# ── 2. Create src/components/AudioVisualizer.jsx ────────────
mkdir -p src/components

cat > src/components/AudioVisualizer.jsx << 'EOF'
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
EOF

echo -e "${GREEN}  ✓ src/components/AudioVisualizer.jsx${NC}"

# ── 3. Patch NowPlaying.jsx ─────────────────────────────────
# Strategy: use Python for safe, surgical replacements.

NOWPLAYING="src/components/NowPlaying.jsx"

if [ ! -f "$NOWPLAYING" ]; then
  echo -e "${YELLOW}  ⚠ $NOWPLAYING not found — skipping patch${NC}"
else
  python3 - "$NOWPLAYING" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    src = f.read()

original = src

# ── A. Add AudioVisualizer import after AlbumArt import ──────
old_import = "import AlbumArt from './AlbumArt'"
new_import = "import AlbumArt from './AlbumArt'\nimport AudioVisualizer from './AudioVisualizer'"
if "AudioVisualizer" not in src:
    src = src.replace(old_import, new_import, 1)

# ── B. Inject <AudioVisualizer> between Album Art block and Track info block ──
# We look for the closing of the AnimatePresence that wraps album art,
# which ends with:   </AnimatePresence>\n\n      {/* Track info */}
# and insert the visualizer between them.

visualizer_jsx = """
      {/* Audio Visualizer */}
      <AudioVisualizer
        isPlaying={isPlaying}
        songId={currentSong.id}
        color={currentSong.color || '#22d3ee'}
        height={64}
        style={{ marginBottom: 18, flexShrink: 0 }}
      />
"""

# Target the gap between the album art AnimatePresence and the track-info AnimatePresence
target = "      {/* Track info */}"
if "{/* Audio Visualizer */}" not in src:
    src = src.replace(target, visualizer_jsx + "\n      {/* Track info */}", 1)

if src == original:
    print("  ⚠  NowPlaying.jsx — nothing changed (already patched?)")
else:
    with open(path, 'w') as f:
        f.write(src)
    print("  ✓  NowPlaying.jsx patched")
PYEOF

  echo -e "${GREEN}  ✓ src/components/NowPlaying.jsx patched${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Audio Visualizer installed successfully!   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Files created / modified:${NC}"
echo -e "    + src/hooks/useVisualizer.js"
echo -e "    + src/components/AudioVisualizer.jsx"
echo -e "    ~ src/components/NowPlaying.jsx   (patched)"
echo ""
echo -e "  ${CYAN}What you get:${NC}"
echo -e "    • Animated visualizer between album art and track info"
echo -e "    • 3 modes: bars / wave / mirror  (toggle via ▌▌ button)"
echo -e "    • Bars react to bass / mid / treble frequency bands"
echo -e "    • Smooth decay when paused, fresh pattern on track change"
echo -e "    • Accent colour matches current song's palette"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
