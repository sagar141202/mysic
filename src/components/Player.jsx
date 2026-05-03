import { useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]

function useScrubber(onSeek) {
  const dragging = useRef(false)
  const calc = (e, el) => {
    const rect = el.getBoundingClientRect()
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left
    return Math.max(0, Math.min(100, (x / rect.width) * 100))
  }
  const onMouseDown = useCallback(e => {
    dragging.current = true
    onSeek(calc(e, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev, el)) }
    const onUp   = ()  => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }, [onSeek])
  return { onMouseDown }
}

function Scrubber({ pct, onSeek, width = '100%', accent = 'var(--accent-grad)' }) {
  const { onMouseDown } = useScrubber(onSeek)
  return (
    <div onMouseDown={onMouseDown} style={{ width, height: 4, borderRadius: 4, background: 'rgba(255,255,255,0.08)', cursor: 'pointer', position: 'relative', flexShrink: 0 }}>
      <div style={{ width: `${pct}%`, height: '100%', borderRadius: 4, background: accent, position: 'relative', transition: 'width 0.9s linear' }}>
        <div style={{ position: 'absolute', right: -5, top: '50%', transform: 'translateY(-50%)', width: 12, height: 12, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.25)' }} />
      </div>
    </div>
  )
}

function Btn({ children, onClick, size = 32, primary = false, title }) {
  return (
    <motion.button
      title={title} onClick={onClick}
      whileHover={{ scale: primary ? 1.08 : 1.15 }}
      whileTap={{ scale: primary ? 0.93 : 0.85 }}
      style={{ width: size, height: size, borderRadius: '50%', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)', border: primary ? 'none' : '1px solid rgba(255,255,255,0.09)', color: primary ? '#08121f' : 'var(--text-secondary)', fontSize: primary ? 15 : 13, cursor: 'pointer', boxShadow: primary ? '0 4px 16px rgba(34,211,238,0.38)' : 'none' }}
    >{children}</motion.button>
  )
}

function MobilePlayer({ onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, togglePlay, playNext } = usePlayer()
  return (
    <div style={{ fontFamily: 'var(--font-body)', background: 'rgba(8,12,20,0.95)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
      <div style={{ height: 2, background: 'rgba(255,255,255,0.06)' }}>
        <motion.div
          style={{ height: '100%', background: 'var(--accent-grad)' }}
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.9, ease: 'linear' }}
        />
      </div>
      <div onClick={onNowPlayingClick} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px', cursor: 'pointer' }}>
        {/* Album art cross-fades on track change */}
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id} initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.25, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>
        {/* Track info cross-fades */}
        <AnimatePresence mode="wait">
          <motion.div key={`title-${currentSong.id}`} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }} transition={{ duration: 0.2 }} style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.title}</p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>
        <Btn primary size={34} onClick={e => { e.stopPropagation(); togglePlay() }} title={isPlaying ? 'Pause' : 'Play'}>{isPlaying ? '\u23F8' : '\u25B6'}</Btn>
        <Btn size={30} onClick={e => { e.stopPropagation(); playNext() }} title="Next">&#9197;</Btn>
      </div>
    </div>
  )
}

export default function Player({ mobile = false, onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, volume, togglePlay, playNext, playPrev, seek, setVolume, toggleLike, liked } = usePlayer()
  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)

  if (mobile) return <MobilePlayer onNowPlayingClick={onNowPlayingClick} />

  return (
    <div style={{ height: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', alignItems: 'center', padding: '0 22px', background: 'rgba(8,12,20,0.92)', backdropFilter: 'blur(30px)', borderTop: '1px solid rgba(255,255,255,0.06)', fontFamily: 'var(--font-body)' }}>

      {/* Left: track info — cross-fades on song change */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id} initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.25, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>
        <AnimatePresence mode="wait">
          <motion.div key={`title-${currentSong.id}`} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }} transition={{ duration: 0.2, ease: EASE }} style={{ minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 140 }}>{currentSong.title}</p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>
        <motion.button
          onClick={() => toggleLike(currentSong.id, currentSong)}
          whileHover={{ scale: 1.25 }} whileTap={{ scale: 0.75 }}
          style={{ background: 'none', border: 'none', flexShrink: 0, fontSize: 16, cursor: 'pointer', color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none', transition: 'color 0.2s, filter 0.2s' }}
        >{isLiked ? '\u2665' : '\u2661'}</motion.button>
      </div>

      {/* Centre: controls + scrubber */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <Btn title="Shuffle">&#8700;</Btn>
          <Btn title="Previous" onClick={playPrev}>&#9198;</Btn>
          <Btn primary size={38} title={isPlaying ? 'Pause' : 'Play'} onClick={togglePlay}>
            <AnimatePresence mode="wait">
              <motion.span key={isPlaying ? 'pause' : 'play'} initial={{ scale: 0, rotate: -30 }} animate={{ scale: 1, rotate: 0 }} exit={{ scale: 0, rotate: 30 }} transition={{ duration: 0.15 }}>
                {isPlaying ? '\u23F8' : '\u25B6'}
              </motion.span>
            </AnimatePresence>
          </Btn>
          <Btn title="Next" onClick={playNext}>&#9197;</Btn>
          <Btn title="Repeat">&#8635;</Btn>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', maxWidth: 340 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSec)}</span>
          <Scrubber pct={progress} onSeek={seek} />
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSong.duration)}</span>
        </div>
      </div>

      {/* Right: volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, justifyContent: 'flex-end' }}>
        {['\u2630', '\u229E'].map(icon => (
          <motion.button key={icon} whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.9 }} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
          >{icon}</motion.button>
        ))}
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}</span>
          <Scrubber pct={volume} onSeek={setVolume} width="80px" accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
        </div>
      </div>
    </div>
  )
}
