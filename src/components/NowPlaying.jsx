import { useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'
import AudioVisualizer from './AudioVisualizer'

const EASE = [0.25, 0.46, 0.45, 0.94]

/* ── Touch + Mouse scrubber ─────────────────────────────── */
function Scrubber({ pct, onSeek }) {
  const dragging = useRef(false)

  const calc = (clientX, el) => {
    const rect = el.getBoundingClientRect()
    return Math.max(0, Math.min(100, ((clientX - rect.left) / rect.width) * 100))
  }

  /* Mouse */
  const onMouseDown = useCallback(e => {
    e.preventDefault()
    dragging.current = true
    onSeek(calc(e.clientX, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev.clientX, el)) }
    const onUp   = () => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }, [onSeek])

  /* Touch */
  const onTouchStart = useCallback(e => {
    dragging.current = true
    onSeek(calc(e.touches[0].clientX, e.currentTarget))
  }, [onSeek])

  const onTouchMove = useCallback(e => {
    if (!dragging.current) return
    e.preventDefault()          /* stop page scroll while scrubbing */
    onSeek(calc(e.touches[0].clientX, e.currentTarget))
  }, [onSeek])

  const onTouchEnd = useCallback(() => { dragging.current = false }, [])

  return (
    /* 28px tall hit-area — comfortable finger target */
    <div
      onMouseDown={onMouseDown}
      onTouchStart={onTouchStart}
      onTouchMove={onTouchMove}
      onTouchEnd={onTouchEnd}
      style={{
        flex: 1, height: 28,
        display: 'flex', alignItems: 'center',
        cursor: 'pointer',
        touchAction: 'none',   /* required for onTouchMove to work */
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      <div style={{ width: '100%', height: 5, borderRadius: 5, background: 'rgba(255,255,255,0.09)', position: 'relative' }}>
        <div style={{ width: `${pct}%`, height: '100%', borderRadius: 5, background: 'var(--accent-grad)', position: 'relative', transition: 'width 0.9s linear' }}>
          <div style={{
            position: 'absolute', right: -6, top: '50%', transform: 'translateY(-50%)',
            width: 14, height: 14, borderRadius: '50%',
            background: 'white',
            boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.30)',
          }} />
        </div>
      </div>
    </div>
  )
}

/* ── Button ─────────────────────────────────────────────── */
function Btn({ children, onClick, size = 40, primary = false, title }) {
  return (
    <motion.button
      title={title}
      onClick={onClick}
      whileHover={{ scale: primary ? 1.07 : 1.11 }}
      whileTap={{ scale: primary ? 0.93 : 0.86 }}
      style={{
        /* min 44px tap-target wrapper */
        width: Math.max(size, 44), height: Math.max(size, 44),
        borderRadius: '50%', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)',
        border: primary ? 'none' : '1px solid rgba(255,255,255,0.09)',
        color: primary ? '#08121f' : 'var(--text-secondary)',
        fontSize: primary ? 20 : 15,
        cursor: 'pointer',
        boxShadow: primary ? '0 6px 22px rgba(34,211,238,0.40)' : 'none',
        WebkitTapHighlightColor: 'transparent',
        touchAction: 'manipulation',
      }}
    >
      {children}
    </motion.button>
  )
}

/* ── Main Component ─────────────────────────────────────── */
export default function NowPlaying({ onClose }) {
  const {
    currentSong, isPlaying, progress, volume,
    togglePlay, playNext, playPrev, seek, setVolume,
    toggleLike, liked, queue,
  } = usePlayer()

  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)

  const upNext = (() => {
    const idx = queue.findIndex(s => s.id === currentSong.id)
    if (idx < 0 || queue.length < 2) return []
    return [1, 2, 3]
      .map(o => queue[(idx + o) % queue.length])
      .filter(Boolean)
  })()

  return (
    <div style={{
      height: '100%',
      display: 'flex', flexDirection: 'column',
      /* safe-area aware padding */
      padding: 'max(22px, env(safe-area-inset-top, 22px)) 18px 18px',
      background: 'rgba(8,12,20,0.78)',
      backdropFilter: 'blur(32px)', WebkitBackdropFilter: 'blur(32px)',
      borderLeft: '1px solid rgba(255,255,255,0.06)',
      fontFamily: 'var(--font-body)',
      overflowY: 'auto',
      overscrollBehavior: 'contain',
      WebkitOverflowScrolling: 'touch',
      /* prevent text from ever overflowing */
      wordBreak: 'break-word',
    }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20, flexShrink: 0 }}>
        <p style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.12em', textTransform: 'uppercase', margin: 0 }}>
          Now Playing
        </p>
        {onClose && (
          <motion.button
            onClick={onClose}
            whileHover={{ scale: 1.2, rotate: 90 }}
            whileTap={{ scale: 0.88 }}
            aria-label="Close"
            style={{
              /* 44px tap target */
              width: 44, height: 44,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'none', border: 'none',
              color: 'var(--text-muted)', fontSize: 16, cursor: 'pointer',
              WebkitTapHighlightColor: 'transparent',
              marginRight: -10,
            }}
          >
            &#10005;
          </motion.button>
        )}
      </div>

      {/* Album Art */}
      <AnimatePresence mode="wait">
        <motion.div
          key={currentSong.id}
          initial={{ opacity: 0, scale: 0.92, y: 14 }}
          animate={{ opacity: 1, scale: 1,   y: 0  }}
          exit={{    opacity: 0, scale: 0.92, y: -14 }}
          transition={{ duration: 0.32, ease: EASE }}
          style={{
            marginBottom: 20, borderRadius: 18, overflow: 'hidden', flexShrink: 0,
            boxShadow: `0 24px 64px ${currentSong.color || '#8b5cf6'}35`,
            /* prevent art from overflowing narrow panels */
            maxWidth: '100%',
          }}
        >
          <AlbumArt song={currentSong} size="xl" isPlaying={isPlaying} />
        </motion.div>
      </AnimatePresence>


      {/* Audio Visualizer */}
      <AudioVisualizer
        isPlaying={isPlaying}
        songId={currentSong.id}
        color={currentSong.color || '#22d3ee'}
        height={64}
        style={{ marginBottom: 18, flexShrink: 0 }}
      />

      {/* Track info */}
      <AnimatePresence mode="wait">
        <motion.div
          key={`info-${currentSong.id}`}
          initial={{ opacity: 0, x: 18 }}
          animate={{ opacity: 1, x: 0  }}
          exit={{    opacity: 0, x: -18 }}
          transition={{ duration: 0.24, ease: EASE }}
          style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 16, flexShrink: 0 }}
        >
          <div style={{ minWidth: 0, flex: 1 }}>
            <h3 style={{
              fontFamily: 'var(--font-display)',
              /* clamp keeps title readable on any width */
              fontSize: 'clamp(15px, 4vw, 18px)',
              fontWeight: 800, color: 'var(--text-primary)',
              margin: '0 0 4px', lineHeight: 1.25,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>
              {currentSong.title}
            </h3>
            <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0 }}>
              {currentSong.artist}
            </p>
          </div>
          <motion.button
            onClick={() => toggleLike(currentSong.id, currentSong)}
            whileHover={{ scale: 1.2 }} whileTap={{ scale: 0.75 }}
            aria-label={isLiked ? 'Unlike' : 'Like'}
            style={{
              width: 44, height: 44,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'none', border: 'none', fontSize: 20, cursor: 'pointer',
              marginLeft: 4, flexShrink: 0,
              color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
              filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none',
              transition: 'color 0.2s, filter 0.2s',
              WebkitTapHighlightColor: 'transparent',
            }}
          >
            {isLiked ? '\u2665' : '\u2661'}
          </motion.button>
        </motion.div>
      </AnimatePresence>

      {/* Progress scrubber */}
      <div style={{ marginBottom: 18, flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <Scrubber pct={progress} onSeek={seek} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
          <span style={{ fontSize: 11, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSec)}</span>
          <span style={{ fontSize: 11, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSong.duration)}</span>
        </div>
      </div>

      {/* Controls */}
      <motion.div
        initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.28, delay: 0.08 }}
        style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 18, flexShrink: 0 }}
      >
        <Btn title="Shuffle">&#8700;</Btn>
        <Btn title="Previous" onClick={playPrev}>&#9198;</Btn>
        <Btn primary size={54} title={isPlaying ? 'Pause' : 'Play'} onClick={togglePlay}>
          {isPlaying ? '\u23F8' : '\u25B6'}
        </Btn>
        <Btn title="Next" onClick={playNext}>&#9197;</Btn>
        <Btn title="Repeat">&#8635;</Btn>
      </motion.div>

      {/* Volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 22, flexShrink: 0 }}>
        <span style={{ fontSize: 14, color: 'var(--text-muted)', flexShrink: 0 }}>
          {volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}
        </span>
        <Scrubber pct={volume} onSeek={setVolume} />
        <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 30, textAlign: 'right', fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
          {Math.round(volume)}%
        </span>
      </div>

      {/* Up Next */}
      {upNext.length > 0 && (
        <div style={{ borderTop: '1px solid rgba(255,255,255,0.07)', paddingTop: 16, flex: 1, minHeight: 0 }}>
          <p style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.12em', color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 10, marginTop: 0 }}>
            Up Next
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {upNext.map((song, i) => (
              <motion.div
                key={`${song.id}-${i}`}
                initial={{ opacity: 0, x: 14 }}
                animate={{ opacity: 1, x: 0  }}
                transition={{ duration: 0.22, delay: i * 0.06, ease: EASE }}
                whileHover={{ x: 4, transition: { duration: 0.14 } }}
                /* 44px min height for tappability */
                style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  padding: '10px 8px', borderRadius: 11,
                  minHeight: 44,
                  cursor: 'pointer',
                  border: '1px solid transparent',
                  transition: 'background 0.2s, border-color 0.2s',
                  WebkitTapHighlightColor: 'transparent',
                }}
                onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.07)' }}
                onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}
              >
                <AlbumArt song={song} size="xs" />
                <div style={{ minWidth: 0, flex: 1 }}>
                  <p style={{ fontSize: 13, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
                  <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: 0 }}>{song.artist}</p>
                </div>
                <span style={{ fontSize: 11, color: 'var(--text-muted)', flexShrink: 0 }}>{formatTime(song.duration)}</span>
              </motion.div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
