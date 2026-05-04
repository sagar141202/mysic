import { useRef, useCallback, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'
import { useSleepTimer } from '../hooks/useSleepTimer'
import SleepTimerMenu from './SleepTimerMenu'

const EASE = [0.25, 0.46, 0.45, 0.94]

/* ── Scrubber (mouse + touch) ───────────────────────────── */
function Scrubber({ pct, onSeek, width = '100%', accent = 'var(--accent-grad)' }) {
  const dragging = useRef(false)
  const [hovered, setHovered] = useState(false)

  const calc = (clientX, el) => {
    const rect = el.getBoundingClientRect()
    return Math.max(0, Math.min(100, ((clientX - rect.left) / rect.width) * 100))
  }

  const onMouseDown = useCallback(e => {
    e.preventDefault(); dragging.current = true
    onSeek(calc(e.clientX, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev.clientX, el)) }
    const onUp   = () => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }, [onSeek])

  const onTouchStart = useCallback(e => {
    dragging.current = true
    onSeek(calc(e.touches[0].clientX, e.currentTarget))
  }, [onSeek])
  const onTouchMove  = useCallback(e => {
    if (!dragging.current) return
    e.preventDefault()
    onSeek(calc(e.touches[0].clientX, e.currentTarget))
  }, [onSeek])
  const onTouchEnd   = useCallback(() => { dragging.current = false }, [])

  return (
    <div
      onMouseDown={onMouseDown}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onTouchStart={onTouchStart}
      onTouchMove={onTouchMove}
      onTouchEnd={onTouchEnd}
      style={{
        width, height: 24,   /* tall touch target */
        display: 'flex', alignItems: 'center',
        cursor: 'pointer', flexShrink: 0,
        touchAction: 'none',
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      <div style={{
        width: '100%', height: hovered ? 6 : 4,
        borderRadius: 4,
        background: 'rgba(255,255,255,0.08)',
        position: 'relative',
        transition: 'height 0.15s ease',
      }}>
        <div style={{
          width: `${pct}%`, height: '100%', borderRadius: 4,
          background: accent, position: 'relative',
          transition: 'width 0.9s linear',
          boxShadow: hovered ? '0 0 8px rgba(34,211,238,0.4)' : 'none',
        }}>
          <motion.div
            animate={{ opacity: hovered ? 1 : 0, scale: hovered ? 1 : 0.5 }}
            transition={{ duration: 0.14 }}
            style={{
              position: 'absolute', right: -6, top: '50%', transform: 'translateY(-50%)',
              width: 13, height: 13, borderRadius: '50%',
              background: 'white',
              boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.25)',
            }}
          />
        </div>
      </div>
    </div>
  )
}

/* ── Button ─────────────────────────────────────────────── */
function Btn({ children, onClick, size = 32, primary = false, title, loading = false }) {
  return (
    <motion.button
      title={title} onClick={onClick}
      whileHover={{ scale: primary ? 1.08 : 1.14 }}
      whileTap={{ scale: primary ? 0.92 : 0.84 }}
      style={{
        /* 44px minimum tap target */
        width: Math.max(size, 44), height: Math.max(size, 44),
        borderRadius: '50%', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)',
        border: primary ? 'none' : '1px solid rgba(255,255,255,0.09)',
        color: primary ? '#08121f' : 'var(--text-secondary)',
        fontSize: primary ? 15 : 13, cursor: 'pointer',
        boxShadow: primary ? '0 4px 16px rgba(34,211,238,0.38)' : 'none',
        position: 'relative', overflow: 'hidden',
        WebkitTapHighlightColor: 'transparent',
        touchAction: 'manipulation',
      }}
    >
      <AnimatePresence mode="wait">
        {loading ? (
          <motion.span key="spin" initial={{ opacity: 0, scale: 0.6 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.15 }}>
            <svg width={primary ? 16 : 12} height={primary ? 16 : 12} viewBox="0 0 24 24" fill="none" style={{ animation: 'spin 0.75s linear infinite' }}>
              <circle cx="12" cy="12" r="9" stroke={primary ? '#08121f' : 'var(--accent-primary)'} strokeWidth="2.5" strokeLinecap="round" strokeDasharray="42 14" />
            </svg>
          </motion.span>
        ) : (
          <motion.span key="icon" initial={{ opacity: 0, scale: 0.7, rotate: 20 }} animate={{ opacity: 1, scale: 1, rotate: 0 }} exit={{ opacity: 0, scale: 0.7, rotate: -20 }} transition={{ duration: 0.16 }}>
            {children}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  )
}

/* ── Mobile strip ───────────────────────────────────────── */
function MobilePlayer({ onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, togglePlay, playNext } = usePlayer()
  const [playLoad, setPlayLoad] = useState(false)

  const handlePlay = async e => {
    e.stopPropagation()
    setPlayLoad(true)
    await togglePlay()
    setTimeout(() => setPlayLoad(false), 650)
  }

  return (
    <div style={{ fontFamily: 'var(--font-body)', background: 'rgba(8,12,20,0.96)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.07)', position: 'relative', overflow: 'hidden' }}>
      {/* Ambient glow */}
      <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', background: `radial-gradient(ellipse 60% 100% at 50% 140%, ${currentSong.color || '#22d3ee'}20 0%, transparent 70%)`, transition: 'background 0.8s ease' }} />

      {/* Progress strip */}
      <div style={{ height: 2, background: 'rgba(255,255,255,0.06)' }}>
        <motion.div style={{ height: '100%', background: 'var(--accent-grad)' }} animate={{ width: `${progress}%` }} transition={{ duration: 0.9, ease: 'linear' }} />
      </div>

      <div
        onClick={onNowPlayingClick}
        style={{
          display: 'flex', alignItems: 'center', gap: 12,
          /* 64px height = very tappable */
          padding: '10px 16px',
          minHeight: 64,
          cursor: 'pointer', position: 'relative', zIndex: 1,
          WebkitTapHighlightColor: 'transparent',
        }}
      >
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id} initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.22, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>

        <AnimatePresence mode="wait">
          <motion.div key={`t-${currentSong.id}`} initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -5 }} transition={{ duration: 0.18 }} style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontSize: 14, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.title}</p>
            <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>

        <Btn primary size={36} onClick={handlePlay} loading={playLoad} title={isPlaying ? 'Pause' : 'Play'}>
          {isPlaying ? '\u23F8' : '\u25B6'}
        </Btn>
        <Btn size={32} onClick={e => { e.stopPropagation(); playNext() }} title="Next">&#9197;</Btn>
      </div>
    </div>
  )
}

/* ── Desktop / Tablet Player ────────────────────────────── */
export default function Player({ mobile = false, onNowPlayingClick, onMiniPlayer, onAmbient, screenSize = 'desktop' }) {
  const { currentSong, isPlaying, progress, volume, togglePlay, playNext, playPrev, seek, setVolume, toggleLike, liked } = usePlayer()
  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)
  const isTablet   = screenSize === 'tablet'

  const [playLoad, setPlayLoad] = useState(false)
  const [prevLoad, setPrevLoad] = useState(false)
  const [nextLoad, setNextLoad] = useState(false)

  const withLoad = (setter, fn) => async () => {
    setter(true)
    try { await fn() } finally { setTimeout(() => setter(false), 650) }
  }

  const { remaining, start: startTimer, cancel: cancelTimer } = useSleepTimer()
  const [showTimer, setShowTimer] = useState(false)
  const [timerMins, setTimerMins] = useState(30)

  if (mobile) return <MobilePlayer onNowPlayingClick={onNowPlayingClick} />

  return (
    <div style={{
      height: '100%',
      display: 'grid',
      /* tablet: 2 cols (track info+controls) | (volume) */
      /* desktop: 3 cols equal */
      gridTemplateColumns: isTablet ? '1fr auto' : '1fr 1fr 1fr',
      alignItems: 'center',
      padding: `0 ${isTablet ? 14 : 22}px`,
      background: 'rgba(8,12,20,0.93)',
      backdropFilter: 'blur(32px)',
      borderTop: '1px solid rgba(255,255,255,0.07)',
      fontFamily: 'var(--font-body)',
      position: 'relative', overflow: 'hidden',
      /* prevent grid children from overflowing */
      minWidth: 0,
    }}>
      {/* Ambient glow */}
      <motion.div key={currentSong.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 1.2 }}
        style={{ position: 'absolute', inset: 0, pointerEvents: 'none', background: `radial-gradient(ellipse 40% 200% at 50% 120%, ${currentSong.color || '#22d3ee'}16 0%, transparent 70%)` }} />

      {/* Left: track info */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, minWidth: 0, position: 'relative', zIndex: 1 }}>
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id} initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.22, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>

        <AnimatePresence mode="wait">
          <motion.div key={`t-${currentSong.id}`} initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -5 }} transition={{ duration: 0.18, ease: EASE }} style={{ minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: isTablet ? 110 : 150 }}>{currentSong.title}</p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: isTablet ? 110 : 150 }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>

        <motion.button onClick={() => toggleLike(currentSong.id, currentSong)}
          whileHover={{ scale: 1.25 }} whileTap={{ scale: 0.75 }}
          style={{ background: 'none', border: 'none', flexShrink: 0, width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, cursor: 'pointer', color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none', transition: 'color 0.2s, filter 0.2s', WebkitTapHighlightColor: 'transparent' }}
        >{isLiked ? '\u2665' : '\u2661'}</motion.button>
      </div>

      {/* Centre: controls + scrubber — on tablet this is merged into left col visually */}
      {!isTablet && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, position: 'relative', zIndex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Btn title="Shuffle">&#8700;</Btn>
            <Btn title="Previous" onClick={withLoad(setPrevLoad, playPrev)} loading={prevLoad}>&#9198;</Btn>
            <Btn primary size={38} title={isPlaying ? 'Pause' : 'Play'} loading={playLoad} onClick={withLoad(setPlayLoad, togglePlay)}>
              {isPlaying ? '\u23F8' : '\u25B6'}
            </Btn>
            <Btn title="Next" onClick={withLoad(setNextLoad, playNext)} loading={nextLoad}>&#9197;</Btn>
            <Btn title="Repeat">&#8635;</Btn>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', maxWidth: 340 }}>
            <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, textAlign: 'right', fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>{formatTime(currentSec)}</span>
            <Scrubber pct={progress} onSeek={seek} />
            <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>{formatTime(currentSong.duration)}</span>
          </div>
        </div>
      )}

      {/* Tablet compact controls */}
      {isTablet && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, position: 'relative', zIndex: 1, paddingLeft: 10 }}>
          <Btn title="Previous" size={28} onClick={withLoad(setPrevLoad, playPrev)} loading={prevLoad}>&#9198;</Btn>
          <Btn primary size={34} title={isPlaying ? 'Pause' : 'Play'} loading={playLoad} onClick={withLoad(setPlayLoad, togglePlay)}>
            {isPlaying ? '\u23F8' : '\u25B6'}
          </Btn>
          <Btn title="Next" size={28} onClick={withLoad(setNextLoad, playNext)} loading={nextLoad}>&#9197;</Btn>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginLeft: 6 }}>
            <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{volume === 0 ? '\uD83D\uDD07' : '\uD83D\uDD0A'}</span>
            <Scrubber pct={volume} onSeek={setVolume} width="70px" accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
          </div>
        </div>
      )}

      {/* Right: volume — desktop only */}
      {!isTablet && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'flex-end', position: 'relative', zIndex: 1, minWidth: 0 }}>
          {['\u2630', '\u229E'].map(icon => (
            <motion.button key={icon} whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.9 }}
              style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s', WebkitTapHighlightColor: 'transparent' }}
              onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
            >{icon}</motion.button>
          ))}
          {/* Mini-player pop-out */}
          {onMiniPlayer && (
            <motion.button
              title='Pop out mini-player'
              onClick={onMiniPlayer}
              whileHover={{ scale: 1.15 }}
              whileTap={{ scale: 0.90 }}
              style={{
                background: 'none', border: 'none',
                color: 'var(--text-muted)', fontSize: 14,
                cursor: 'pointer', transition: 'color 0.2s',
                WebkitTapHighlightColor: 'transparent',
              }}
              onMouseEnter={e => e.currentTarget.style.color = 'var(--accent-primary)'}
              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
            >
              &#x229F;
            </motion.button>
          )}
          {/* Mini-player pop-out button */}
          {onMiniPlayer && (
            <motion.button
              title="Pop out mini-player"
              onClick={onMiniPlayer}
              whileHover={{ scale: 1.18 }}
              whileTap={{ scale: 0.88 }}
              style={{
                background: 'none', border: 'none',
                color: 'var(--text-muted)',
                fontSize: 16, cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                width: 32, height: 32, borderRadius: 8,
                transition: 'color 0.18s',
                WebkitTapHighlightColor: 'transparent',
              }}
              onMouseEnter={e => e.currentTarget.style.color = 'var(--accent-primary)'}
              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
            >
              ⊟
            </motion.button>
          )}
          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
            <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>{volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}</span>
            <Scrubber pct={volume} onSeek={setVolume} width="80px" accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
          </div>
        </div>
      )}
    </div>
  )
}
