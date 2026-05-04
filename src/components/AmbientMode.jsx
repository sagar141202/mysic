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
