#!/usr/bin/env bash
# ============================================================
#  Mysic — Sleep Timer + Ambient / Cinema Mode
#  Run from project root:  bash add_sleep_and_ambient.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Adding Sleep Timer + Ambient Mode...${NC}"

if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run from project root${NC}"; exit 1
fi

mkdir -p src/hooks src/components

# ════════════════════════════════════════════════════════════
# 1.  src/hooks/useSleepTimer.js
#     Countdown timer that fades volume to 0 then pauses.
#     Persists remaining seconds to localStorage so refresh
#     doesn't lose the timer.
# ════════════════════════════════════════════════════════════
cat > src/hooks/useSleepTimer.js << 'EOF'
/**
 * useSleepTimer
 *
 * Returns:
 *   remaining   number | null   — seconds left, null = inactive
 *   start(mins) fn              — start timer for N minutes
 *   cancel()    fn              — cancel active timer
 *
 * When timer reaches 0:
 *   1. Fades volume from current → 0 over 20 seconds
 *   2. Calls togglePlay() to pause
 *   3. Restores volume to original level after 1 s
 */
import { useState, useEffect, useRef, useCallback } from 'react'
import { usePlayer } from './usePlayer.jsx'

const LS_KEY = 'mysic:sleeptimer'

export function useSleepTimer() {
  const { setVolume, volume, togglePlay, isPlaying } = usePlayer()
  const volRef      = useRef(volume)
  const isPlayingRef = useRef(isPlaying)
  useEffect(() => { volRef.current = volume },       [volume])
  useEffect(() => { isPlayingRef.current = isPlaying }, [isPlaying])

  /* Restore persisted timer across reloads */
  const [remaining, setRemaining] = useState(() => {
    try {
      const saved = localStorage.getItem(LS_KEY)
      if (!saved) return null
      const { endsAt } = JSON.parse(saved)
      const left = Math.round((endsAt - Date.now()) / 1000)
      return left > 0 ? left : null
    } catch { return null }
  })

  const fadingRef    = useRef(false)
  const tickRef      = useRef(null)

  const cancel = useCallback(() => {
    clearInterval(tickRef.current)
    setRemaining(null)
    fadingRef.current = false
    localStorage.removeItem(LS_KEY)
  }, [])

  const start = useCallback((mins) => {
    cancel()
    const secs  = mins * 60
    const endsAt = Date.now() + secs * 1000
    localStorage.setItem(LS_KEY, JSON.stringify({ endsAt }))
    setRemaining(secs)
  }, [cancel])

  /* Countdown tick every second */
  useEffect(() => {
    if (remaining === null) return
    if (remaining <= 0) {
      /* Already at 0 — start the fade */
      if (!fadingRef.current) {
        fadingRef.current = true
        const startVol  = volRef.current || 70
        const FADE_SECS = 20
        let elapsed     = 0
        const fade = setInterval(() => {
          elapsed++
          const newVol = Math.max(0, startVol * (1 - elapsed / FADE_SECS))
          setVolume(Math.round(newVol))
          if (elapsed >= FADE_SECS) {
            clearInterval(fade)
            if (isPlayingRef.current) togglePlay()
            /* restore volume after brief pause */
            setTimeout(() => setVolume(startVol), 1000)
            cancel()
          }
        }, 1000)
      }
      return
    }

    tickRef.current = setInterval(() => {
      setRemaining(r => {
        if (r === null) return null
        const next = r - 1
        /* Update localStorage with fresh endsAt */
        const endsAt = Date.now() + next * 1000
        localStorage.setItem(LS_KEY, JSON.stringify({ endsAt }))
        return next
      })
    }, 1000)

    return () => clearInterval(tickRef.current)
  }, [remaining])  // eslint-disable-line

  return { remaining, start, cancel }
}
EOF
echo -e "${GREEN}  ✓ src/hooks/useSleepTimer.js${NC}"

# ════════════════════════════════════════════════════════════
# 2.  src/components/SleepTimerMenu.jsx
#     Popover that appears when the moon button is clicked.
#     Options: 15 / 30 / 45 / 60 min + Cancel.
#     Shows live countdown when active.
# ════════════════════════════════════════════════════════════
cat > src/components/SleepTimerMenu.jsx << 'EOF'
/**
 * SleepTimerMenu — popover panel for the sleep timer.
 *
 * Props:
 *   remaining   number|null
 *   onStart     fn(mins)
 *   onCancel    fn()
 *   onClose     fn()
 */
import { useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

const EASE = [0.25, 0.46, 0.45, 0.94]
const OPTIONS = [15, 30, 45, 60]

function fmt(secs) {
  const m = Math.floor(secs / 60)
  const s = secs % 60
  return `${m}:${String(s).padStart(2, '0')}`
}

/* Circular countdown ring */
function Ring({ pct, size = 44, stroke = 3 }) {
  const r = (size - stroke) / 2
  const circ = 2 * Math.PI * r
  return (
    <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={size/2} cy={size/2} r={r}
        stroke="rgba(255,255,255,0.08)" strokeWidth={stroke} fill="none" />
      <circle cx={size/2} cy={size/2} r={r}
        stroke="var(--accent-primary)" strokeWidth={stroke} fill="none"
        strokeLinecap="round"
        strokeDasharray={circ}
        strokeDashoffset={circ * (1 - pct / 100)}
        style={{ transition: 'stroke-dashoffset 1s linear' }}
      />
    </svg>
  )
}

export default function SleepTimerMenu({ remaining, onStart, onCancel, onClose, initialMins }) {
  const ref = useRef(null)

  /* Close on outside click */
  useEffect(() => {
    const handler = e => {
      if (ref.current && !ref.current.contains(e.target)) onClose()
    }
    setTimeout(() => window.addEventListener('mousedown', handler), 0)
    return () => window.removeEventListener('mousedown', handler)
  }, [onClose])

  const pct = remaining !== null
    ? (remaining / (initialMins * 60)) * 100
    : 0

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 10, scale: 0.94 }}
      animate={{ opacity: 1, y: 0,  scale: 1    }}
      exit={{    opacity: 0, y: 6,  scale: 0.96 }}
      transition={{ duration: 0.20, ease: EASE }}
      style={{
        position: 'absolute',
        bottom: 'calc(100% + 12px)',
        right: 0,
        width: 220,
        background: 'rgba(8,12,20,0.96)',
        backdropFilter: 'blur(28px)',
        WebkitBackdropFilter: 'blur(28px)',
        border: '1px solid rgba(255,255,255,0.10)',
        borderRadius: 18,
        boxShadow: '0 20px 60px rgba(0,0,0,0.55), 0 0 0 1px rgba(34,211,238,0.07)',
        fontFamily: 'var(--font-body)',
        overflow: 'hidden',
        zIndex: 400,
      }}
    >
      {/* Header */}
      <div style={{
        padding: '14px 16px 10px',
        borderBottom: '1px solid rgba(255,255,255,0.06)',
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span style={{ fontSize: 16 }}>🌙</span>
        <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>
          Sleep Timer
        </span>
      </div>

      {/* Active timer display */}
      <AnimatePresence>
        {remaining !== null && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{    opacity: 0, height: 0 }}
            style={{
              overflow: 'hidden',
              borderBottom: '1px solid rgba(255,255,255,0.06)',
            }}
          >
            <div style={{
              padding: '16px',
              display: 'flex', alignItems: 'center', gap: 14,
            }}>
              {/* Circular ring countdown */}
              <div style={{ position: 'relative', flexShrink: 0 }}>
                <Ring pct={pct} size={52} stroke={3} />
                <div style={{
                  position: 'absolute', inset: 0,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <span style={{ fontSize: 9, fontWeight: 700, color: 'var(--accent-primary)', fontVariantNumeric: 'tabular-nums' }}>
                    {fmt(remaining)}
                  </span>
                </div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: 12, color: 'var(--text-primary)', margin: '0 0 2px', fontWeight: 500 }}>
                  Pausing in
                </p>
                <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: 0 }}>
                  + 20s fade out
                </p>
              </div>
              <motion.button
                onClick={onCancel}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                style={{
                  background: 'rgba(255,80,80,0.12)',
                  border: '1px solid rgba(255,80,80,0.25)',
                  borderRadius: 8, padding: '4px 10px',
                  color: '#ff6b6b', fontSize: 11,
                  cursor: 'pointer', flexShrink: 0,
                  fontFamily: 'var(--font-body)',
                }}
              >
                Cancel
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Time options */}
      <div style={{ padding: '10px 10px 12px' }}>
        <p style={{
          fontSize: 10, fontWeight: 600, letterSpacing: '0.10em',
          color: 'var(--text-muted)', textTransform: 'uppercase',
          margin: '0 6px 8px',
        }}>
          {remaining !== null ? 'Change timer' : 'Set timer'}
        </p>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
          {OPTIONS.map(mins => (
            <motion.button
              key={mins}
              onClick={() => { onStart(mins); onClose() }}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.94 }}
              style={{
                background: remaining !== null && Math.round(remaining / 60) === mins
                  ? 'rgba(34,211,238,0.12)'
                  : 'rgba(255,255,255,0.04)',
                border: remaining !== null && Math.round(remaining / 60) === mins
                  ? '1px solid rgba(34,211,238,0.30)'
                  : '1px solid rgba(255,255,255,0.07)',
                borderRadius: 10,
                padding: '10px 0',
                color: remaining !== null && Math.round(remaining / 60) === mins
                  ? 'var(--accent-primary)'
                  : 'var(--text-secondary)',
                fontSize: 13, fontWeight: 500,
                cursor: 'pointer',
                fontFamily: 'var(--font-body)',
                transition: 'all 0.15s',
              }}
            >
              {mins} min
            </motion.button>
          ))}
        </div>
      </div>
    </motion.div>
  )
}
EOF
echo -e "${GREEN}  ✓ src/components/SleepTimerMenu.jsx${NC}"

# ════════════════════════════════════════════════════════════
# 3.  src/components/AmbientMode.jsx
#     Full-screen cinema overlay.
#     - Blurred album art fills entire viewport (blur: 80px)
#     - Dark gradient overlay for readability
#     - Floating controls: scrubber, play/prev/next, like, volume
#     - Track title + artist with glow
#     - Animated particles drifting upward (canvas)
#     - Press Escape or click the collapse button to exit
# ════════════════════════════════════════════════════════════
cat > src/components/AmbientMode.jsx << 'EOF'
/**
 * AmbientMode — full-screen cinema / screensaver overlay.
 *
 * Props:
 *   onClose  fn  — called when user exits
 */
import { useEffect, useRef, useCallback }         from 'react'
import { motion, AnimatePresence }         from 'framer-motion'
import { usePlayer }                       from '../hooks/usePlayer.jsx'
import { formatTime }                      from '../data/songs'
import AlbumArt                            from './AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]

/* ── Floating particle canvas ── */
function Particles({ color }) {
  const canvasRef = useRef(null)
  const rafRef    = useRef(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    canvas.width  = window.innerWidth
    canvas.height = window.innerHeight

    const rgb = color.startsWith('#')
      ? [
          parseInt(color.slice(1,3),16),
          parseInt(color.slice(3,5),16),
          parseInt(color.slice(5,7),16),
        ]
      : [34, 211, 238]

    /* Create particles */
    const COUNT = 38
    const particles = Array.from({ length: COUNT }, () => ({
      x:    Math.random() * canvas.width,
      y:    Math.random() * canvas.height,
      r:    Math.random() * 2.5 + 0.5,
      vy:   -(Math.random() * 0.4 + 0.1),
      vx:   (Math.random() - 0.5) * 0.18,
      life: Math.random(),       /* 0–1, wraps */
      speed: Math.random() * 0.004 + 0.002,
    }))

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      for (const p of particles) {
        p.life = (p.life + p.speed) % 1
        p.x += p.vx
        p.y += p.vy
        /* wrap vertically */
        if (p.y < -10) { p.y = canvas.height + 10; p.x = Math.random() * canvas.width }

        /* opacity bell curve: fade in, hold, fade out */
        const alpha = p.life < 0.2
          ? p.life / 0.2 * 0.55
          : p.life > 0.75
          ? (1 - p.life) / 0.25 * 0.55
          : 0.55

        ctx.beginPath()
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2)
        ctx.fillStyle = `rgba(${rgb.join(',')}, ${alpha})`
        ctx.fill()
      }
      rafRef.current = requestAnimationFrame(draw)
    }
    rafRef.current = requestAnimationFrame(draw)

    const onResize = () => {
      canvas.width  = window.innerWidth
      canvas.height = window.innerHeight
    }
    window.addEventListener('resize', onResize)
    return () => {
      cancelAnimationFrame(rafRef.current)
      window.removeEventListener('resize', onResize)
    }
  }, [color])

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: 'absolute', inset: 0,
        pointerEvents: 'none', zIndex: 1,
        opacity: 0.7,
      }}
    />
  )
}

/* ── Thin scrubber bar ── */
function AmbientScrubber({ pct, onSeek }) {
  const dragging = useRef(false)
  const calc = (clientX, el) => {
    const rect = el.getBoundingClientRect()
    return Math.max(0, Math.min(100, ((clientX - rect.left) / rect.width) * 100))
  }
  const onMouseDown = e => {
    e.preventDefault(); dragging.current = true
    onSeek(calc(e.clientX, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev.clientX, el)) }
    const onUp = () => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }
  return (
    <div onMouseDown={onMouseDown}
      style={{ width: '100%', height: 28, display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
      <div style={{ width: '100%', height: 4, borderRadius: 4, background: 'rgba(255,255,255,0.15)', position: 'relative' }}>
        <div style={{ width: `${pct}%`, height: '100%', borderRadius: 4, background: 'var(--accent-grad)', position: 'relative', transition: 'width 0.9s linear' }}>
          <div style={{
            position: 'absolute', right: -7, top: '50%', transform: 'translateY(-50%)',
            width: 16, height: 16, borderRadius: '50%', background: 'white',
            boxShadow: '0 0 12px rgba(34,211,238,0.9), 0 0 0 3px rgba(34,211,238,0.3)',
          }} />
        </div>
      </div>
    </div>
  )
}

/* ── Ambient control button ── */
function ABtn({ children, onClick, primary = false, title, size = 52 }) {
  return (
    <motion.button
      title={title} onClick={onClick}
      whileHover={{ scale: primary ? 1.08 : 1.14 }}
      whileTap={{ scale: primary ? 0.92 : 0.86 }}
      style={{
        width: size, height: size, borderRadius: '50%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: primary
          ? 'var(--accent-grad)'
          : 'rgba(255,255,255,0.10)',
        backdropFilter: 'blur(12px)',
        border: primary ? 'none' : '1px solid rgba(255,255,255,0.18)',
        color: primary ? '#08121f' : 'white',
        fontSize: primary ? 22 : 16,
        cursor: 'pointer',
        boxShadow: primary ? '0 8px 32px rgba(34,211,238,0.45)' : 'none',
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      {children}
    </motion.button>
  )
}

export default function AmbientMode({ onClose }) {
  const {
    currentSong, isPlaying, progress, volume,
    togglePlay, playNext, playPrev, seek, setVolume,
    toggleLike, liked,
  } = usePlayer()

  const isLiked  = liked.has(currentSong.id)
  const currSec  = Math.floor((progress / 100) * currentSong.duration)
  const accent   = currentSong.color || '#22d3ee'

  /* Escape key exits */
  useEffect(() => {
    const handler = e => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  /* Thumbnail URL for background */
  const thumb = currentSong.thumbnail ||
    (currentSong.youtubeId
      ? `https://i.ytimg.com/vi/${currentSong.youtubeId}/maxresdefault.jpg`
      : null)

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{    opacity: 0 }}
      transition={{ duration: 0.55, ease: EASE }}
      style={{
        position: 'fixed', inset: 0, zIndex: 500,
        overflow: 'hidden',
        fontFamily: 'var(--font-body)',
      }}
    >
      {/* ── Blurred album art background ── */}
      <AnimatePresence mode="wait">
        <motion.div
          key={currentSong.id}
          initial={{ opacity: 0, scale: 1.06 }}
          animate={{ opacity: 1, scale: 1    }}
          exit={{    opacity: 0, scale: 1.04 }}
          transition={{ duration: 0.8, ease: EASE }}
          style={{
            position: 'absolute', inset: '-60px',   /* overscan to hide blur edges */
            backgroundImage: thumb ? `url(${thumb})` : 'none',
            backgroundColor: accent + '33',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            filter: 'blur(72px) saturate(1.4) brightness(0.55)',
            zIndex: 0,
          }}
        />
      </AnimatePresence>

      {/* Dark overlay gradient — heavier at bottom for text readability */}
      <div style={{
        position: 'absolute', inset: 0, zIndex: 1,
        background: [
          'linear-gradient(to bottom,',
          '  rgba(4,6,14,0.55) 0%,',
          '  rgba(4,6,14,0.20) 35%,',
          '  rgba(4,6,14,0.20) 55%,',
          '  rgba(4,6,14,0.80) 82%,',
          '  rgba(4,6,14,0.97) 100%)',
        ].join(''),
      }} />

      {/* Floating particles */}
      <Particles color={accent} />

      {/* ── Top bar: logo + close ── */}
      <motion.div
        initial={{ opacity: 0, y: -16 }}
        animate={{ opacity: 1, y: 0   }}
        transition={{ duration: 0.4, delay: 0.15, ease: EASE }}
        style={{
          position: 'absolute', top: 0, left: 0, right: 0,
          padding: '22px 28px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          zIndex: 10,
        }}
      >
        {/* Mysic wordmark */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{
            width: 30, height: 30, borderRadius: 9,
            background: 'var(--accent-grad)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 14, boxShadow: '0 4px 16px rgba(34,211,238,0.30)',
          }}>♫</div>
          <span style={{
            fontFamily: 'var(--font-display)', fontSize: 18, fontWeight: 800,
            background: 'var(--accent-grad)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
          }}>mysic</span>
        </div>

        {/* Ambient badge + exit */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{
            fontSize: 11, padding: '4px 12px', borderRadius: 20,
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.14)',
            color: 'rgba(255,255,255,0.55)',
            letterSpacing: '0.10em',
          }}>
            AMBIENT MODE
          </span>
          <motion.button
            onClick={onClose}
            whileHover={{ scale: 1.12, rotate: 90 }}
            whileTap={{ scale: 0.88 }}
            title="Exit ambient mode (Esc)"
            style={{
              width: 36, height: 36, borderRadius: 10,
              background: 'rgba(255,255,255,0.08)',
              border: '1px solid rgba(255,255,255,0.14)',
              color: 'rgba(255,255,255,0.70)',
              fontSize: 14, cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >✕</motion.button>
        </div>
      </motion.div>

      {/* ── Centre: album art ── */}
      <div style={{
        position: 'absolute', inset: 0, zIndex: 5,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        paddingBottom: 240,   /* leave room for controls at bottom */
      }}>
        <AnimatePresence mode="wait">
          <motion.div
            key={currentSong.id}
            initial={{ opacity: 0, scale: 0.82, y: 20 }}
            animate={{ opacity: 1, scale: 1,    y: 0  }}
            exit={{    opacity: 0, scale: 0.88, y: -10 }}
            transition={{ duration: 0.45, ease: EASE }}
            style={{
              width: 'min(280px, 46vw)',
              aspectRatio: '1',
              borderRadius: 24,
              overflow: 'hidden',
              boxShadow: `0 40px 100px rgba(0,0,0,0.70), 0 0 0 1px rgba(255,255,255,0.08), 0 0 80px ${accent}30`,
            }}
          >
            <AlbumArt song={currentSong} size="xl" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>
      </div>

      {/* ── Bottom controls ── */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0  }}
        transition={{ duration: 0.45, delay: 0.20, ease: EASE }}
        style={{
          position: 'absolute', bottom: 0, left: 0, right: 0,
          zIndex: 10,
          padding: '0 clamp(20px, 8vw, 120px) clamp(24px, 4vh, 48px)',
          display: 'flex', flexDirection: 'column', gap: 0,
        }}
      >
        {/* Track info */}
        <AnimatePresence mode="wait">
          <motion.div
            key={`info-${currentSong.id}`}
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0  }}
            exit={{    opacity: 0, x: -16 }}
            transition={{ duration: 0.28, ease: EASE }}
            style={{
              display: 'flex', alignItems: 'flex-end',
              justifyContent: 'space-between',
              marginBottom: 14,
            }}
          >
            <div style={{ minWidth: 0, flex: 1 }}>
              <h2 style={{
                fontFamily: 'var(--font-display)',
                fontSize: 'clamp(22px, 4vw, 38px)',
                fontWeight: 900, color: 'white',
                margin: '0 0 4px', lineHeight: 1.15,
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                textShadow: `0 0 40px ${accent}60, 0 2px 12px rgba(0,0,0,0.5)`,
              }}>
                {currentSong.title}
              </h2>
              <p style={{
                fontSize: 'clamp(13px, 2vw, 18px)',
                color: 'rgba(255,255,255,0.60)',
                margin: 0,
                textShadow: '0 1px 8px rgba(0,0,0,0.6)',
              }}>
                {currentSong.artist}
              </p>
            </div>

            {/* Like button */}
            <motion.button
              onClick={() => toggleLike(currentSong.id, currentSong)}
              whileHover={{ scale: 1.20 }} whileTap={{ scale: 0.75 }}
              style={{
                background: 'none', border: 'none', fontSize: 26,
                cursor: 'pointer', marginLeft: 16, flexShrink: 0,
                color: isLiked ? accent : 'rgba(255,255,255,0.45)',
                filter: isLiked ? `drop-shadow(0 0 12px ${accent}99)` : 'none',
                transition: 'color 0.2s, filter 0.2s',
              }}
            >
              {isLiked ? '♥' : '♡'}
            </motion.button>
          </motion.div>
        </AnimatePresence>

        {/* Progress scrubber */}
        <div style={{ marginBottom: 6 }}>
          <AmbientScrubber pct={progress} onSeek={seek} />
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
            <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.40)', fontVariantNumeric: 'tabular-nums' }}>
              {formatTime(currSec)}
            </span>
            <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.40)', fontVariantNumeric: 'tabular-nums' }}>
              {formatTime(currentSong.duration)}
            </span>
          </div>
        </div>

        {/* Controls row */}
        <div style={{
          display: 'flex', alignItems: 'center',
          justifyContent: 'space-between',
          marginTop: 10,
        }}>
          {/* Volume */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: 1 }}>
            <span style={{ fontSize: 14, color: 'rgba(255,255,255,0.45)' }}>
              {volume === 0 ? '🔇' : volume < 40 ? '🔉' : '🔊'}
            </span>
            <div style={{ width: 90 }}>
              <AmbientScrubber pct={volume} onSeek={setVolume} />
            </div>
          </div>

          {/* Playback buttons */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <ABtn title="Previous" size={44} onClick={playPrev}>&#9198;</ABtn>
            <ABtn primary size={64} title={isPlaying ? 'Pause' : 'Play'} onClick={togglePlay}>
              {isPlaying ? '\u23F8' : '\u25B6'}
            </ABtn>
            <ABtn title="Next" size={44} onClick={playNext}>&#9197;</ABtn>
          </div>

          {/* Right spacer — mirror the volume side */}
          <div style={{ flex: 1, display: 'flex', justifyContent: 'flex-end' }}>
            <motion.button
              onClick={onClose}
              whileHover={{ scale: 1.08 }}
              whileTap={{ scale: 0.92 }}
              title="Exit ambient mode"
              style={{
                background: 'rgba(255,255,255,0.08)',
                border: '1px solid rgba(255,255,255,0.14)',
                borderRadius: 10, padding: '7px 14px',
                color: 'rgba(255,255,255,0.55)',
                fontSize: 12, cursor: 'pointer',
                fontFamily: 'var(--font-body)',
                backdropFilter: 'blur(12px)',
                letterSpacing: '0.04em',
              }}
            >
              ⊠ Exit
            </motion.button>
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
}
EOF
echo -e "${GREEN}  ✓ src/components/AmbientMode.jsx${NC}"

# ════════════════════════════════════════════════════════════
# 4.  Patch Player.jsx
#     - Add useSleepTimer hook + SleepTimerMenu import
#     - Add sleep timer state (showTimer, timerMins)
#     - Add 🌙 button to right toolbar (before volume)
#     - Render SleepTimerMenu popover
#     - Add onAmbient prop + ✦ ambient button to right toolbar
# ════════════════════════════════════════════════════════════
PLAYER="src/components/Player.jsx"
python3 - "$PLAYER" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# ── A. Add imports at top ────────────────────────────────────
old_import_albumart = "import AlbumArt from './AlbumArt'"
new_imports = (
    "import AlbumArt from './AlbumArt'\n"
    "import { useSleepTimer } from '../hooks/useSleepTimer'\n"
    "import SleepTimerMenu from './SleepTimerMenu'"
)
if 'useSleepTimer' not in src:
    src = src.replace(old_import_albumart, new_imports, 1)

# ── B. Add onAmbient + onMiniPlayer to desktop props ────────
old_props = "export default function Player({ mobile = false, onNowPlayingClick, screenSize = 'desktop' }) {"
new_props  = "export default function Player({ mobile = false, onNowPlayingClick, onMiniPlayer, onAmbient, screenSize = 'desktop' }) {"
if 'onAmbient' not in src:
    if 'onMiniPlayer' in src:
        # mini-player already patched
        old_props2 = "export default function Player({ mobile = false, onNowPlayingClick, onMiniPlayer, screenSize = 'desktop' }) {"
        src = src.replace(old_props2, new_props, 1)
    else:
        src = src.replace(old_props, new_props, 1)

# ── C. Add sleep timer hook + state after withLoad definition
old_withload = (
    "  const withLoad = (setter, fn) => async () => {\n"
    "    setter(true)\n"
    "    try { await fn() } finally { setTimeout(() => setter(false), 650) }\n"
    "  }"
)
new_withload = (
    "  const withLoad = (setter, fn) => async () => {\n"
    "    setter(true)\n"
    "    try { await fn() } finally { setTimeout(() => setter(false), 650) }\n"
    "  }\n"
    "\n"
    "  const { remaining, start: startTimer, cancel: cancelTimer } = useSleepTimer()\n"
    "  const [showTimer, setShowTimer] = useState(false)\n"
    "  const [timerMins, setTimerMins] = useState(30)"
)
if 'useSleepTimer' in src and 'showTimer' not in src:
    src = src.replace(old_withload, new_withload, 1)

# ── D. Replace the right toolbar div with sleep + ambient + volume
old_right = (
    "      {/* Right: volume — desktop only */}\n"
    "      {!isTablet && (\n"
    "        <div style={{ display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'flex-end', position: 'relative', zIndex: 1, minWidth: 0 }}>\n"
    "          {['\\u2630', '\\u229E'].map(icon => (\n"
    "            <motion.button key={icon} whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.9 }}\n"
    "              style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s', WebkitTapHighlightColor: 'transparent' }}\n"
    "              onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}\n"
    "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}\n"
    "            >{icon}</motion.button>\n"
    "          ))}\n"
    "          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>\n"
    "            <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>{volume === 0 ? '\\uD83D\\uDD07' : volume < 40 ? '\\uD83D\\uDD08' : '\\uD83D\\uDD0A'}</span>\n"
    "            <Scrubber pct={volume} onSeek={setVolume} width=\"80px\" accent=\"linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))\" />\n"
    "          </div>\n"
    "        </div>\n"
    "      )}"
)
new_right = (
    "      {/* Right: sleep timer + ambient + mini-player + volume */}\n"
    "      {!isTablet && (\n"
    "        <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'flex-end', position: 'relative', zIndex: 1, minWidth: 0 }}>\n"
    "\n"
    "          {/* 🌙 Sleep timer button */}\n"
    "          <div style={{ position: 'relative' }}>\n"
    "            <motion.button\n"
    "              title='Sleep timer'\n"
    "              onClick={() => setShowTimer(v => !v)}\n"
    "              whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.90 }}\n"
    "              style={{\n"
    "                background: remaining !== null ? 'rgba(34,211,238,0.10)' : 'none',\n"
    "                border: remaining !== null ? '1px solid rgba(34,211,238,0.28)' : 'none',\n"
    "                borderRadius: 8,\n"
    "                color: remaining !== null ? 'var(--accent-primary)' : 'var(--text-muted)',\n"
    "                fontSize: 14, cursor: 'pointer',\n"
    "                width: 32, height: 32,\n"
    "                display: 'flex', alignItems: 'center', justifyContent: 'center',\n"
    "                transition: 'all 0.18s',\n"
    "                WebkitTapHighlightColor: 'transparent',\n"
    "                position: 'relative',\n"
    "              }}\n"
    "              onMouseEnter={e => { if (remaining === null) e.currentTarget.style.color = 'var(--text-primary)' }}\n"
    "              onMouseLeave={e => { if (remaining === null) e.currentTarget.style.color = 'var(--text-muted)' }}\n"
    "            >\n"
    "              🌙\n"
    "              {/* Active dot */}\n"
    "              {remaining !== null && (\n"
    "                <span style={{\n"
    "                  position: 'absolute', top: 2, right: 2,\n"
    "                  width: 6, height: 6, borderRadius: '50%',\n"
    "                  background: 'var(--accent-primary)',\n"
    "                  boxShadow: '0 0 6px var(--accent-primary)',\n"
    "                }} />\n"
    "              )}\n"
    "            </motion.button>\n"
    "            <AnimatePresence>\n"
    "              {showTimer && (\n"
    "                <SleepTimerMenu\n"
    "                  remaining={remaining}\n"
    "                  initialMins={timerMins}\n"
    "                  onStart={mins => { setTimerMins(mins); startTimer(mins) }}\n"
    "                  onCancel={cancelTimer}\n"
    "                  onClose={() => setShowTimer(false)}\n"
    "                />\n"
    "              )}\n"
    "            </AnimatePresence>\n"
    "          </div>\n"
    "\n"
    "          {/* ✦ Ambient mode button */}\n"
    "          {onAmbient && (\n"
    "            <motion.button\n"
    "              title='Ambient / Cinema mode'\n"
    "              onClick={onAmbient}\n"
    "              whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.90 }}\n"
    "              style={{\n"
    "                background: 'none', border: 'none',\n"
    "                color: 'var(--text-muted)', fontSize: 15,\n"
    "                cursor: 'pointer', transition: 'color 0.18s',\n"
    "                width: 32, height: 32,\n"
    "                display: 'flex', alignItems: 'center', justifyContent: 'center',\n"
    "                WebkitTapHighlightColor: 'transparent',\n"
    "              }}\n"
    "              onMouseEnter={e => e.currentTarget.style.color = 'var(--accent-primary)'}\n"
    "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}\n"
    "            >\n"
    "              ✦\n"
    "            </motion.button>\n"
    "          )}\n"
    "\n"
    "          {/* ⊟ Mini-player */}\n"
    "          {onMiniPlayer && (\n"
    "            <motion.button\n"
    "              title='Pop out mini-player'\n"
    "              onClick={onMiniPlayer}\n"
    "              whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.90 }}\n"
    "              style={{\n"
    "                background: 'none', border: 'none',\n"
    "                color: 'var(--text-muted)', fontSize: 15,\n"
    "                cursor: 'pointer', transition: 'color 0.18s',\n"
    "                width: 32, height: 32,\n"
    "                display: 'flex', alignItems: 'center', justifyContent: 'center',\n"
    "                WebkitTapHighlightColor: 'transparent',\n"
    "              }}\n"
    "              onMouseEnter={e => e.currentTarget.style.color = 'var(--accent-primary)'}\n"
    "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}\n"
    "            >\n"
    "              ⊟\n"
    "            </motion.button>\n"
    "          )}\n"
    "\n"
    "          {/* Volume */}\n"
    "          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>\n"
    "            <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>{volume === 0 ? '\\uD83D\\uDD07' : volume < 40 ? '\\uD83D\\uDD08' : '\\uD83D\\uDD0A'}</span>\n"
    "            <Scrubber pct={volume} onSeek={setVolume} width=\"80px\" accent=\"linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))\" />\n"
    "          </div>\n"
    "        </div>\n"
    "      )}"
)
if 'Sleep timer button' not in src:
    src = src.replace(old_right, new_right, 1)

if src == original:
    print('  ⚠  Player.jsx — no changes made')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Player.jsx patched')
PYEOF
echo -e "${GREEN}  ✓ src/components/Player.jsx patched${NC}"

# ════════════════════════════════════════════════════════════
# 5.  Patch Layout.jsx
#     - Import AmbientMode
#     - Add showAmbient state
#     - Pass onAmbient prop to all Player instances
#     - Render <AmbientMode> with AnimatePresence at root level
# ════════════════════════════════════════════════════════════
LAYOUT="src/components/Layout.jsx"
python3 - "$LAYOUT" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# ── A. Add AmbientMode import after last import line ─────────
lines = src.split('\n')
last_import_idx = max(i for i, l in enumerate(lines) if l.startswith('import '))
if 'AmbientMode' not in src:
    lines.insert(last_import_idx + 1, "import AmbientMode   from './AmbientMode'")
src = '\n'.join(lines)

# ── B. Add showAmbient state after activePage state ──────────
old_state = "  const [activePage,     setActivePage]     = useState('Home')"
new_state  = (
    "  const [activePage,     setActivePage]     = useState('Home')\n"
    "  const [showAmbient,    setShowAmbient]    = useState(false)"
)
if 'showAmbient' not in src:
    src = src.replace(old_state, new_state, 1)

# ── C. Desktop <Player /> — add onAmbient ────────────────────
if 'onMiniPlayer={() => setShowMini(true)}' in src:
    old_dp = "            <Player onMiniPlayer={() => setShowMini(true)} />"
    new_dp = "            <Player onMiniPlayer={() => setShowMini(true)} onAmbient={() => setShowAmbient(true)} />"
else:
    old_dp = "            <Player />"
    new_dp = "            <Player onAmbient={() => setShowAmbient(true)} />"
if 'onAmbient' not in src:
    src = src.replace(old_dp, new_dp, 1)

# ── D. Tablet <Player /> — add onAmbient ─────────────────────
if 'onMiniPlayer={() => setShowMini(true)}' in src:
    old_tp = "            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} onMiniPlayer={() => setShowMini(true)} />"
    new_tp = "            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} onMiniPlayer={() => setShowMini(true)} onAmbient={() => setShowAmbient(true)} />"
else:
    old_tp = "            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} />"
    new_tp = "            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} onAmbient={() => setShowAmbient(true)} />"
if '&& onAmbient' not in src:
    src = src.replace(old_tp, new_tp, 1)

# ── E. Render AmbientMode just before the final </div> ───────
old_closing = "    </div>\n  )\n}"
new_closing = (
    "\n"
    "      {/* Ambient / Cinema mode overlay */}\n"
    "      <AnimatePresence>\n"
    "        {showAmbient && (\n"
    "          <AmbientMode onClose={() => setShowAmbient(false)} />\n"
    "        )}\n"
    "      </AnimatePresence>\n"
    "    </div>\n"
    "  )\n"
    "}"
)
if 'AmbientMode' not in src or 'showAmbient &&' not in src:
    src = src.replace(old_closing, new_closing, 1)

if src == original:
    print('  ⚠  Layout.jsx — no changes made')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Layout.jsx patched')
PYEOF
echo -e "${GREEN}  ✓ src/components/Layout.jsx patched${NC}"

# ════════════════════════════════════════════════════════════
# 6.  Self-verify
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}  Verifying...${NC}"
python3 << 'PYEOF'
checks = {
    'src/components/Player.jsx': [
        'useSleepTimer', 'SleepTimerMenu', 'onAmbient',
        'Sleep timer button', 'Ambient mode button',
    ],
    'src/components/Layout.jsx': [
        'AmbientMode', 'showAmbient', 'setShowAmbient',
        'showAmbient &&',
    ],
}
import os
all_ok = True
for path, patterns in checks.items():
    with open(path) as f: src = f.read()
    for p in patterns:
        if p in src:
            print(f'  ✓  {path} — {p}')
        else:
            print(f'  ✗  {path} — MISSING: {p}')
            all_ok = False
for f in ['src/hooks/useSleepTimer.js','src/components/SleepTimerMenu.jsx','src/components/AmbientMode.jsx']:
    if os.path.exists(f):
        print(f'  ✓  {f} exists')
    else:
        print(f'  ✗  MISSING: {f}')
        all_ok = False
if not all_ok:
    import sys; sys.exit(1)
PYEOF

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Sleep Timer + Ambient Mode installed successfully!    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}New files:${NC}"
echo -e "    + src/hooks/useSleepTimer.js"
echo -e "    + src/components/SleepTimerMenu.jsx"
echo -e "    + src/components/AmbientMode.jsx"
echo ""
echo -e "  ${CYAN}Patched:${NC}"
echo -e "    ~ src/components/Player.jsx   — 🌙 + ✦ buttons in right toolbar"
echo -e "    ~ src/components/Layout.jsx   — AmbientMode overlay wired in"
echo ""
echo -e "  ${CYAN}Sleep Timer (🌙 button):${NC}"
echo -e "    • Pick 15 / 30 / 45 / 60 min"
echo -e "    • Circular ring counts down live in the popover"
echo -e "    • Glowing dot on button while active"
echo -e "    • Volume fades to 0 over 20s, then pauses"
echo -e "    • Restores volume after pause"
echo -e "    • Survives page refresh (localStorage)"
echo ""
echo -e "  ${CYAN}Ambient Mode (✦ button):${NC}"
echo -e "    • Full-screen blurred album art backdrop (blur: 72px)"
echo -e "    • Floating particles drift upward in accent colour"
echo -e "    • Floating controls: scrubber, prev/play/next, like, volume"
echo -e "    • Track title with glow text-shadow"
echo -e "    • Crossfades between songs"
echo -e "    • Press Esc or ✕ to exit"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
