/**
 * LyricsPanel — full-height lyrics view that replaces Up Next
 * when the user taps the ♪ button in NowPlaying header.
 *
 * Props:
 *   currentSec  number   — current playback position in seconds
 *   song        object   — currentSong from usePlayer
 *   isPlaying   bool
 */
import { useEffect, useRef, useState, useCallback } from 'react'
import { motion, AnimatePresence }                   from 'framer-motion'
import { fetchLyrics }                               from '../utils/fetchLyrics'

const EASE = [0.25, 0.46, 0.45, 0.94]

export default function LyricsPanel({ currentSec, song, isPlaying }) {
  const [state,   setState]   = useState('idle')   // idle | loading | ready | error
  const [data,    setData]    = useState(null)      // { lines, synced, notFound }
  const [songId,  setSongId]  = useState(null)
  const scrollRef             = useRef(null)
  const lineRefs              = useRef([])

  /* ── Fetch whenever song changes ── */
  useEffect(() => {
    if (!song?.id || song.id === songId) return
    setSongId(song.id)
    setState('loading')
    setData(null)
    fetchLyrics(song).then(result => {
      setData(result)
      setState(result.notFound ? 'error' : 'ready')
    })
  }, [song?.id])

  /* ── Auto-scroll active line into centre view ── */
  const activeIdx = useCallback(() => {
    if (!data?.lines?.length || !data.synced) return -1
    let idx = -1
    for (let i = 0; i < data.lines.length; i++) {
      if (data.lines[i].time <= currentSec) idx = i
      else break
    }
    return idx
  }, [data, currentSec])

  const active = activeIdx()

  useEffect(() => {
    if (active < 0) return
    const el = lineRefs.current[active]
    const container = scrollRef.current
    if (!el || !container) return
    const elTop    = el.offsetTop
    const elHeight = el.offsetHeight
    const target   = elTop - container.clientHeight / 2 + elHeight / 2
    container.scrollTo({ top: target, behavior: 'smooth' })
  }, [active])

  /* ── Accent colour from song ── */
  const accent = song?.color || '#22d3ee'

  /* ── States ── */
  if (state === 'loading') return (
    <motion.div
      initial={{ opacity: 0 }} animate={{ opacity: 1 }}
      style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14, padding: '30px 0' }}
    >
      {/* Pulsing music note */}
      <motion.div
        animate={{ scale: [1, 1.18, 1], opacity: [0.5, 1, 0.5] }}
        transition={{ duration: 1.6, repeat: Infinity, ease: 'easeInOut' }}
        style={{ fontSize: 32, color: accent }}
      >♪</motion.div>
      <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0, letterSpacing: '0.08em' }}>
        Finding lyrics…
      </p>
    </motion.div>
  )

  if (state === 'error' || data?.notFound) return (
    <motion.div
      initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
      style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '30px 0', textAlign: 'center' }}
    >
      <span style={{ fontSize: 28, opacity: 0.35 }}>♩</span>
      <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: 0 }}>
        No lyrics found
      </p>
      <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.2)', margin: 0 }}>
        {song?.title}
      </p>
    </motion.div>
  )

  if (state !== 'ready' || !data) return null

  const { lines, synced } = data

  return (
    <motion.div
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      transition={{ duration: 0.28 }}
      style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, position: 'relative' }}
    >
      {/* Sync badge */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10, flexShrink: 0 }}>
        <p style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.12em', textTransform: 'uppercase', margin: 0 }}>
          Lyrics
        </p>
        <span style={{
          fontSize: 10, padding: '2px 8px', borderRadius: 20,
          background: synced ? `${accent}22` : 'rgba(255,255,255,0.06)',
          color:      synced ? accent        : 'var(--text-muted)',
          border:     `1px solid ${synced ? `${accent}44` : 'rgba(255,255,255,0.08)'}`,
          letterSpacing: '0.06em',
        }}>
          {synced ? '⏱ synced' : 'plain text'}
        </span>
      </div>

      {/* Fade mask top */}
      <div style={{
        position: 'absolute', top: 32, left: 0, right: 0, height: 48,
        background: 'linear-gradient(to bottom, rgba(8,12,20,0.78) 0%, transparent 100%)',
        pointerEvents: 'none', zIndex: 2,
      }} />

      {/* Scrollable lyrics */}
      <div
        ref={scrollRef}
        style={{
          flex: 1, overflowY: 'auto', overflowX: 'hidden',
          overscrollBehavior: 'contain',
          WebkitOverflowScrolling: 'touch',
          /* hide scrollbar */
          scrollbarWidth: 'none',
          msOverflowStyle: 'none',
          paddingTop: 20,
          paddingBottom: 60,
          position: 'relative',
        }}
      >
        <style>{`
          .lyrics-scroll::-webkit-scrollbar { display: none; }
          @keyframes lyric-pulse {
            0%, 100% { opacity: 0.9; }
            50%       { opacity: 1;   }
          }
        `}</style>

        <div className="lyrics-scroll" style={{ padding: '0 4px' }}>
          {lines.map((line, i) => {
            const isActive = synced && i === active
            const isPast   = synced && i < active
            const isFuture = synced && i > active

            /* opacity layers */
            const opacity = isActive ? 1
              : isPast   ? Math.max(0.18, 1 - (active - i) * 0.14)
              : isFuture ? Math.max(0.20, 1 - (i - active) * 0.12)
              : 0.55     /* plain text */

            /* font size: active swells */
            const fontSize = isActive ? 17 : 14

            return (
              <motion.p
                key={i}
                ref={el => { lineRefs.current[i] = el }}
                animate={{
                  opacity,
                  scale:  isActive ? 1.04 : 1,
                  color:  isActive ? accent : '#ffffff',
                  filter: isActive ? `drop-shadow(0 0 12px ${accent}88)` : 'none',
                }}
                transition={{ duration: 0.38, ease: EASE }}
                style={{
                  fontSize,
                  fontFamily:   'var(--font-display)',
                  fontWeight:   isActive ? 700 : isPast ? 400 : 500,
                  lineHeight:   1.55,
                  margin:       '0 0 6px',
                  padding:      '5px 0',
                  cursor:       synced ? 'default' : 'default',
                  textAlign:    'left',
                  letterSpacing: isActive ? '-0.01em' : '0',
                  transformOrigin: 'left center',
                  /* keep text from wrapping too wide */
                  maxWidth: '100%',
                  wordBreak: 'break-word',
                  /* active line: subtle left accent bar */
                  borderLeft:  isActive ? `3px solid ${accent}` : '3px solid transparent',
                  paddingLeft: 10,
                  transition:  'border-color 0.3s ease, padding 0.2s ease',
                  /* active glow animation */
                  animation: isActive && isPlaying ? 'lyric-pulse 2s ease-in-out infinite' : 'none',
                }}
              >
                {line.text}
              </motion.p>
            )
          })}
        </div>
      </div>

      {/* Fade mask bottom */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 64,
        background: 'linear-gradient(to top, rgba(8,12,20,0.95) 0%, transparent 100%)',
        pointerEvents: 'none', zIndex: 2,
      }} />
    </motion.div>
  )
}
