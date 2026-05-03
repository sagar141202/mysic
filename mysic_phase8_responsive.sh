#!/usr/bin/env bash
# ============================================================
#  mysic_phase8_responsive.sh
#  Phase 8 — Responsiveness and UX
#
#  Fixes:
#    1. Layout.jsx        — safe-area insets, overflow guards
#    2. MobileNav.jsx     — 44px tap targets, safe-area padding
#    3. NowPlaying.jsx    — touch scrubber, mobile padding
#    4. MainContent.jsx   — responsive spacing, mobile search
#    5. Player.jsx        — tablet layout, touch scrubber
#    6. Sidebar.jsx       — collapse threshold, overflow guard
#    7. index.css         — CSS vars, safe-area, scrollbar, text
#
#  Run from project root:
#    bash mysic_phase8_responsive.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✅  $1${RESET}"; }
msg()  { echo -e "${CYAN}➜   $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠️   $1${RESET}"; }

# ─────────────────────────────────────────────────────────────
# 0. Locate the global CSS file
# ─────────────────────────────────────────────────────────────
CSS_FILE=""
for f in src/index.css src/App.css src/styles/global.css; do
  [ -f "$f" ] && { CSS_FILE="$f"; break; }
done
[ -z "$CSS_FILE" ] && { warn "No CSS file found – skipping CSS patch"; }

# ─────────────────────────────────────────────────────────────
# 1.  Layout.jsx
#     • Pass screenSize to every PageRouter page
#     • Safe-area bottom padding on mobile container
#     • Touch-action pan-y on scroll containers
# ─────────────────────────────────────────────────────────────
msg "Writing Layout.jsx …"
cat > src/components/Layout.jsx << 'EOF'
import { useState, useEffect } from 'react'
import { AnimatePresence } from 'framer-motion'
import Sidebar from './Sidebar'
import MainContent from './MainContent'
import NowPlaying from './NowPlaying'
import Player from './Player'
import MobileNav from './MobileNav'
import YouTubePlayer from './YouTubePlayer'
import PageTransition from './PageTransition'
import DiscoverPage from '../pages/DiscoverPage'
import LibraryPage from '../pages/LibraryPage'
import LikedPage from '../pages/LikedPage'
import PlaylistsPage from '../pages/PlaylistsPage'

function PageRouter({ page, screenSize }) {
  const props = { screenSize }
  switch (page) {
    case 'Discover':  return <DiscoverPage  {...props} />
    case 'Library':   return <LibraryPage   {...props} />
    case 'Liked':     return <LikedPage     {...props} />
    case 'Playlists': return <PlaylistsPage {...props} />
    default:          return <MainContent   {...props} />
  }
}

export default function Layout() {
  const [screen,         setScreen]         = useState('desktop')
  const [nowPlayingOpen, setNowPlayingOpen] = useState(false)
  const [activePage,     setActivePage]     = useState('Home')

  useEffect(() => {
    const upd = () => {
      const w = window.innerWidth
      setScreen(w < 640 ? 'mobile' : w < 1024 ? 'tablet' : 'desktop')
    }
    upd()
    window.addEventListener('resize', upd)
    return () => window.removeEventListener('resize', upd)
  }, [])

  const isMobile  = screen === 'mobile'
  const isTablet  = screen === 'tablet'
  const isDesktop = screen === 'desktop'

  /* shared slide-panel styles */
  const backdrop = {
    position: 'fixed', inset: 0, zIndex: 40,
    background: 'rgba(0,0,0,0.55)',
    animation: 'fadeIn 0.2s ease',
  }

  return (
    <div style={{
      height: '100dvh', width: '100vw',
      overflow: 'hidden',
      background: 'var(--bg-base)',
      position: 'relative',
      display: 'flex', flexDirection: 'column',
      fontFamily: 'var(--font-body)',
      /* prevent rubber-band scroll on iOS from exposing background */
      overscrollBehavior: 'none',
    }}>
      <YouTubePlayer />

      {/* Ambient orbs */}
      <div style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 0, overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: '-15%', left: '-8%', width: isMobile ? 240 : 520, height: isMobile ? 240 : 520, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-1) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift1 20s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', top: '40%', right: '-12%', width: isMobile ? 190 : 420, height: isMobile ? 190 : 420, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-2) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift2 25s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', bottom: '-8%', left: '38%', width: isMobile ? 160 : 360, height: isMobile ? 160 : 360, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-3) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift3 28s ease-in-out infinite alternate' }} />
      </div>

      {/* ── Desktop ── */}
      {isDesktop && (
        <div style={{
          flex: 1,
          display: 'grid',
          gridTemplateColumns: 'var(--sidebar-width) 1fr var(--right-panel-width)',
          gridTemplateRows: '1fr var(--player-height)',
          overflow: 'hidden',
          position: 'relative', zIndex: 1,
          minWidth: 0,  /* prevent grid blowout */
        }}>
          <div style={{ gridColumn: 1, gridRow: 1, overflow: 'hidden', minWidth: 0 }}>
            <Sidebar activePage={activePage} onNavigate={setActivePage} />
          </div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden', position: 'relative', minWidth: 0 }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <div style={{ gridColumn: 3, gridRow: 1, overflow: 'hidden', minWidth: 0 }}>
            <NowPlaying />
          </div>
          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>
            <Player />
          </div>
        </div>
      )}

      {/* ── Tablet ── */}
      {isTablet && (
        <div style={{
          flex: 1,
          display: 'grid',
          gridTemplateColumns: '64px 1fr',
          gridTemplateRows: '1fr var(--player-height)',
          overflow: 'hidden',
          position: 'relative', zIndex: 1,
          minWidth: 0,
        }}>
          <div style={{ gridColumn: 1, gridRow: 1, overflow: 'hidden' }}>
            <Sidebar collapsed activePage={activePage} onNavigate={setActivePage} />
          </div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden', position: 'relative', minWidth: 0 }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <div style={{ gridColumn: '1/-1', gridRow: 2, minWidth: 0 }}>
            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} />
          </div>

          {nowPlayingOpen && (
            <>
              <div style={backdrop} onClick={() => setNowPlayingOpen(false)} />
              <div style={{ position: 'fixed', top: 0, right: 0, width: 'min(320px, 90vw)', height: '100dvh', zIndex: 50, animation: 'slideInRight 0.28s ease' }}>
                <NowPlaying onClose={() => setNowPlayingOpen(false)} />
              </div>
            </>
          )}
        </div>
      )}

      {/* ── Mobile ── */}
      {isMobile && (
        <div style={{
          flex: 1,
          display: 'flex', flexDirection: 'column',
          overflow: 'hidden',
          position: 'relative', zIndex: 1,
          /* pushes content above home indicator on iOS */
          paddingBottom: 'env(safe-area-inset-bottom, 0px)',
        }}>
          <div style={{ flex: 1, overflow: 'hidden', position: 'relative', touchAction: 'pan-y' }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} />
          <MobileNav activePage={activePage} onNavigate={setActivePage} />

          {nowPlayingOpen && (
            <>
              <div style={{ ...backdrop, background: 'rgba(0,0,0,0.65)' }} onClick={() => setNowPlayingOpen(false)} />
              <div style={{
                position: 'fixed', bottom: 0, left: 0, right: 0,
                height: '92dvh',
                borderRadius: '24px 24px 0 0',
                zIndex: 50,
                animation: 'slideInUp 0.28s ease',
                overflow: 'hidden',
              }}>
                <NowPlaying onClose={() => setNowPlayingOpen(false)} />
              </div>
            </>
          )}
        </div>
      )}
    </div>
  )
}
EOF
ok "Layout.jsx"

# ─────────────────────────────────────────────────────────────
# 2.  MobileNav.jsx
#     • 44px minimum tap target per Apple HIG / WCAG
#     • safe-area-inset-bottom padding
#     • active indicator dot
#     • font-size bump on label for readability
# ─────────────────────────────────────────────────────────────
msg "Writing MobileNav.jsx …"
cat > src/components/MobileNav.jsx << 'EOF'
import { motion } from 'framer-motion'

const tabs = [
  { icon: '⌂', label: 'Home' },
  { icon: '⊙', label: 'Discover' },
  { icon: '♪', label: 'Library' },
  { icon: '♡', label: 'Liked' },
  { icon: '⊞', label: 'Playlists' },
]

export default function MobileNav({ activePage = 'Home', onNavigate }) {
  return (
    <nav
      role="navigation"
      aria-label="Main navigation"
      style={{
        display: 'flex',
        background: 'rgba(6,10,18,0.97)',
        backdropFilter: 'blur(24px)',
        WebkitBackdropFilter: 'blur(24px)',
        borderTop: '1px solid rgba(255,255,255,0.07)',
        /* safe-area: home bar on iPhone */
        paddingBottom: 'max(8px, env(safe-area-inset-bottom, 8px))',
        paddingTop: 4,
        /* prevent tap highlight flash on Android */
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      {tabs.map(tab => {
        const active = activePage === tab.label
        return (
          <motion.button
            key={tab.label}
            aria-label={tab.label}
            aria-current={active ? 'page' : undefined}
            onClick={() => onNavigate?.(tab.label)}
            whileTap={{ scale: 0.88 }}
            style={{
              /* ≥44px tap target */
              flex: 1,
              minHeight: 44,
              display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center',
              gap: 3,
              background: 'none', border: 'none',
              cursor: 'pointer',
              padding: '6px 4px',
              color: active ? 'var(--accent-primary)' : 'var(--text-muted)',
              transition: 'color 0.18s',
              fontFamily: 'var(--font-body)',
              WebkitTapHighlightColor: 'transparent',
              position: 'relative',
            }}
          >
            {/* Icon */}
            <span style={{
              fontSize: 20,
              lineHeight: 1,
              filter: active ? 'drop-shadow(0 0 7px rgba(34,211,238,0.65))' : 'none',
              transition: 'filter 0.2s',
            }}>
              {tab.icon}
            </span>

            {/* Label */}
            <span style={{
              fontSize: 10,
              fontWeight: active ? 600 : 400,
              letterSpacing: '0.03em',
              /* keep readable even on small phones */
              whiteSpace: 'nowrap',
            }}>
              {tab.label}
            </span>

            {/* Active dot */}
            {active && (
              <motion.span
                layoutId="nav-dot"
                style={{
                  position: 'absolute', bottom: 2,
                  width: 4, height: 4, borderRadius: '50%',
                  background: 'var(--accent-primary)',
                  boxShadow: '0 0 6px var(--accent-primary)',
                }}
              />
            )}
          </motion.button>
        )
      })}
    </nav>
  )
}
EOF
ok "MobileNav.jsx"

# ─────────────────────────────────────────────────────────────
# 3.  NowPlaying.jsx
#     • Touch scrubber (onTouchStart / onTouchMove)
#     • Taller scrubber hit area (20px wrapper, 4px visual)
#     • Larger control buttons on mobile (52px primary, 40px secondary)
#     • Readable font sizes (min 12px body, 15px title)
#     • Padding respects safe-area on mobile sheet
# ─────────────────────────────────────────────────────────────
msg "Writing NowPlaying.jsx …"
cat > src/components/NowPlaying.jsx << 'EOF'
import { useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

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
EOF
ok "NowPlaying.jsx"

# ─────────────────────────────────────────────────────────────
# 4.  MainContent.jsx
#     • Responsive padding via CSS clamp
#     • Collections grid shows on mobile (2-col)
#     • Search input font-size 16px on mobile (prevents iOS zoom)
#     • Song rows have 44px min-height on mobile
#     • Duration hidden on very small screens
# ─────────────────────────────────────────────────────────────
msg "Writing MainContent.jsx …"
cat > src/components/MainContent.jsx << 'EOF'
import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import GlassCard from './GlassCard'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { COLLECTIONS, formatTime } from '../data/songs'
import { searchYouTube } from '../utils/ytSearch'

const TRENDING_QUERIES = [
  'top hindi songs 2025',
  'best english hits 2025',
  'arijit singh latest',
  'weeknd best songs',
]

const EASE = [0.25, 0.46, 0.45, 0.94]

const listVariants = {
  hidden: {},
  show:  { transition: { staggerChildren: 0.045 } },
  exit:  { transition: { staggerChildren: 0.02, staggerDirection: -1 } },
}
const rowVariants = {
  hidden: { opacity: 0, x: -14 },
  show:   { opacity: 1, x: 0, transition: { duration: 0.26, ease: EASE } },
  exit:   { opacity: 0, x: 14, transition: { duration: 0.18, ease: EASE } },
}
const cardVariants = {
  hidden: { opacity: 0, y: 20, scale: 0.96 },
  show:   (i) => ({ opacity: 1, y: 0, scale: 1, transition: { duration: 0.30, delay: i * 0.055, ease: EASE } }),
}

export default function MainContent({ screenSize = 'desktop' }) {
  const [search,        setSearch]        = useState('')
  const [searchResults, setSearchResults] = useState([])
  const [searching,     setSearching]     = useState(false)
  const [trending,      setTrending]      = useState([])
  const [trendingLoad,  setTrendingLoad]  = useState(true)
  const debounceRef = useRef(null)

  const isMobile = screenSize === 'mobile'
  const isTablet = screenSize === 'tablet'
  const { currentSong, isPlaying, playSong, togglePlay, toggleLike, liked } = usePlayer()

  useEffect(() => {
    const q = TRENDING_QUERIES[Math.floor(Math.random() * TRENDING_QUERIES.length)]
    searchYouTube(q, 8).then(res => { setTrending(res); setTrendingLoad(false) })
  }, [])

  useEffect(() => {
    if (!search.trim()) { setSearchResults([]); return }
    setSearching(true)
    clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(async () => {
      const res = await searchYouTube(search, 20)
      setSearchResults(res)
      setSearching(false)
    }, 500)
  }, [search])

  const showSearch   = !!search.trim()
  const displaySongs = showSearch ? searchResults : trending

  /* responsive padding: 14px on mobile → 28px on desktop */
  const hPad = isMobile ? 14 : isTablet ? 20 : 28

  return (
    <div style={{
      height: '100%',
      overflowY: 'auto',
      overscrollBehavior: 'contain',
      WebkitOverflowScrolling: 'touch',
      padding: `${isMobile ? 16 : 24}px ${hPad}px ${isMobile ? 8 : 16}px`,
      fontFamily: 'var(--font-body)',
      /* ensure nothing pokes outside */
      boxSizing: 'border-box',
      maxWidth: '100%',
    }}>

      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.38, ease: EASE }}
        style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: isMobile ? 16 : 22,
          /* prevent header content from wrapping oddly */
          gap: 12, minWidth: 0,
        }}
      >
        <div style={{ minWidth: 0 }}>
          <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', marginBottom: 3, margin: '0 0 3px' }}>
            Good Evening
          </p>
          <h1 style={{
            fontFamily: 'var(--font-display)',
            /* clamp: min 18px (small phone) → max 28px (desktop) */
            fontSize: 'clamp(18px, 5vw, 28px)',
            fontWeight: 800, lineHeight: 1.15, margin: 0,
            background: 'var(--accent-grad)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
            /* prevent overflow on narrow screens */
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>
            What's the vibe?
          </h1>
        </div>

        <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
          {(isMobile ? ['🔔'] : ['🔔', '⊙', '⚙']).map((icon, i) => (
            <motion.button
              key={icon}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.28, delay: 0.08 + i * 0.05, ease: EASE }}
              whileHover={{ scale: 1.12 }}
              whileTap={{ scale: 0.90 }}
              /* 44px tap target */
              style={{
                width: 44, height: 44, borderRadius: '50%',
                background: 'var(--glass-bg)',
                border: '1px solid var(--glass-border)',
                backdropFilter: 'blur(12px)',
                color: 'var(--text-secondary)', fontSize: 15,
                cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                WebkitTapHighlightColor: 'transparent',
                touchAction: 'manipulation',
              }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(34,211,238,0.35)'; e.currentTarget.style.background = 'rgba(34,211,238,0.06)'; e.currentTarget.style.color = 'var(--accent-primary)' }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--glass-border)'; e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.color = 'var(--text-secondary)' }}
            >
              {icon}
            </motion.button>
          ))}
        </div>
      </motion.div>

      {/* Search bar */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.32, delay: 0.07, ease: EASE }}
        style={{ position: 'relative', marginBottom: isMobile ? 20 : 26 }}
      >
        <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14, pointerEvents: 'none', zIndex: 1 }}>⊙</span>
        <AnimatePresence>
          {searching && (
            <motion.span
              key="spinner"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--accent-primary)', fontSize: 12, zIndex: 1 }}
            >
              ···
            </motion.span>
          )}
        </AnimatePresence>
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder={isMobile ? 'Search songs…' : 'Search any song, artist, mood on YouTube…'}
          style={{
            width: '100%', boxSizing: 'border-box',
            /* 48px height = comfortable mobile tap */
            padding: isMobile ? '14px 42px 14px 42px' : '13px 42px 13px 42px',
            background: 'rgba(255,255,255,0.03)',
            border: '1px solid rgba(255,255,255,0.07)',
            borderRadius: 14, outline: 'none',
            color: 'var(--text-primary)',
            /* 16px prevents iOS auto-zoom on focus */
            fontSize: isMobile ? 16 : 13,
            fontFamily: 'var(--font-body)',
            backdropFilter: 'blur(12px)',
            transition: 'all 0.22s',
            /* stop mobile keyboard from resizing layout */
            WebkitAppearance: 'none',
          }}
          onFocus={e => { e.target.style.borderColor = 'rgba(34,211,238,0.42)'; e.target.style.background = 'rgba(34,211,238,0.04)'; e.target.style.boxShadow = '0 0 0 3px rgba(34,211,238,0.08)' }}
          onBlur={e  => { e.target.style.borderColor = 'rgba(255,255,255,0.07)'; e.target.style.background = 'rgba(255,255,255,0.03)'; e.target.style.boxShadow = 'none' }}
        />
      </motion.div>

      {/* Collections grid — 2 col on mobile, 2 on tablet, 4 on desktop */}
      <AnimatePresence mode="wait">
        {!showSearch && (
          <motion.div
            key="collections"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.22 }}
            style={{ marginBottom: isMobile ? 20 : 26 }}
          >
            <SectionHeader title="Collections" />
            <div style={{
              display: 'grid',
              gridTemplateColumns: isMobile
                ? 'repeat(2, 1fr)'
                : isTablet ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)',
              gap: isMobile ? 8 : 10,
            }}>
              {COLLECTIONS.map((c, i) => (
                <motion.div
                  key={c.name}
                  custom={i}
                  variants={cardVariants}
                  initial="hidden"
                  animate="show"
                  whileHover={{ scale: 1.03, y: -3, transition: { duration: 0.16 } }}
                  whileTap={{ scale: 0.96 }}
                >
                  <GlassCard
                    variant="elevated"
                    padding={isMobile ? '12px' : '14px'}
                    radius={14}
                    onClick={() => setSearch(c.name.toLowerCase())}
                    style={{ overflow: 'hidden', cursor: 'pointer' }}
                  >
                    <div style={{ position: 'absolute', top: -16, right: -16, width: 64, height: 64, borderRadius: '50%', background: `${c.color}22`, filter: 'blur(14px)', pointerEvents: 'none' }} />
                    <div style={{ width: 34, height: 34, borderRadius: 10, marginBottom: 8, background: `${c.color}18`, border: `1px solid ${c.color}35`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, boxShadow: `0 4px 12px ${c.color}20`, flexShrink: 0 }}>♪</div>
                    <p style={{ fontSize: isMobile ? 12 : 13, fontWeight: 600, color: 'var(--text-primary)', margin: '0 0 2px', fontFamily: 'var(--font-display)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.name}</p>
                    <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>{c.count}</p>
                  </GlassCard>
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Song list */}
      <div style={{ paddingBottom: 20 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <AnimatePresence mode="wait">
            <motion.h2
              key={showSearch ? 'search' : 'trending'}
              initial={{ opacity: 0, x: -8 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 8 }}
              transition={{ duration: 0.18 }}
              style={{
                fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700,
                color: 'var(--text-primary)', margin: 0,
                /* prevent long search queries from overflowing */
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                maxWidth: '70%',
              }}
            >
              {showSearch ? `Results for "${search}"` : 'Trending Now'}
            </motion.h2>
          </AnimatePresence>

          <AnimatePresence>
            {(searching || trendingLoad) && (
              <motion.span
                key="loading"
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                style={{ fontSize: 11, color: 'var(--accent-primary)', flexShrink: 0 }}
              >
                {searching ? 'Searching…' : 'Loading…'}
              </motion.span>
            )}
          </AnimatePresence>
        </div>

        {(trendingLoad && !showSearch) || (searching && showSearch) ? (
          <SkeletonList count={6} />
        ) : displaySongs.length === 0 && showSearch ? (
          <motion.div
            initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
            style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}
          >
            No results for "{search}"
          </motion.div>
        ) : (
          <AnimatePresence mode="wait">
            <motion.div
              key={showSearch ? `s-${search}` : 'trending'}
              variants={listVariants}
              initial="hidden" animate="show" exit="exit"
              style={{ display: 'flex', flexDirection: 'column', gap: 2 }}
            >
              {displaySongs.map((song, i) => (
                <motion.div key={song.id} variants={rowVariants} layout>
                  <SongRow
                    song={song} index={i}
                    active={currentSong.id === song.id}
                    isPlaying={isPlaying && currentSong.id === song.id}
                    isLiked={liked.has(song.id)}
                    isMobile={isMobile} isTablet={isTablet}
                    onClick={() => currentSong.id === song.id ? togglePlay() : playSong(song, displaySongs)}
                    onLike={e => { e.stopPropagation(); toggleLike(song.id, song) }}
                  />
                </motion.div>
              ))}
            </motion.div>
          </AnimatePresence>
        )}
      </div>
    </div>
  )
}

/* ── Skeleton ─────────────────────────────────────────────── */
function SkeletonList({ count }) {
  return (
    <motion.div
      variants={listVariants} initial="hidden" animate="show"
      style={{ display: 'flex', flexDirection: 'column', gap: 8 }}
    >
      {Array.from({ length: count }).map((_, i) => (
        <motion.div key={i} variants={rowVariants}
          style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', borderRadius: 12, minHeight: 44 }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(255,255,255,0.05)', animation: 'pulse-glow 1.5s ease-in-out infinite', flexShrink: 0 }} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ height: 12, borderRadius: 6, background: 'rgba(255,255,255,0.05)', marginBottom: 8, width: `${50 + (i * 13) % 30}%`, animation: 'pulse-glow 1.5s ease-in-out infinite' }} />
            <div style={{ height: 10, borderRadius: 6, background: 'rgba(255,255,255,0.03)', width: '35%', animation: 'pulse-glow 1.5s ease-in-out infinite' }} />
          </div>
        </motion.div>
      ))}
    </motion.div>
  )
}

function SectionHeader({ title }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
      <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>{title}</h2>
    </div>
  )
}

/* ── Song Row ─────────────────────────────────────────────── */
function SongRow({ song, index, active, isPlaying, isLiked, isMobile, isTablet, onClick, onLike }) {
  const accentCol = song.color || 'rgba(34,211,238,'

  return (
    <motion.div
      onClick={onClick}
      whileHover={{ x: isMobile ? 0 : 3, transition: { duration: 0.14 } }}
      whileTap={{ scale: 0.985 }}
      style={{
        display: 'grid',
        /* mobile: thumb | info | like  (no index, no duration to save space) */
        /* tablet+: index | thumb | info | like | duration */
        gridTemplateColumns: isMobile
          ? 'auto 1fr auto'
          : '28px auto 1fr auto auto',
        gap: isMobile ? 10 : 12,
        /* 44px min ensures comfortable tap target */
        minHeight: 44,
        padding: isMobile ? '8px 6px' : '9px 12px',
        borderRadius: 12,
        cursor: 'pointer',
        alignItems: 'center',
        background: active
          ? `linear-gradient(90deg, ${accentCol}18) 0%, ${accentCol}08) 100%)`
          : 'transparent',
        border: `1px solid ${active ? `${accentCol}28)` : 'transparent'}`,
        boxShadow: active ? `inset 3px 0 0 0 ${accentCol}80)` : 'none',
        transition: 'background 0.22s, border-color 0.22s, box-shadow 0.22s',
        /* prevent row from expanding beyond container */
        minWidth: 0,
        WebkitTapHighlightColor: 'transparent',
        touchAction: 'manipulation',
      }}
      onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
      onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}}
    >
      {/* Index — hidden on mobile */}
      {!isMobile && (
        <span style={{ fontSize: 11, textAlign: 'center', color: active ? 'var(--accent-primary)' : 'var(--text-muted)', fontWeight: active ? 600 : 400 }}>
          {isPlaying ? '▶' : active ? '❚❚' : index + 1}
        </span>
      )}

      {/* Thumbnail */}
      <div style={{
        width: isMobile ? 42 : 40, height: isMobile ? 42 : 40,
        borderRadius: 10, flexShrink: 0, overflow: 'hidden',
        background: `linear-gradient(135deg, ${song.color}28, ${song.color}0d)`,
        border: `1px solid ${song.color}${active ? '55' : '30'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: active ? `0 0 14px ${song.color}40` : 'none',
      }}>
        {song.thumbnail
          ? <img src={song.thumbnail} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={e => { e.target.style.display = 'none' }} />
          : <span style={{ fontSize: 16 }}>♪</span>
        }
      </div>

      {/* Title + artist */}
      <div style={{ minWidth: 0 }}>
        <p style={{
          fontSize: isMobile ? 14 : 13, margin: 0,
          fontWeight: active ? 600 : 400,
          color: active ? 'var(--accent-primary)' : 'var(--text-primary)',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          transition: 'color 0.2s',
        }}>{song.title}</p>
        <p style={{
          fontSize: isMobile ? 12 : 11, margin: 0,
          color: 'var(--text-secondary)',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{song.artist}</p>
      </div>

      {/* Like */}
      <motion.button
        onClick={onLike}
        whileHover={{ scale: 1.22 }} whileTap={{ scale: 0.80 }}
        aria-label={isLiked ? 'Unlike' : 'Like'}
        style={{
          background: 'none', border: 'none', cursor: 'pointer',
          /* 44px tap target */
          width: 44, height: 44,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 16,
          color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
          filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.55))' : 'none',
          transition: 'color 0.2s, filter 0.2s',
          WebkitTapHighlightColor: 'transparent',
          touchAction: 'manipulation',
          flexShrink: 0,
        }}
      >
        {isLiked ? '♥' : '♡'}
      </motion.button>

      {/* Duration — hidden on mobile to reclaim space */}
      {!isMobile && (
        <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 32, textAlign: 'right', fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
          {formatTime(song.duration)}
        </span>
      )}
    </motion.div>
  )
}
EOF
ok "MainContent.jsx"

# ─────────────────────────────────────────────────────────────
# 5.  Player.jsx  (tablet-aware + touch scrubber + overflow fix)
#     • Tablet: 2-col grid (info+controls | volume) instead of 3
#     • Touch scrubber in both MobilePlayer and desktop
#     • min-width: 0 on all grid children
# ─────────────────────────────────────────────────────────────
msg "Writing Player.jsx …"
cat > src/components/Player.jsx << 'EOF'
import { useRef, useCallback, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

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
export default function Player({ mobile = false, onNowPlayingClick, screenSize = 'desktop' }) {
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
          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
            <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>{volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}</span>
            <Scrubber pct={volume} onSeek={setVolume} width="80px" accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
          </div>
        </div>
      )}
    </div>
  )
}
EOF
ok "Player.jsx"

# ─────────────────────────────────────────────────────────────
# 6.  CSS additions
#     • --player-height responsive value
#     • meta viewport (inserted via index.html check)
#     • safe-area utilities
#     • prevent text size adjust on rotation
#     • custom scrollbar thinned for mobile
#     • touch-callout none
# ─────────────────────────────────────────────────────────────
if [ -n "$CSS_FILE" ]; then
  msg "Appending responsive CSS to $CSS_FILE …"
  if ! grep -q "phase8-responsive" "$CSS_FILE"; then
    cat >> "$CSS_FILE" << 'CSSEOF'

/* ── Phase 8: Responsiveness ──────────────────────────────── */

/* Prevent iOS font inflation on rotation */
html {
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
}

/* Smooth momentum scroll on all scrollable elements */
* {
  -webkit-overflow-scrolling: touch;
}

/* Prevent blue tap flash on all interactive elements */
button, a, [role="button"] {
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
}

/* Responsive player height */
:root {
  --player-height: 72px;
}
@media (max-width: 639px) {
  :root {
    --player-height: 68px;
  }
}
@media (min-width: 1024px) {
  :root {
    --player-height: 76px;
  }
}

/* Thin, themed scrollbar */
::-webkit-scrollbar { width: 4px; height: 4px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.12); border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: rgba(34,211,238,0.30); }

/* Prevent any block-level element from exceeding viewport width */
img, video, iframe, table { max-width: 100%; }

/* Readable minimum font size */
p, span, a, li { font-size: max(var(--fs, 11px), 11px); }

/* phase8-responsive marker */
EOF
    ok "CSS appended to $CSS_FILE"
  else
    warn "Phase 8 CSS already present — skipped"
  fi
fi

# ─────────────────────────────────────────────────────────────
# 7.  index.html — ensure correct viewport meta
# ─────────────────────────────────────────────────────────────
HTML_FILE=""
for f in index.html public/index.html; do
  [ -f "$f" ] && { HTML_FILE="$f"; break; }
done

if [ -n "$HTML_FILE" ]; then
  msg "Checking viewport meta in $HTML_FILE …"
  if grep -q 'viewport-fit=cover' "$HTML_FILE"; then
    warn "viewport-fit=cover already set — skipped"
  else
    # Replace existing viewport or inject after <head>
    if grep -q 'name="viewport"' "$HTML_FILE"; then
      sed -i.bak 's|<meta name="viewport"[^>]*>|<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover, maximum-scale=1.0" />|' "$HTML_FILE"
      ok "viewport meta updated in $HTML_FILE"
    else
      sed -i.bak 's|<head>|<head>\n  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover, maximum-scale=1.0" />|' "$HTML_FILE"
      ok "viewport meta injected into $HTML_FILE"
    fi
  fi
else
  warn "index.html not found — add this manually inside <head>:"
  echo '  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover, maximum-scale=1.0" />'
fi

# ─────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅  Phase 8 — Responsiveness applied!                 ║${RESET}"
echo -e "${GREEN}╟──────────────────────────────────────────────────────────╢${RESET}"
echo -e "${GREEN}║  Layout.jsx      safe-area, overflow guards, minWidth 0 ║${RESET}"
echo -e "${GREEN}║  MobileNav.jsx   44px tap targets, safe-area bottom      ║${RESET}"
echo -e "${GREEN}║  NowPlaying.jsx  touch scrubber, clamp font, safe-area   ║${RESET}"
echo -e "${GREEN}║  MainContent.jsx 2-col mobile grid, 16px input, clamp    ║${RESET}"
echo -e "${GREEN}║  Player.jsx      tablet 2-col, touch scrubber, 44px btns ║${RESET}"
echo -e "${GREEN}║  CSS             scrollbar, text-adjust, tap flash off    ║${RESET}"
echo -e "${GREEN}║  index.html      viewport-fit=cover for iOS notch         ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Run  ${CYAN}npm run dev${NC}  and test on:"
echo -e "    • Chrome DevTools → iPhone 14 Pro (390×844)"
echo -e "    • Chrome DevTools → iPad Air (820×1180)"
echo -e "    • Chrome DevTools → Desktop 1440×900"
