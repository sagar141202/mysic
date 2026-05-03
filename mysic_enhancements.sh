#!/usr/bin/env bash
# ============================================================
#  mysic_enhancements.sh
#  Applies 4 UI improvements to the Mysic project:
#    1. Subtle transitions on cards & buttons
#    2. Active states for selected songs
#    3. Background glow / gradient effects
#    4. Loading states for player actions
#
#  Run from your project root:
#    bash mysic_enhancements.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()  { echo -e "${GREEN}✅  $1${NC}"; }
msg() { echo -e "${CYAN}➜  $1${NC}"; }
warn(){ echo -e "${YELLOW}⚠️   $1${NC}"; }

# ── helpers ─────────────────────────────────────────────────
write_file() {          # write_file <path> <content-heredoc-marker>
  local path="$1"; shift
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}

# ============================================================
# 1. src/components/AnimatedCard.jsx
#    — richer spring + glow shadow on hover
# ============================================================
msg "Patching AnimatedCard.jsx …"
write_file src/components/AnimatedCard.jsx << 'ANIMATEDCARD'
import { motion } from 'framer-motion'

export default function AnimatedCard({
  children,
  className = '',
  style = {},
  delay = 0,
  onClick,
  glowColor = 'rgba(34,211,238,0.18)',
  ...props
}) {
  return (
    <motion.div
      className={className}
      style={{ position: 'relative', ...style }}
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0  }}
      exit={{    opacity: 0, y: -10 }}
      transition={{ duration: 0.32, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      whileHover={{
        scale: 1.022,
        y: -4,
        boxShadow: `0 16px 40px ${glowColor}, 0 4px 16px rgba(0,0,0,0.22)`,
        transition: { duration: 0.22, ease: [0.25, 0.46, 0.45, 0.94] },
      }}
      whileTap={{
        scale: 0.97,
        boxShadow: `0 4px 12px rgba(0,0,0,0.30)`,
        transition: { duration: 0.12 },
      }}
      onClick={onClick}
      {...props}
    >
      {children}
    </motion.div>
  )
}
ANIMATEDCARD
ok "AnimatedCard.jsx"

# ============================================================
# 2. src/components/GlassCard.jsx
#    — smoother transitions + coloured active glow
# ============================================================
msg "Patching GlassCard.jsx …"
write_file src/components/GlassCard.jsx << 'GLASSCARD'
/**
 * GlassCard — reusable glassmorphism container
 *
 * Props:
 *   variant   "default" | "elevated" | "inset"
 *   active    bool   — cyan highlight state
 *   hoverable bool   — enable hover lift
 *   glow      bool   — ambient cyan glow
 *   glowColor string — custom glow colour (default cyan)
 *   radius    number — border radius in px
 *   padding   string — css padding shorthand
 *   onClick   fn     — makes cursor pointer
 *   style     obj    — extra inline styles
 */
export default function GlassCard({
  children,
  style     = {},
  active    = false,
  hoverable = true,
  radius    = 20,
  padding,
  glow      = false,
  glowColor = 'rgba(34,211,238,',   // appended with alpha
  onClick,
  variant   = 'default',
}) {
  const c = glowColor.endsWith('(') ? glowColor : 'rgba(34,211,238,'   // safety

  const variants = {
    default: {
      bg:          'rgba(255,255,255,0.04)',
      bgHover:     'rgba(255,255,255,0.07)',
      border:      'rgba(255,255,255,0.07)',
      borderHover: `${c}0.26)`,
      shadow:      'none',
      shadowHover: `0 12px 32px ${c}0.12), 0 2px 8px rgba(0,0,0,0.18)`,
    },
    elevated: {
      bg:          'rgba(255,255,255,0.06)',
      bgHover:     'rgba(255,255,255,0.09)',
      border:      'rgba(255,255,255,0.10)',
      borderHover: `${c}0.32)`,
      shadow:      '0 4px 20px rgba(0,0,0,0.30), inset 0 1px 0 rgba(255,255,255,0.06)',
      shadowHover: `0 18px 44px ${c}0.14), inset 0 1px 0 ${c}0.08)`,
    },
    inset: {
      bg:          'rgba(0,0,0,0.20)',
      bgHover:     'rgba(0,0,0,0.15)',
      border:      'rgba(255,255,255,0.05)',
      borderHover: `${c}0.18)`,
      shadow:      'inset 0 1px 0 rgba(255,255,255,0.05)',
      shadowHover: `inset 0 1px 0 ${c}0.12)`,
    },
  }

  const v = variants[variant] || variants.default

  const base = {
    background:           active ? `${c}0.09)` : v.bg,
    backdropFilter:       'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    border:               `1px solid ${active ? `${c}0.38)` : v.border}`,
    borderRadius:         radius,
    // ← longer transition so hover feels buttery
    transition:           'background 0.30s ease, border-color 0.30s ease, transform 0.30s ease, box-shadow 0.30s ease',
    boxShadow: active
      ? `0 0 0 1px ${c}0.14), 0 8px 28px ${c}0.16), inset 0 1px 0 ${c}0.10)`
      : glow
      ? `0 0 32px ${c}0.12), inset 0 1px 0 rgba(255,255,255,0.06)`
      : v.shadow,
    cursor:   onClick ? 'pointer' : 'default',
    position: 'relative',
    ...(padding !== undefined ? { padding } : {}),
    ...style,
  }

  const onEnter = e => {
    if (!hoverable || active) return
    e.currentTarget.style.background  = v.bgHover
    e.currentTarget.style.borderColor = v.borderHover
    e.currentTarget.style.transform   = 'translateY(-3px) scale(1.005)'
    e.currentTarget.style.boxShadow   = v.shadowHover
  }

  const onLeave = e => {
    if (!hoverable || active) return
    e.currentTarget.style.background  = v.bg
    e.currentTarget.style.borderColor = v.border
    e.currentTarget.style.transform   = 'translateY(0) scale(1)'
    e.currentTarget.style.boxShadow   = v.shadow
  }

  return (
    <div style={base} onMouseEnter={onEnter} onMouseLeave={onLeave} onClick={onClick}>
      {children}
    </div>
  )
}
GLASSCARD
ok "GlassCard.jsx"

# ============================================================
# 3. src/components/SongList.jsx
#    — richer active state (left accent bar + glow bg) +
#      smooth per-row transitions
# ============================================================
msg "Patching SongList.jsx …"
write_file src/components/SongList.jsx << 'SONGLIST'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]

const listVariants = {
  hidden: {},
  show:   { transition: { staggerChildren: 0.04 } },
}
const rowVariants = {
  hidden: { opacity: 0, x: -12 },
  show:   { opacity: 1, x: 0, transition: { duration: 0.26, ease: EASE } },
}

export default function SongList({ songs, showIndex = true }) {
  const { currentSong, isPlaying, playSong, togglePlay, toggleLike, liked } = usePlayer()

  if (!songs?.length) return (
    <motion.div
      initial={{ opacity: 0 }} animate={{ opacity: 1 }}
      style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}
    >
      No songs found
    </motion.div>
  )

  return (
    <motion.div
      variants={listVariants} initial="hidden" animate="show"
      style={{ display: 'flex', flexDirection: 'column', gap: 2 }}
    >
      {songs.map((song, i) => {
        const active  = currentSong.id === song.id
        const playing = active && isPlaying
        const isLiked = liked.has(song.id)
        const accentCol = song.color || 'rgba(34,211,238,'

        return (
          <motion.div
            key={song.id}
            variants={rowVariants}
            layout
            onClick={() => active ? togglePlay() : playSong(song, songs)}
            whileHover={{ x: 4, transition: { duration: 0.16 } }}
            whileTap={{ scale: 0.985 }}
            style={{
              display: 'grid',
              gridTemplateColumns: showIndex
                ? '28px auto 1fr auto auto'
                : 'auto 1fr auto auto',
              gap: 12,
              padding: '9px 12px 9px 10px',
              borderRadius: 12,
              cursor: 'pointer',
              alignItems: 'center',
              position: 'relative',
              overflow: 'hidden',
              // Active: vivid bg + subtle colour glow
              background: active
                ? `linear-gradient(90deg, ${accentCol}18) 0%, ${accentCol}08) 100%)`
                : 'transparent',
              border: `1px solid ${active ? `${accentCol}28)` : 'transparent'}`,
              boxShadow: active
                ? `inset 3px 0 0 0 ${accentCol}80), 0 4px 18px ${accentCol}12)`
                : 'none',
              transition: 'background 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease',
            }}
            onMouseEnter={e => {
              if (!active) {
                e.currentTarget.style.background  = 'rgba(255,255,255,0.035)'
                e.currentTarget.style.borderColor = 'rgba(255,255,255,0.07)'
              }
            }}
            onMouseLeave={e => {
              if (!active) {
                e.currentTarget.style.background  = 'transparent'
                e.currentTarget.style.borderColor = 'transparent'
              }
            }}
          >
            {showIndex && (
              <span style={{
                fontSize: 11, textAlign: 'center',
                color: active ? 'var(--accent-primary)' : 'var(--text-muted)',
                fontWeight: active ? 600 : 400,
              }}>
                {playing ? (
                  /* animated bars when playing */
                  <span style={{ display: 'inline-flex', alignItems: 'flex-end', gap: 1.5, height: 14 }}>
                    {[1, 0.6, 0.85].map((h, idx) => (
                      <span key={idx} style={{
                        display: 'block', width: 2.5,
                        height: `${h * 14}px`,
                        borderRadius: 2,
                        background: 'var(--accent-primary)',
                        animation: `eq-bar ${0.55 + idx * 0.12}s ease-in-out infinite alternate`,
                        transformOrigin: 'bottom',
                      }} />
                    ))}
                  </span>
                ) : active ? '❚❚' : i + 1}
              </span>
            )}

            <AlbumArt song={song} size="sm" isPlaying={playing} />

            <div style={{ minWidth: 0 }}>
              <p style={{
                fontSize: 13, margin: 0,
                fontWeight: active ? 600 : 400,
                color: active ? 'var(--accent-primary)' : 'var(--text-primary)',
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                transition: 'color 0.2s',
              }}>
                {song.title}
              </p>
              <p style={{
                fontSize: 11, margin: 0,
                color: active ? 'var(--text-secondary)' : 'var(--text-muted)',
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                transition: 'color 0.2s',
              }}>
                {song.artist}
              </p>
            </div>

            <motion.button
              onClick={e => { e.stopPropagation(); toggleLike(song.id, song) }}
              whileHover={{ scale: 1.28 }}
              whileTap={{ scale: 0.75 }}
              animate={isLiked ? { scale: [1, 1.35, 1] } : {}}
              style={{
                background: 'none', border: 'none', cursor: 'pointer',
                fontSize: 14,
                color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
                filter: isLiked ? 'drop-shadow(0 0 5px rgba(34,211,238,0.55))' : 'none',
                transition: 'color 0.2s, filter 0.2s',
                padding: '0 4px',
              }}
            >
              {isLiked ? '♥' : '♡'}
            </motion.button>

            <span style={{
              fontSize: 11, color: 'var(--text-muted)',
              minWidth: 32, textAlign: 'right',
              fontVariantNumeric: 'tabular-nums',
            }}>
              {formatTime(song.duration)}
            </span>
          </motion.div>
        )
      })}
    </motion.div>
  )
}
SONGLIST
ok "SongList.jsx"

# ============================================================
# 4. src/components/Player.jsx
#    — loading spinner on play button + glow bg strip +
#      smoother scrubber transition
# ============================================================
msg "Patching Player.jsx …"
write_file src/components/Player.jsx << 'PLAYER'
import { useRef, useCallback, useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]

/* ── Scrubber ─────────────────────────────────────────────── */
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
  const [hovered, setHovered] = useState(false)
  return (
    <div
      onMouseDown={onMouseDown}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        width, height: hovered ? 6 : 4,
        borderRadius: 4,
        background: 'rgba(255,255,255,0.08)',
        cursor: 'pointer',
        position: 'relative',
        flexShrink: 0,
        transition: 'height 0.18s ease',
      }}
    >
      <div style={{
        width: `${pct}%`, height: '100%', borderRadius: 4,
        background: accent,
        position: 'relative',
        transition: 'width 0.9s linear',
        boxShadow: hovered ? '0 0 8px rgba(34,211,238,0.45)' : 'none',
      }}>
        <motion.div
          animate={{ opacity: hovered ? 1 : 0, scale: hovered ? 1 : 0.6 }}
          transition={{ duration: 0.15 }}
          style={{
            position: 'absolute', right: -6, top: '50%',
            transform: 'translateY(-50%)',
            width: 12, height: 12, borderRadius: '50%',
            background: 'white',
            boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.25)',
          }}
        />
      </div>
    </div>
  )
}

/* ── Control Button ────────────────────────────────────────── */
function Btn({ children, onClick, size = 32, primary = false, title, loading = false, disabled = false }) {
  return (
    <motion.button
      title={title}
      onClick={disabled ? undefined : onClick}
      whileHover={disabled ? {} : { scale: primary ? 1.08 : 1.15 }}
      whileTap={disabled   ? {} : { scale: primary ? 0.93 : 0.85 }}
      style={{
        width: size, height: size, borderRadius: '50%', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)',
        border: primary ? 'none' : '1px solid rgba(255,255,255,0.09)',
        color: primary ? '#08121f' : 'var(--text-secondary)',
        fontSize: primary ? 15 : 13, cursor: disabled ? 'default' : 'pointer',
        boxShadow: primary ? '0 4px 16px rgba(34,211,238,0.38)' : 'none',
        opacity: disabled ? 0.4 : 1,
        transition: 'opacity 0.2s',
        position: 'relative', overflow: 'hidden',
      }}
    >
      <AnimatePresence mode="wait">
        {loading ? (
          <motion.span
            key="spinner"
            initial={{ opacity: 0, scale: 0.6, rotate: -90 }}
            animate={{ opacity: 1, scale: 1, rotate: 0 }}
            exit={{ opacity: 0, scale: 0.6 }}
            transition={{ duration: 0.2 }}
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}
          >
            <LoadingRing size={primary ? 16 : 12} color={primary ? '#08121f' : 'var(--accent-primary)'} />
          </motion.span>
        ) : (
          <motion.span
            key="icon"
            initial={{ opacity: 0, scale: 0.7, rotate: 20 }}
            animate={{ opacity: 1, scale: 1, rotate: 0 }}
            exit={{ opacity: 0, scale: 0.7, rotate: -20 }}
            transition={{ duration: 0.18 }}
          >
            {children}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  )
}

/* ── SVG loading ring ─────────────────────────────────────── */
function LoadingRing({ size = 14, color = 'white' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      style={{ animation: 'spin 0.75s linear infinite' }}>
      <circle cx="12" cy="12" r="9" stroke={color} strokeWidth="2.5" strokeLinecap="round"
        strokeDasharray="42 14" />
    </svg>
  )
}

/* ── Mobile strip ─────────────────────────────────────────── */
function MobilePlayer({ onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, togglePlay, playNext } = usePlayer()
  const [actionLoading, setActionLoading] = useState(false)

  const handlePlay = async (e) => {
    e.stopPropagation()
    setActionLoading(true)
    await togglePlay()
    setTimeout(() => setActionLoading(false), 600)
  }

  return (
    <div style={{ fontFamily: 'var(--font-body)', background: 'rgba(8,12,20,0.95)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.06)', position: 'relative', overflow: 'hidden' }}>
      {/* Ambient glow strip from current song colour */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(ellipse 60% 100% at 50% 150%, ${currentSong.color || '#22d3ee'}22 0%, transparent 70%)`,
        transition: 'background 0.8s ease',
      }} />

      <div style={{ height: 2, background: 'rgba(255,255,255,0.06)' }}>
        <motion.div
          style={{ height: '100%', background: 'var(--accent-grad)' }}
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.9, ease: 'linear' }}
        />
      </div>

      <div onClick={onNowPlayingClick}
        style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px', cursor: 'pointer', position: 'relative', zIndex: 1 }}>
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id}
            initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }}
            transition={{ duration: 0.25, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>

        <AnimatePresence mode="wait">
          <motion.div key={`title-${currentSong.id}`}
            initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }}
            transition={{ duration: 0.2 }} style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.title}</p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>

        <Btn primary size={34} onClick={handlePlay} title={isPlaying ? 'Pause' : 'Play'} loading={actionLoading}>
          {isPlaying ? '\u23F8' : '\u25B6'}
        </Btn>
        <Btn size={30} onClick={e => { e.stopPropagation(); playNext() }} title="Next">&#9197;</Btn>
      </div>
    </div>
  )
}

/* ── Desktop Player ───────────────────────────────────────── */
export default function Player({ mobile = false, onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, volume, togglePlay, playNext, playPrev, seek, setVolume, toggleLike, liked } = usePlayer()
  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)

  // Track loading state per action
  const [playLoading, setPlayLoading]     = useState(false)
  const [prevLoading, setPrevLoading]     = useState(false)
  const [nextLoading, setNextLoading]     = useState(false)

  // Auto-clear loading after 800ms (fallback)
  const withLoad = (setter, fn) => async () => {
    setter(true)
    try { await fn() } finally { setTimeout(() => setter(false), 700) }
  }

  if (mobile) return <MobilePlayer onNowPlayingClick={onNowPlayingClick} />

  return (
    <div style={{
      height: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
      alignItems: 'center', padding: '0 22px',
      background: 'rgba(8,12,20,0.92)', backdropFilter: 'blur(30px)',
      borderTop: '1px solid rgba(255,255,255,0.06)',
      fontFamily: 'var(--font-body)', position: 'relative', overflow: 'hidden',
    }}>
      {/* Background ambient glow from current song */}
      <motion.div
        key={currentSong.id}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1.2 }}
        style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          background: `radial-gradient(ellipse 40% 200% at 50% 120%, ${currentSong.color || '#22d3ee'}18 0%, transparent 70%)`,
        }}
      />

      {/* Left: track info */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 1 }}>
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id}
            initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }}
            transition={{ duration: 0.25, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>

        <AnimatePresence mode="wait">
          <motion.div key={`title-${currentSong.id}`}
            initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }}
            transition={{ duration: 0.2, ease: EASE }} style={{ minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 140 }}>{currentSong.title}</p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>

        <motion.button onClick={() => toggleLike(currentSong.id, currentSong)}
          whileHover={{ scale: 1.25 }} whileTap={{ scale: 0.75 }}
          style={{ background: 'none', border: 'none', flexShrink: 0, fontSize: 16, cursor: 'pointer', color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none', transition: 'color 0.2s, filter 0.2s' }}
        >{isLiked ? '\u2665' : '\u2661'}</motion.button>
      </div>

      {/* Centre: controls + scrubber */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, position: 'relative', zIndex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <Btn title="Shuffle">&#8700;</Btn>
          <Btn title="Previous" onClick={withLoad(setPrevLoading, playPrev)} loading={prevLoading}>&#9198;</Btn>
          <Btn primary size={38} title={isPlaying ? 'Pause' : 'Play'} loading={playLoading}
            onClick={withLoad(setPlayLoading, togglePlay)}>
            {isPlaying ? '\u23F8' : '\u25B6'}
          </Btn>
          <Btn title="Next" onClick={withLoad(setNextLoading, playNext)} loading={nextLoading}>&#9197;</Btn>
          <Btn title="Repeat">&#8635;</Btn>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', maxWidth: 340 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSec)}</span>
          <Scrubber pct={progress} onSeek={seek} />
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSong.duration)}</span>
        </div>
      </div>

      {/* Right: volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, justifyContent: 'flex-end', position: 'relative', zIndex: 1 }}>
        {['\u2630', '\u229E'].map(icon => (
          <motion.button key={icon} whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.9 }}
            style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s' }}
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
PLAYER
ok "Player.jsx"

# ============================================================
# 5. Inject CSS keyframes into index.css  (or App.css)
#    — eq-bar  : equaliser bounce for playing state
#    — spin    : loading ring rotation
# ============================================================
msg "Injecting CSS keyframes …"

# Detect which global CSS file exists
CSS_FILE=""
for f in src/index.css src/App.css src/styles/global.css; do
  [ -f "$f" ] && { CSS_FILE="$f"; break; }
done

KEYFRAMES='
/* ── mysic_enhancements keyframes ── */
@keyframes eq-bar {
  from { transform: scaleY(0.35); }
  to   { transform: scaleY(1); }
}
@keyframes spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position:  200% 0; }
}
'

if [ -n "$CSS_FILE" ]; then
  # Only inject if not already there
  if ! grep -q "eq-bar" "$CSS_FILE"; then
    printf '%s' "$KEYFRAMES" >> "$CSS_FILE"
    ok "Keyframes injected into $CSS_FILE"
  else
    warn "Keyframes already present in $CSS_FILE — skipped"
  fi
else
  warn "No global CSS file found. Paste the following manually into your CSS:"
  echo "$KEYFRAMES"
fi

# ============================================================
# Done
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅  All Mysic enhancements applied!            ║${NC}"
echo -e "${GREEN}╟──────────────────────────────────────────────────╢${NC}"
echo -e "${GREEN}║  1. AnimatedCard  — spring lift + colour glow    ║${NC}"
echo -e "${GREEN}║  2. GlassCard     — buttery hover transitions    ║${NC}"
echo -e "${GREEN}║  3. SongList      — active bar + EQ bars         ║${NC}"
echo -e "${GREEN}║  4. Player        — loading rings + ambient glow ║${NC}"
echo -e "${GREEN}║  5. CSS           — eq-bar, spin, shimmer        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Run  ${CYAN}npm run dev${NC}  and enjoy 🎵"
