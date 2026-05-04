#!/usr/bin/env bash
# =============================================================================
#  fix-player-toolbar.sh — Mysic · Clean Desktop Right Toolbar
#
#  Run from the ROOT of your mysic repo:
#    bash fix-player-toolbar.sh
#
#  What this fixes (exact line references to the original Player.jsx)
#  ──────────────────────────────────────────────────────────────────
#  BUG 1  Lines 283-289  — two dead icon buttons (☰ ⊞) with no handlers,
#                          mapped from a hardcoded array. Removed.
#  BUG 2  Lines 291-308  — first mini-player button (&#x229F;). Kept as base.
#  BUG 3  Lines 309-330  — DUPLICATE mini-player button added by a failed
#                          patch script whose target string didn't match.
#                          Removed entirely.
#  BUG 4  Lines 197-199  — useSleepTimer() and [showTimer, timerMins] state
#                          were declared but the SleepTimerMenu JSX was never
#                          rendered anywhere. Now rendered.
#  BUG 5  Line 182        — onAmbient prop accepted but never called. Now
#                          wired to the ✦ ambient button in the toolbar.
#
#  RESULT: right toolbar = [ 🌙 sleep ] [ ✦ ambient ] [ ⊟ mini ] [ 🔊 vol ]
# =============================================================================
set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

log()  { echo -e "${CYAN}[mysic]${RESET} $1"; }
ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }
warn() { echo -e "${YELLOW}  ⚠${RESET} $1"; }
die()  { echo -e "${RED}  ✗ $1${RESET}"; exit 1; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║   Mysic — Clean Desktop Right Toolbar                    ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

[ -f "package.json" ] || die "Run from the repo root (package.json not found)"
log "Repo root confirmed"

# ── Locate Player.jsx ─────────────────────────────────────────────────────────
PLAYER=""
for p in src/components/Player.jsx src/components/Player.js components/Player.jsx; do
  [ -f "$p" ] && PLAYER="$p" && break
done
[ -z "$PLAYER" ] && warn "Player.jsx not found — will create at src/components/Player.jsx" \
  && mkdir -p src/components && PLAYER="src/components/Player.jsx"
[ -f "$PLAYER" ] && cp "$PLAYER" "${PLAYER}.bak" && ok "Backed up → ${PLAYER}.bak"

log "Writing clean ${PLAYER} …"

# ── Write complete Player.jsx ─────────────────────────────────────────────────
cat > "$PLAYER" << 'PLAYEREOF'
/**
 * Player.jsx — Mysic bottom player bar
 *
 * Desktop right toolbar (fixed):
 *   [ 🌙 sleep-timer ] [ ✦ ambient ] [ ⊟ mini-player ] [ 🔊 volume ]
 *
 * Fixes applied vs original:
 *   • Removed the two dead icon buttons (☰ ⊞) that had no click handlers.
 *   • Removed the duplicate ⊟ mini-player button (lines 309-330 in original).
 *   • SleepTimerMenu is now actually rendered (was declared but never shown).
 *   • onAmbient prop is now wired to the ✦ button (was accepted but never called).
 *   • Sleep-timer button turns cyan + shows remaining time when active.
 *   • Ambient button turns cyan when mode is active (via prop).
 */

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
  const onTouchMove = useCallback(e => {
    if (!dragging.current) return
    e.preventDefault()
    onSeek(calc(e.touches[0].clientX, e.currentTarget))
  }, [onSeek])
  const onTouchEnd = useCallback(() => { dragging.current = false }, [])

  return (
    <div
      onMouseDown={onMouseDown}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onTouchStart={onTouchStart}
      onTouchMove={onTouchMove}
      onTouchEnd={onTouchEnd}
      style={{
        width, height: 24,
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

/* ── Playback button ────────────────────────────────────── */
function Btn({ children, onClick, size = 32, primary = false, title, loading = false }) {
  return (
    <motion.button
      title={title} onClick={onClick}
      whileHover={{ scale: primary ? 1.08 : 1.14 }}
      whileTap={{ scale: primary ? 0.92 : 0.84 }}
      style={{
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
          <motion.span key="spin"
            initial={{ opacity: 0, scale: 0.6 }} animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }} transition={{ duration: 0.15 }}>
            <svg width={primary ? 16 : 12} height={primary ? 16 : 12}
              viewBox="0 0 24 24" fill="none"
              style={{ animation: 'spin 0.75s linear infinite' }}>
              <circle cx="12" cy="12" r="9"
                stroke={primary ? '#08121f' : 'var(--accent-primary)'}
                strokeWidth="2.5" strokeLinecap="round" strokeDasharray="42 14" />
            </svg>
          </motion.span>
        ) : (
          <motion.span key="icon"
            initial={{ opacity: 0, scale: 0.7, rotate: 20 }}
            animate={{ opacity: 1, scale: 1, rotate: 0 }}
            exit={{ opacity: 0, scale: 0.7, rotate: -20 }}
            transition={{ duration: 0.16 }}>
            {children}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  )
}

/* ── Toolbar icon button (right-side utility buttons) ───── */
function ToolBtn({ children, onClick, title, active = false, activeColor = 'var(--accent-primary)' }) {
  return (
    <motion.button
      title={title}
      onClick={onClick}
      whileHover={{ scale: 1.15 }}
      whileTap={{ scale: 0.88 }}
      style={{
        background: active ? 'rgba(34,211,238,0.08)' : 'none',
        border: active ? '1px solid rgba(34,211,238,0.25)' : '1px solid transparent',
        borderRadius: 9,
        color: active ? activeColor : 'var(--text-muted)',
        fontSize: 15, cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        width: 34, height: 34,
        transition: 'color 0.18s, background 0.18s, border-color 0.18s',
        flexShrink: 0,
        WebkitTapHighlightColor: 'transparent',
        fontFamily: 'var(--font-body)',
      }}
      onMouseEnter={e => {
        if (!active) e.currentTarget.style.color = 'var(--text-primary)'
      }}
      onMouseLeave={e => {
        if (!active) e.currentTarget.style.color = 'var(--text-muted)'
      }}
    >
      {children}
    </motion.button>
  )
}

/* ── Formats remaining sleep-timer seconds for button label ─ */
function fmtRemaining(secs) {
  if (secs === null) return null
  const m = Math.floor(secs / 60)
  const s = secs % 60
  return m > 0 ? `${m}m` : `${s}s`
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
    <div style={{
      fontFamily: 'var(--font-body)',
      background: 'rgba(8,12,20,0.96)',
      backdropFilter: 'blur(20px)',
      borderTop: '1px solid rgba(255,255,255,0.07)',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* Ambient glow */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(ellipse 60% 100% at 50% 140%, ${currentSong.color || '#22d3ee'}20 0%, transparent 70%)`,
        transition: 'background 0.8s ease',
      }} />

      {/* Progress strip */}
      <div style={{ height: 2, background: 'rgba(255,255,255,0.06)' }}>
        <motion.div
          style={{ height: '100%', background: 'var(--accent-grad)' }}
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.9, ease: 'linear' }}
        />
      </div>

      <div
        onClick={onNowPlayingClick}
        style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '10px 16px', minHeight: 64,
          cursor: 'pointer', position: 'relative', zIndex: 1,
          WebkitTapHighlightColor: 'transparent',
        }}
      >
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id}
            initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.22, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>

        <AnimatePresence mode="wait">
          <motion.div key={`t-${currentSong.id}`}
            initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -5 }} transition={{ duration: 0.18 }}
            style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontSize: 14, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {currentSong.title}
            </p>
            <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {currentSong.artist}
            </p>
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
export default function Player({
  mobile = false,
  onNowPlayingClick,
  onMiniPlayer,
  onAmbient,          /* ← now actually wired to the ✦ button */
  screenSize = 'desktop',
  ambientActive = false,
}) {
  const {
    currentSong, isPlaying, progress, volume,
    togglePlay, playNext, playPrev, seek, setVolume,
    toggleLike, liked,
    shuffle, repeat, toggleShuffle, toggleRepeat,
  } = usePlayer()

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

  /* Sleep timer */
  const { remaining, initialMins, start: startTimer, cancel: cancelTimer } = useSleepTimer()
  const [showTimer, setShowTimer] = useState(false)
  const timerActive = remaining !== null

  if (mobile) return <MobilePlayer onNowPlayingClick={onNowPlayingClick} />

  return (
    <div style={{
      height: '100%',
      display: 'grid',
      gridTemplateColumns: isTablet ? '1fr auto' : '1fr 1fr 1fr',
      alignItems: 'center',
      padding: `0 ${isTablet ? 14 : 22}px`,
      background: 'rgba(8,12,20,0.93)',
      backdropFilter: 'blur(32px)',
      borderTop: '1px solid rgba(255,255,255,0.07)',
      fontFamily: 'var(--font-body)',
      position: 'relative', overflow: 'hidden',
      minWidth: 0,
    }}>
      {/* Ambient glow */}
      <motion.div
        key={currentSong.id}
        initial={{ opacity: 0 }} animate={{ opacity: 1 }}
        transition={{ duration: 1.2 }}
        style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          background: `radial-gradient(ellipse 40% 200% at 50% 120%, ${currentSong.color || '#22d3ee'}16 0%, transparent 70%)`,
        }}
      />

      {/* ── Left: track info ── */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, minWidth: 0, position: 'relative', zIndex: 1 }}>
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id}
            initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.22, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>

        <AnimatePresence mode="wait">
          <motion.div key={`t-${currentSong.id}`}
            initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -5 }} transition={{ duration: 0.18, ease: EASE }}
            style={{ minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: isTablet ? 110 : 150 }}>
              {currentSong.title}
            </p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: isTablet ? 110 : 150 }}>
              {currentSong.artist}
            </p>
          </motion.div>
        </AnimatePresence>

        <motion.button
          onClick={() => toggleLike(currentSong.id, currentSong)}
          whileHover={{ scale: 1.25 }} whileTap={{ scale: 0.75 }}
          style={{
            background: 'none', border: 'none', flexShrink: 0,
            width: 44, height: 44,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 16, cursor: 'pointer',
            color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
            filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none',
            transition: 'color 0.2s, filter 0.2s',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          {isLiked ? '\u2665' : '\u2661'}
        </motion.button>
      </div>

      {/* ── Centre: playback controls + scrubber (desktop only) ── */}
      {!isTablet && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, position: 'relative', zIndex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {/* Shuffle — lights up when active */}
            <motion.button
              title={shuffle ? 'Shuffle on' : 'Shuffle off'}
              onClick={toggleShuffle}
              whileHover={{ scale: 1.14 }} whileTap={{ scale: 0.84 }}
              style={{
                width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: shuffle ? 'rgba(34,211,238,0.10)' : 'rgba(255,255,255,0.05)',
                border: shuffle ? '1px solid rgba(34,211,238,0.30)' : '1px solid rgba(255,255,255,0.09)',
                color: shuffle ? 'var(--accent-primary)' : 'var(--text-secondary)',
                fontSize: 13, cursor: 'pointer',
                transition: 'all 0.2s ease',
                WebkitTapHighlightColor: 'transparent',
              }}
            >&#8700;</motion.button>

            <Btn title="Previous" onClick={withLoad(setPrevLoad, playPrev)} loading={prevLoad}>&#9198;</Btn>

            <Btn primary size={38} title={isPlaying ? 'Pause' : 'Play'}
              loading={playLoad} onClick={withLoad(setPlayLoad, togglePlay)}>
              {isPlaying ? '\u23F8' : '\u25B6'}
            </Btn>

            <Btn title="Next" onClick={withLoad(setNextLoad, playNext)} loading={nextLoad}>&#9197;</Btn>

            {/* Repeat — cycles off → all → one */}
            <motion.button
              title={repeat === false ? 'Repeat off' : repeat === 'all' ? 'Repeat all' : 'Repeat one'}
              onClick={toggleRepeat}
              whileHover={{ scale: 1.14 }} whileTap={{ scale: 0.84 }}
              style={{
                width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: repeat ? 'rgba(34,211,238,0.10)' : 'rgba(255,255,255,0.05)',
                border: repeat ? '1px solid rgba(34,211,238,0.30)' : '1px solid rgba(255,255,255,0.09)',
                color: repeat ? 'var(--accent-primary)' : 'var(--text-secondary)',
                fontSize: 13, cursor: 'pointer',
                transition: 'all 0.2s ease',
                WebkitTapHighlightColor: 'transparent',
                position: 'relative',
              }}
            >
              &#8635;
              {/* "1" badge when repeat-one */}
              {repeat === 'one' && (
                <span style={{
                  position: 'absolute', top: 6, right: 6,
                  width: 10, height: 10, borderRadius: '50%',
                  background: 'var(--accent-primary)',
                  fontSize: 7, fontWeight: 800,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#08121f', lineHeight: 1,
                }}>1</span>
              )}
            </motion.button>
          </div>

          {/* Scrubber + timestamps */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', maxWidth: 340 }}>
            <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, textAlign: 'right', fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
              {formatTime(currentSec)}
            </span>
            <Scrubber pct={progress} onSeek={seek} />
            <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
              {formatTime(currentSong.duration)}
            </span>
          </div>
        </div>
      )}

      {/* ── Tablet compact controls ── */}
      {isTablet && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, position: 'relative', zIndex: 1, paddingLeft: 10 }}>
          <Btn title="Previous" size={28} onClick={withLoad(setPrevLoad, playPrev)} loading={prevLoad}>&#9198;</Btn>
          <Btn primary size={34} title={isPlaying ? 'Pause' : 'Play'}
            loading={playLoad} onClick={withLoad(setPlayLoad, togglePlay)}>
            {isPlaying ? '\u23F8' : '\u25B6'}
          </Btn>
          <Btn title="Next" size={28} onClick={withLoad(setNextLoad, playNext)} loading={nextLoad}>&#9197;</Btn>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginLeft: 6 }}>
            <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>
              {volume === 0 ? '\uD83D\uDD07' : '\uD83D\uDD0A'}
            </span>
            <Scrubber pct={volume} onSeek={setVolume} width="70px"
              accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
          </div>
        </div>
      )}

      {/* ── Right: utility toolbar + volume (desktop only) ── */}
      {!isTablet && (
        <div style={{
          display: 'flex', alignItems: 'center', gap: 4,
          justifyContent: 'flex-end',
          position: 'relative', zIndex: 1, minWidth: 0,
        }}>

          {/* 🌙 Sleep timer — shows remaining time when active */}
          <div style={{ position: 'relative' }}>
            <ToolBtn
              title={timerActive ? `Sleep timer: ${fmtRemaining(remaining)} left` : 'Sleep timer'}
              active={timerActive}
              onClick={() => setShowTimer(v => !v)}
            >
              {timerActive ? (
                <span style={{ fontSize: 11, fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>
                  {fmtRemaining(remaining)}
                </span>
              ) : '🌙'}
            </ToolBtn>

            {/* SleepTimerMenu popover */}
            <AnimatePresence>
              {showTimer && (
                <SleepTimerMenu
                  remaining={remaining}
                  initialMins={initialMins ?? 30}
                  onStart={mins => startTimer(mins)}
                  onCancel={cancelTimer}
                  onClose={() => setShowTimer(false)}
                />
              )}
            </AnimatePresence>
          </div>

          {/* ✦ Ambient / cinema mode */}
          {onAmbient && (
            <ToolBtn
              title={ambientActive ? 'Exit ambient mode' : 'Ambient mode'}
              active={ambientActive}
              onClick={onAmbient}
            >
              ✦
            </ToolBtn>
          )}

          {/* ⊟ Mini-player pop-out — ONE button, no duplicate */}
          {onMiniPlayer && (
            <ToolBtn title="Pop out mini-player" onClick={onMiniPlayer}>
              ⊟
            </ToolBtn>
          )}

          {/* Volume */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginLeft: 4 }}>
            <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>
              {volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}
            </span>
            <Scrubber pct={volume} onSeek={setVolume} width="80px"
              accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
          </div>

        </div>
      )}

    </div>
  )
}
PLAYEREOF
ok "${PLAYER} written"

# ── Patch Layout.jsx to pass ambientActive prop ───────────────────────────────
log "Locating Layout.jsx …"
LAYOUT=""
for p in src/components/Layout.jsx src/components/Layout.js components/Layout.jsx; do
  [ -f "$p" ] && LAYOUT="$p" && break
done

if [ -z "$LAYOUT" ]; then
  warn "Layout.jsx not found — skipping ambientActive prop patch (add it manually)"
else
  cp "$LAYOUT" "${LAYOUT}.bak"
  ok "Backed up → ${LAYOUT}.bak"

  # Check if ambientActive is already there
  if grep -q "ambientActive" "$LAYOUT"; then
    ok "ambientActive already present in Layout.jsx — no patch needed"
  else
    # Patch: add ambientActive={showAmbient} to every <Player ... onAmbient= line
    # Use perl for reliable multi-line-safe replacement
    perl -i -pe '
      s|(onAmbient=\{[^}]+\})|$1 ambientActive={showAmbient}|g
    ' "$LAYOUT"
    ok "Patched Layout.jsx — added ambientActive={showAmbient} to <Player>"
  fi
fi

# ── Verify useSleepTimer exports initialMins ─────────────────────────────────
log "Checking useSleepTimer for initialMins export …"
SLEEP_HOOK=""
for p in src/hooks/useSleepTimer.js src/hooks/useSleepTimer.jsx hooks/useSleepTimer.js; do
  [ -f "$p" ] && SLEEP_HOOK="$p" && break
done

if [ -z "$SLEEP_HOOK" ]; then
  warn "useSleepTimer not found — Player.jsx uses { remaining, initialMins, start, cancel }"
  warn "Make sure your hook exports those four values."
else
  if grep -q "initialMins" "$SLEEP_HOOK"; then
    ok "useSleepTimer already exports initialMins"
  else
    warn "useSleepTimer does NOT export initialMins."
    warn "SleepTimerMenu needs it for the countdown ring percentage."
    warn "Add 'initialMins' to your useSleepTimer return value:"
    echo ""
    echo "  // inside useSleepTimer:"
    echo "  const [initialMins, setInitialMins] = useState(null)"
    echo "  // set it when startTimer(mins) is called"
    echo "  // then export: return { remaining, initialMins, start, cancel }"
    echo ""
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║  Done! Files written / patched:                          ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
printf "${GREEN}║  %-56s║${RESET}\n" "${PLAYER}  (backup: .bak)"
[ -n "$LAYOUT" ] && printf "${GREEN}║  %-56s║${RESET}\n" "${LAYOUT}  (patched, backup: .bak)"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  What changed in the right toolbar                       ║${RESET}"
echo -e "${GREEN}║  ✓ Removed dead ☰ ⊞ icon buttons (no handlers)         ║${RESET}"
echo -e "${GREEN}║  ✓ Removed duplicate ⊟ mini-player button               ║${RESET}"
echo -e "${GREEN}║  ✓ SleepTimerMenu now rendered (was declared, never shown)║${RESET}"
echo -e "${GREEN}║  ✓ 🌙 shows remaining time badge when timer is active    ║${RESET}"
echo -e "${GREEN}║  ✓ ✦ ambient button wired to onAmbient prop             ║${RESET}"
echo -e "${GREEN}║  ✓ Shuffle + Repeat buttons wired to toggleShuffle/Repeat║${RESET}"
echo -e "${GREEN}║  ✓ Repeat badge shows '1' dot in repeat-one mode        ║${RESET}"
echo -e "${GREEN}║  New toolbar order: 🌙 | ✦ | ⊟ | 🔊 vol               ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Next steps                                              ║${RESET}"
echo -e "${GREEN}║  1. npm run dev — verify toolbar looks correct           ║${RESET}"
echo -e "${GREEN}║  2. Click 🌙 — SleepTimerMenu should appear above player ║${RESET}"
echo -e "${GREEN}║  3. Click ✦ — AmbientMode overlay should open           ║${RESET}"
echo -e "${GREEN}║  4. Click ⊟ — MiniPlayer pill should float over UI      ║${RESET}"
echo -e "${GREEN}║  5. git add -A && git commit -m 'fix: player toolbar'    ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
