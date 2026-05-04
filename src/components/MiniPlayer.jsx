import { useRef, useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence }                   from 'framer-motion'
import { usePlayer }                                 from '../hooks/usePlayer.jsx'
import AlbumArt                                      from './AlbumArt'

const EASE   = [0.25, 0.46, 0.45, 0.94]
const W      = 300
const H      = 76
const MARGIN = 18

function PillBtn({ children, onClick, primary = false, title }) {
  const [hov, setHov] = useState(false)
  return (
    <button
      title={title}
      onClick={onClick}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        width: 34, height: 34, borderRadius: '50%', border: 'none',
        flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: primary
          ? 'var(--accent-grad)'
          : hov ? 'rgba(255,255,255,0.10)' : 'rgba(255,255,255,0.04)',
        color:  primary ? '#08121f' : 'var(--text-secondary)',
        fontSize: primary ? 13 : 11,
        cursor: 'pointer',
        transition: 'background 0.15s',
        WebkitTapHighlightColor: 'transparent',
        touchAction: 'manipulation',
        boxShadow: primary ? '0 3px 12px rgba(34,211,238,0.40)' : 'none',
      }}
    >
      {children}
    </button>
  )
}

export default function MiniPlayer({ onClose, onExpand }) {
  const {
    currentSong, isPlaying, progress,
    togglePlay, playNext, playPrev,
  } = usePlayer()

  const startPos = useCallback(() => ({
    x: window.innerWidth  - W - MARGIN,
    y: window.innerHeight - H - MARGIN - 80,
  }), [])

  const [pos,      setPos]      = useState(startPos)
  const [dragging, setDragging] = useState(false)
  const dragStart = useRef({ mx: 0, my: 0, px: 0, py: 0 })

  const clamp = useCallback((x, y) => ({
    x: Math.max(MARGIN, Math.min(window.innerWidth  - W - MARGIN, x)),
    y: Math.max(MARGIN, Math.min(window.innerHeight - H - MARGIN, y)),
  }), [])

  const onPointerDown = useCallback(e => {
    if (e.target.closest('button')) return
    e.currentTarget.setPointerCapture(e.pointerId)
    setDragging(true)
    dragStart.current = { mx: e.clientX, my: e.clientY, px: pos.x, py: pos.y }
  }, [pos])

  const onPointerMove = useCallback(e => {
    if (!dragging) return
    const dx = e.clientX - dragStart.current.mx
    const dy = e.clientY - dragStart.current.my
    setPos(clamp(dragStart.current.px + dx, dragStart.current.py + dy))
  }, [dragging, clamp])

  const onPointerUp = useCallback(e => {
    e.currentTarget?.releasePointerCapture?.(e.pointerId)
    setDragging(false)
  }, [])

  useEffect(() => {
    const onResize = () => setPos(p => clamp(p.x, p.y))
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [clamp])

  useEffect(() => { setPos(startPos()) }, [startPos])

  const accentHex = currentSong.color || '#22d3ee'

  return (
    <motion.div
      initial={{ opacity: 0, y: 40, scale: 0.92 }}
      animate={{ opacity: 1, y: 0,  scale: 1    }}
      exit={{    opacity: 0, y: 40, scale: 0.92 }}
      transition={{ duration: 0.30, ease: EASE }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      style={{
        position: 'fixed',
        left: pos.x, top: pos.y,
        width: W, height: H,
        zIndex: 300,
        cursor: dragging ? 'grabbing' : 'grab',
        userSelect: 'none',
        background:           'rgba(8,12,20,0.92)',
        backdropFilter:       'blur(28px)',
        WebkitBackdropFilter: 'blur(28px)',
        border:               '1px solid rgba(255,255,255,0.10)',
        borderRadius:         22,
        boxShadow: `0 16px 48px rgba(0,0,0,0.55), 0 0 0 1px ${accentHex}18, inset 0 1px 0 rgba(255,255,255,0.06)`,
        fontFamily: 'var(--font-body)',
        overflow: 'hidden',
        display: 'flex', flexDirection: 'column',
      }}
    >
      {/* Ambient glow */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(ellipse 80% 60% at 10% 50%, ${accentHex}14 0%, transparent 70%)`,
        transition: 'background 0.8s ease',
      }} />

      {/* Main row */}
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center',
        gap: 10, padding: '0 10px 0 12px',
        position: 'relative', zIndex: 1,
      }}>
        {/* Album art */}
        <div onClick={onExpand} title="Open Now Playing" style={{ cursor: 'pointer', flexShrink: 0 }}>
          <AnimatePresence mode="wait">
            <motion.div
              key={currentSong.id}
              initial={{ opacity: 0, scale: 0.80 }}
              animate={{ opacity: 1, scale: 1    }}
              exit={{    opacity: 0, scale: 0.80 }}
              transition={{ duration: 0.20, ease: EASE }}
            >
              <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Track info */}
        <div onClick={onExpand} style={{ flex: 1, minWidth: 0, cursor: 'pointer' }}>
          <AnimatePresence mode="wait">
            <motion.div
              key={`t-${currentSong.id}`}
              initial={{ opacity: 0, y: 4  }}
              animate={{ opacity: 1, y: 0  }}
              exit={{    opacity: 0, y: -4 }}
              transition={{ duration: 0.18 }}
            >
              <p style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {currentSong.title}
              </p>
              <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {currentSong.artist}
              </p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 2, flexShrink: 0 }}>
          <PillBtn title="Previous" onClick={e => { e.stopPropagation(); playPrev() }}>&#9198;</PillBtn>
          <PillBtn primary title={isPlaying ? 'Pause' : 'Play'} onClick={e => { e.stopPropagation(); togglePlay() }}>
            {isPlaying ? '\u23F8' : '\u25B6'}
          </PillBtn>
          <PillBtn title="Next" onClick={e => { e.stopPropagation(); playNext() }}>&#9197;</PillBtn>
        </div>

        {/* Dismiss */}
        <motion.button
          title="Close mini-player"
          onClick={e => { e.stopPropagation(); onClose() }}
          whileHover={{ scale: 1.18, rotate: 90 }}
          whileTap={{ scale: 0.85 }}
          style={{
            position: 'absolute', top: 6, right: 8,
            width: 18, height: 18, borderRadius: '50%',
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.12)',
            color: 'var(--text-muted)', fontSize: 9,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', WebkitTapHighlightColor: 'transparent',
          }}
        >✕</motion.button>
      </div>

      {/* Progress bar */}
      <div style={{ height: 3, background: 'rgba(255,255,255,0.06)', flexShrink: 0, position: 'relative', zIndex: 1 }}>
        <motion.div
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.9, ease: 'linear' }}
          style={{ height: '100%', background: 'var(--accent-grad)', borderRadius: '0 2px 2px 0' }}
        />
      </div>
    </motion.div>
  )
}
