#!/usr/bin/env bash
# =============================================================================
#  fix-library-page.sh — Mysic · Real-time Dynamic Library Page
#
#  Run from the ROOT of your mysic repo:
#    bash fix-library-page.sh
#
#  PROBLEM
#  ───────
#  LibraryPage reads from the static SONGS array in data/songs.js — a
#  hardcoded list that never changes. It has no connection to:
#    • What the user has actually searched and played
#    • The recentlyPlayed array persisted in localStorage + usePlayer context
#    • The live queue
#
#  FIX — three live sections driven by actual user activity:
#
#  1. Recently Played  — reads recentlyPlayed[] from usePlayer context.
#     Already persisted to localStorage by fix-progress-tracking.sh.
#     Updates the instant any song starts playing.
#
#  2. Inline Search    — live YouTube results as you type (480ms debounce).
#     Plays directly into the queue on click. Same proxy as Home.
#
#  3. Search History   — last 10 unique queries, stored as chips in
#     localStorage key 'mysic_search_history'. Click to re-run. Clear all.
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
echo -e "${CYAN}║   Mysic — Real-time Dynamic Library Page                 ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

[ -f "package.json" ] || die "Run from the repo root (package.json not found)"
log "Repo root confirmed"

# ── Locate LibraryPage ────────────────────────────────────────────────────────
LIBRARY=""
for p in src/pages/LibraryPage.jsx src/pages/LibraryPage.js pages/LibraryPage.jsx; do
  [ -f "$p" ] && LIBRARY="$p" && break
done
if [ -z "$LIBRARY" ]; then
  warn "LibraryPage.jsx not found — creating at src/pages/LibraryPage.jsx"
  mkdir -p src/pages
  LIBRARY="src/pages/LibraryPage.jsx"
else
  cp "$LIBRARY" "${LIBRARY}.bak"
  ok "Backed up → ${LIBRARY}.bak"
fi

log "Writing ${LIBRARY} …"
cat > "$LIBRARY" << 'LIBRARYEOF'
/**
 * LibraryPage.jsx — Real-time dynamic music library
 *
 * Three live sections, all driven by actual user activity:
 *
 *   1. Recently Played — from usePlayer.recentlyPlayed (context + localStorage)
 *   2. Inline Search   — live YouTube results as you type
 *   3. Search History  — last 10 queries, persisted in localStorage
 *
 * No static SONGS import. No hardcoded data. Everything reflects what the
 * user has actually searched, played, or liked in this or prior sessions.
 */

import { useState, useEffect, useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import { searchYouTube } from '../utils/ytSearch'
import AlbumArt from '../components/AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]
const HISTORY_KEY = 'mysic_search_history'
const MAX_HISTORY  = 10

/* ── Search history helpers ─────────────────────────────── */
function loadHistory() {
  try { return JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]') }
  catch { return [] }
}
function pushHistory(query, prev) {
  const t = query.trim()
  if (!t) return prev
  const next = [t, ...prev.filter(q => q !== t)].slice(0, MAX_HISTORY)
  try { localStorage.setItem(HISTORY_KEY, JSON.stringify(next)) } catch {}
  return next
}

/* ── Section header ─────────────────────────────────────── */
function SectionHeader({ title, count, action, actionLabel }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>
          {title}
        </h2>
        {count != null && (
          <span style={{
            fontSize: 10, padding: '2px 7px', borderRadius: 20,
            background: 'rgba(34,211,238,0.10)', border: '1px solid rgba(34,211,238,0.20)',
            color: 'var(--accent-primary)', fontVariantNumeric: 'tabular-nums',
          }}>{count}</span>
        )}
      </div>
      {action && (
        <button onClick={action} style={{
          background: 'none', border: 'none', cursor: 'pointer',
          fontSize: 11, color: 'var(--text-muted)', padding: '4px 8px', borderRadius: 6,
          transition: 'color 0.15s', fontFamily: 'var(--font-body)',
        }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
        >{actionLabel}</button>
      )}
    </div>
  )
}

/* ── Skeleton row ───────────────────────────────────────── */
function SkeletonRow() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 10px', borderRadius: 12, minHeight: 58 }}>
      <div style={{ width: 42, height: 42, borderRadius: 10, flexShrink: 0, background: 'rgba(255,255,255,0.05)', animation: 'pulse-glow 1.5s ease-in-out infinite' }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ height: 12, borderRadius: 6, background: 'rgba(255,255,255,0.05)', width: '55%', marginBottom: 8, animation: 'pulse-glow 1.5s ease-in-out infinite' }} />
        <div style={{ height: 10, borderRadius: 6, background: 'rgba(255,255,255,0.03)', width: '35%', animation: 'pulse-glow 1.5s ease-in-out infinite' }} />
      </div>
    </div>
  )
}

/* ── Compact song row ───────────────────────────────────── */
function CompactRow({ song, active, isPlaying, isLiked, onClick, onLike, isMobile }) {
  const accent = song.color || '#22d3ee'
  return (
    <motion.div
      onClick={onClick}
      whileHover={{ x: 3, transition: { duration: 0.14 } }}
      whileTap={{ scale: 0.985 }}
      style={{
        display: 'grid',
        gridTemplateColumns: isMobile ? 'auto 1fr auto' : 'auto 1fr auto auto',
        gap: 10, alignItems: 'center',
        padding: '8px 10px', borderRadius: 12, minHeight: 58,
        cursor: 'pointer',
        background: active ? `linear-gradient(90deg, ${accent}18 0%, ${accent}08 100%)` : 'transparent',
        border: `1px solid ${active ? `${accent}28` : 'transparent'}`,
        boxShadow: active ? `inset 3px 0 0 0 ${accent}80` : 'none',
        transition: 'background 0.22s, border-color 0.22s',
        WebkitTapHighlightColor: 'transparent',
      }}
      onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
      onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}}
    >
      <AlbumArt song={song} size="sm" isPlaying={isPlaying} />

      <div style={{ minWidth: 0 }}>
        <p style={{ fontSize: 13, margin: 0, fontWeight: active ? 600 : 400, color: active ? 'var(--accent-primary)' : 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', transition: 'color 0.2s' }}>
          {song.title}
        </p>
        <p style={{ fontSize: 11, margin: 0, color: 'var(--text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {song.artist}
        </p>
      </div>

      <motion.button
        onClick={onLike}
        whileHover={{ scale: 1.22 }} whileTap={{ scale: 0.80 }}
        style={{
          background: 'none', border: 'none', cursor: 'pointer',
          width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 15, flexShrink: 0,
          color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
          filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.55))' : 'none',
          transition: 'color 0.2s, filter 0.2s',
          WebkitTapHighlightColor: 'transparent',
        }}
      >{isLiked ? '♥' : '♡'}</motion.button>

      {!isMobile && (
        <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 32, textAlign: 'right', fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
          {formatTime(song.duration)}
        </span>
      )}
    </motion.div>
  )
}

/* ── Main component ─────────────────────────────────────── */
export default function LibraryPage({ screenSize = 'desktop' }) {
  const {
    currentSong, isPlaying, recentlyPlayed,
    playSong, togglePlay, toggleLike, liked,
  } = usePlayer()

  const isMobile = screenSize === 'mobile'
  const isTablet = screenSize === 'tablet'
  const hPad = isMobile ? 14 : isTablet ? 20 : 28

  /* Search */
  const [query,      setQuery]      = useState('')
  const [results,    setResults]    = useState([])
  const [searching,  setSearching]  = useState(false)
  const [searchDone, setSearchDone] = useState(false)
  const [history,    setHistory]    = useState(loadHistory)
  const debounceRef = useRef(null)
  const inputRef    = useRef(null)

  /* Live search */
  useEffect(() => {
    const q = query.trim()
    if (!q) { setResults([]); setSearchDone(false); return }
    setSearching(true); setSearchDone(false)
    clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(async () => {
      const res = await searchYouTube(q, 15)
      setResults(res)
      setSearching(false)
      setSearchDone(true)
      if (res.length > 0) setHistory(prev => pushHistory(q, prev))
    }, 480)
    return () => clearTimeout(debounceRef.current)
  }, [query])

  const handleSongClick = useCallback((song, list) => {
    if (currentSong.id === song.id) togglePlay()
    else playSong(song, list)
  }, [currentSong.id, togglePlay, playSong])

  const clearHistory = useCallback(() => {
    setHistory([])
    localStorage.removeItem(HISTORY_KEY)
  }, [])

  const showSearch = query.trim().length > 0
  const hasRecent  = recentlyPlayed.length > 0
  const hasHistory = history.length > 0

  return (
    <div style={{ height: '100%', overflowY: 'auto', overflowX: 'hidden', overscrollBehavior: 'contain', WebkitOverflowScrolling: 'touch', fontFamily: 'var(--font-body)' }}>
      <div style={{ padding: `${isMobile ? 16 : 26}px ${hPad}px 100px` }}>

        {/* Header */}
        <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.30, ease: EASE }} style={{ marginBottom: isMobile ? 18 : 24 }}>
          <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', margin: '0 0 4px' }}>Your music</p>
          <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 'clamp(20px, 4vw, 28px)', fontWeight: 800, margin: 0, lineHeight: 1.2, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>
            Library
          </h1>
        </motion.div>

        {/* Search bar */}
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28, delay: 0.06, ease: EASE }} style={{ position: 'relative', marginBottom: isMobile ? 20 : 26 }}>
          <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14, pointerEvents: 'none', zIndex: 1 }}>⊙</span>
          <AnimatePresence>
            {searching && (
              <motion.span key="spin" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                style={{ position: 'absolute', right: query ? 44 : 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--accent-primary)', fontSize: 12, zIndex: 1 }}>
                ···
              </motion.span>
            )}
          </AnimatePresence>
          <input
            ref={inputRef}
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Search any song, artist, mood…"
            style={{
              width: '100%', boxSizing: 'border-box',
              padding: `${isMobile ? 14 : 12}px ${query ? 44 : 16}px ${isMobile ? 14 : 12}px 42px`,
              background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)',
              borderRadius: 14, outline: 'none', color: 'var(--text-primary)',
              fontSize: isMobile ? 16 : 13, fontFamily: 'var(--font-body)',
              backdropFilter: 'blur(12px)', transition: 'all 0.22s', WebkitAppearance: 'none',
            }}
            onFocus={e => { e.target.style.borderColor = 'rgba(34,211,238,0.42)'; e.target.style.background = 'rgba(34,211,238,0.04)'; e.target.style.boxShadow = '0 0 0 3px rgba(34,211,238,0.08)' }}
            onBlur={e  => { e.target.style.borderColor = 'rgba(255,255,255,0.07)'; e.target.style.background = 'rgba(255,255,255,0.03)'; e.target.style.boxShadow = 'none' }}
          />
          <AnimatePresence>
            {query && (
              <motion.button key="clear"
                initial={{ opacity: 0, scale: 0.7 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.7 }}
                transition={{ duration: 0.14 }}
                onClick={() => { setQuery(''); setResults([]); setSearchDone(false); inputRef.current?.focus() }}
                style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', width: 28, height: 28, borderRadius: '50%', background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.10)', color: 'var(--text-muted)', fontSize: 11, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', WebkitTapHighlightColor: 'transparent' }}
              >✕</motion.button>
            )}
          </AnimatePresence>
        </motion.div>

        {/* Search History chips — shown when search bar is empty */}
        <AnimatePresence>
          {!showSearch && hasHistory && (
            <motion.div key="history" initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -4 }} transition={{ duration: 0.22, ease: EASE }} style={{ marginBottom: isMobile ? 24 : 28 }}>
              <SectionHeader title="Recent searches" action={clearHistory} actionLabel="Clear" />
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                {history.map((q, i) => (
                  <motion.button key={q}
                    initial={{ opacity: 0, scale: 0.88 }} animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.18, delay: i * 0.03, ease: EASE }}
                    onClick={() => { setQuery(q); inputRef.current?.focus() }}
                    whileHover={{ scale: 1.05, y: -1 }} whileTap={{ scale: 0.95 }}
                    style={{ padding: '7px 14px', borderRadius: 50, background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', color: 'var(--text-secondary)', fontSize: 12, cursor: 'pointer', fontFamily: 'var(--font-body)', display: 'flex', alignItems: 'center', gap: 6, transition: 'all 0.15s', WebkitTapHighlightColor: 'transparent' }}
                    onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(34,211,238,0.28)'; e.currentTarget.style.color = 'var(--accent-primary)'; e.currentTarget.style.background = 'rgba(34,211,238,0.06)' }}
                    onMouseLeave={e => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.08)'; e.currentTarget.style.color = 'var(--text-secondary)'; e.currentTarget.style.background = 'rgba(255,255,255,0.04)' }}
                  >
                    <span style={{ fontSize: 11, opacity: 0.5 }}>⟳</span>{q}
                  </motion.button>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Search results */}
        <AnimatePresence mode="wait">
          {showSearch && (
            <motion.div key="results" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} transition={{ duration: 0.22, ease: EASE }} style={{ marginBottom: 32 }}>
              <SectionHeader
                title={searching ? `Searching…` : searchDone ? `Results for "${query}"` : `Searching…`}
                count={!searching && results.length > 0 ? results.length : undefined}
              />
              {searching && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  {Array.from({ length: 5 }).map((_, i) => <SkeletonRow key={i} />)}
                </div>
              )}
              {!searching && searchDone && results.length === 0 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}
                  style={{ padding: '32px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}>
                  <div style={{ fontSize: 28, marginBottom: 10, opacity: 0.3 }}>⊙</div>
                  No results for "{query}"
                </motion.div>
              )}
              {!searching && results.length > 0 && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.20 }}
                  style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  {results.map((song, i) => (
                    <motion.div key={song.id} initial={{ opacity: 0, x: -12 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.22, delay: i * 0.03, ease: EASE }}>
                      <CompactRow
                        song={song}
                        active={currentSong.id === song.id}
                        isPlaying={isPlaying && currentSong.id === song.id}
                        isLiked={liked.has(song.id)}
                        isMobile={isMobile}
                        onClick={() => handleSongClick(song, results)}
                        onLike={e => { e.stopPropagation(); toggleLike(song.id, song) }}
                      />
                    </motion.div>
                  ))}
                </motion.div>
              )}
            </motion.div>
          )}
        </AnimatePresence>

        {/* Recently Played */}
        <AnimatePresence>
          {!showSearch && (
            <motion.div key="recent" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} transition={{ duration: 0.26, ease: EASE }}>
              <SectionHeader title="Recently Played" count={hasRecent ? recentlyPlayed.length : undefined} />

              {!hasRecent ? (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}
                  style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '48px 20px', gap: 10, textAlign: 'center' }}>
                  <div style={{ fontSize: 36, opacity: 0.15 }}>♪</div>
                  <p style={{ fontSize: 14, color: 'var(--text-secondary)', margin: 0 }}>Nothing played yet</p>
                  <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0 }}>Songs you play will appear here automatically</p>
                  <motion.button
                    onClick={() => inputRef.current?.focus()}
                    whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.96 }}
                    style={{ marginTop: 8, padding: '10px 22px', borderRadius: 50, background: 'rgba(34,211,238,0.10)', border: '1px solid rgba(34,211,238,0.25)', color: 'var(--accent-primary)', fontSize: 13, cursor: 'pointer', fontFamily: 'var(--font-body)', display: 'flex', alignItems: 'center', gap: 8, WebkitTapHighlightColor: 'transparent' }}
                  >⊙ Search for music</motion.button>
                </motion.div>
              ) : (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.22 }}
                  style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  {recentlyPlayed.map((song, i) => (
                    <motion.div key={`${song.id}-${i}`}
                      initial={{ opacity: 0, x: -12 }} animate={{ opacity: 1, x: 0 }}
                      transition={{ duration: 0.24, delay: Math.min(i, 8) * 0.04, ease: EASE }}>
                      <CompactRow
                        song={song}
                        active={currentSong.id === song.id}
                        isPlaying={isPlaying && currentSong.id === song.id}
                        isLiked={liked.has(song.id)}
                        isMobile={isMobile}
                        onClick={() => handleSongClick(song, recentlyPlayed)}
                        onLike={e => { e.stopPropagation(); toggleLike(song.id, song) }}
                      />
                    </motion.div>
                  ))}
                </motion.div>
              )}
            </motion.div>
          )}
        </AnimatePresence>

      </div>
    </div>
  )
}
LIBRARYEOF
ok "${LIBRARY} written"

# ── Verify recentlyPlayed in usePlayer ───────────────────────────────────────
log "Verifying usePlayer exposes recentlyPlayed …"
USE_PLAYER=""
for p in src/hooks/usePlayer.jsx src/hooks/usePlayer.js hooks/usePlayer.jsx; do
  [ -f "$p" ] && USE_PLAYER="$p" && break
done
if [ -z "$USE_PLAYER" ]; then
  warn "usePlayer not found — ensure recentlyPlayed is in context value"
elif grep -q "recentlyPlayed" "$USE_PLAYER"; then
  ok "recentlyPlayed present in ${USE_PLAYER}"
else
  warn "recentlyPlayed NOT found in ${USE_PLAYER} — run fix-progress-tracking.sh first"
fi

# ── Verify ytSearch path ─────────────────────────────────────────────────────
log "Checking ytSearch import path …"
for p in src/utils/ytSearch.js src/utils/ytSearch.ts utils/ytSearch.js; do
  [ -f "$p" ] && ok "searchYouTube found at ${p}" && break
done

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║  Done!                                                    ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
printf "${GREEN}║  %-56s║${RESET}\n" "${LIBRARY}  (backup: .bak)"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  What's new in Library                                   ║${RESET}"
echo -e "${GREEN}║  ✓ No static SONGS — zero hardcoded data                 ║${RESET}"
echo -e "${GREEN}║  ✓ Recently Played: live from usePlayer context          ║${RESET}"
echo -e "${GREEN}║    Updates the instant any song starts playing           ║${RESET}"
echo -e "${GREEN}║    Persisted across sessions via localStorage            ║${RESET}"
echo -e "${GREEN}║  ✓ Inline search: live YouTube results as you type       ║${RESET}"
echo -e "${GREEN}║    480ms debounce, skeleton loading state                ║${RESET}"
echo -e "${GREEN}║    Plays straight into queue on click                    ║${RESET}"
echo -e "${GREEN}║  ✓ Search History: last 10 queries as clickable chips    ║${RESET}"
echo -e "${GREEN}║    Persisted in localStorage key mysic_search_history    ║${RESET}"
echo -e "${GREEN}║    Clear button removes all history                      ║${RESET}"
echo -e "${GREEN}║  ✓ Empty state with CTA to search when nothing played    ║${RESET}"
echo -e "${GREEN}║  ✓ Like/unlike works inline in all sections              ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Next steps                                              ║${RESET}"
echo -e "${GREEN}║  1. npm run dev                                          ║${RESET}"
echo -e "${GREEN}║  2. Play 2-3 songs → Library shows them instantly        ║${RESET}"
echo -e "${GREEN}║  3. Search in Library → live results appear              ║${RESET}"
echo -e "${GREEN}║  4. Search again → history chips appear                  ║${RESET}"
echo -e "${GREEN}║  5. git add -A && git commit -m 'feat: dynamic library'  ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
