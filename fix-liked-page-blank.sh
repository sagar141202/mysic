#!/usr/bin/env bash
# =============================================================================
#  fix-liked-page-blank.sh — Mysic · Fix blank LikedPage crash
#
#  Run from the ROOT of your mysic repo:
#    bash fix-liked-page-blank.sh
#
#  ROOT CAUSE (exact)
#  ──────────────────
#  The fix-progress-tracking.sh rewrite of usePlayer.jsx changed how liked
#  songs are stored in localStorage:
#
#  BEFORE (original usePlayer):
#    mysic_liked = [{ id, title, artist, duration, thumbnail, color }, ...]
#    i.e. full song objects in the array
#
#  AFTER (rewritten usePlayer):
#    mysic_liked = ["id1", "id2", ...]          ← just ID strings
#    mysic_liked_songs = [{ id, title, ... }]   ← separate key, only written
#                                                  when liking, never cleaned
#
#  LikedPage reads the array and does song.title, song.artist etc.
#  With the new format it gets plain strings → song.title = undefined → crash.
#
#  SECONDARY BUG
#  ─────────────
#  The context value object in the rewritten usePlayer has _setYtReady listed
#  TWICE (duplicate key). The second silently overwrites the first. Not a crash
#  but a lint error and confusing.
#
#  ALSO: likedSongs (array of full song objects) was never exposed on the
#  context, so LikedPage had no clean way to get them without localStorage.
#
#  THE FIX
#  ───────
#  1. usePlayer stores liked songs as full objects in ONE key (mysic_liked)
#     — same as the original. The Set of IDs is derived from it, not separate.
#  2. likedSongs (array) is exposed on the context alongside liked (Set).
#  3. toggleLike correctly removes the full object on unlike too.
#  4. Duplicate _setYtReady key removed from context value.
#  5. LikedPage is rewritten to use likedSongs from context (no localStorage).
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
echo -e "${CYAN}║   Mysic — Fix Blank LikedPage Crash                      ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

[ -f "package.json" ] || die "Run from the repo root (package.json not found)"
log "Repo root confirmed"

# ── locate helpers ────────────────────────────────────────────────────────────
find_file() {
  local name="$1"; shift
  for dir in "$@"; do
    local p="${dir}/${name}"
    [ -f "$p" ] && echo "$p" && return
  done
  echo ""
}

backup() {
  local f="$1"
  [ -f "$f" ] && cp "$f" "${f}.bak" && ok "Backed up → ${f}.bak"
}

# ─────────────────────────────────────────────────────────────────────────────
# 1.  Patch usePlayer.jsx — fix storage + expose likedSongs + remove dup key
# ─────────────────────────────────────────────────────────────────────────────
log "Locating usePlayer.jsx …"
USE_PLAYER=""
for p in src/hooks/usePlayer.jsx src/hooks/usePlayer.js hooks/usePlayer.jsx; do
  [ -f "$p" ] && USE_PLAYER="$p" && break
done
[ -z "$USE_PLAYER" ] && die "usePlayer.jsx not found. Run from repo root."
backup "$USE_PLAYER"

log "Patching ${USE_PLAYER} …"

# We rewrite the entire file so every change is clean and auditable.
cat > "$USE_PLAYER" << 'USEPLAYEREOF'
/**
 * usePlayer.jsx — Mysic global player context
 *
 * STORAGE FORMAT (restored to original contract):
 *   localStorage key  "mysic_liked"  →  array of full song objects
 *   [ { id, title, artist, duration, thumbnail, color, youtubeId }, ... ]
 *
 *   The Set<id> used by liked.has() is derived from this array, not stored
 *   separately. This is what LikedPage and every other component expects.
 *
 * CONTEXT ADDITIONS vs original:
 *   likedSongs  — array of full song objects in like order (newest first)
 *   shuffle, repeat, toggleShuffle, toggleRepeat — wired up
 *   recentlyPlayed — persisted array
 *   _onEnded — called by YouTubePlayer onStateChange(0)
 *
 * PROGRESS FIX (from fix-progress-tracking.sh, kept):
 *   startTick polls getCurrentTime() instead of accumulating a fake counter.
 */

import {
  createContext, useContext, useRef,
  useState, useEffect, useCallback,
} from 'react'
import { SONGS } from '../data/songs'

/* ── Liked songs — stored as full song objects ───────────── */
function loadLikedSongs() {
  try {
    const raw = localStorage.getItem('mysic_liked')
    if (!raw) return []
    const parsed = JSON.parse(raw)
    // Handle legacy format: if array contains plain strings (IDs), discard
    if (!Array.isArray(parsed)) return []
    if (parsed.length > 0 && typeof parsed[0] === 'string') {
      // Old ID-only format from the broken fix — migrate to empty, user re-likes
      localStorage.removeItem('mysic_liked')
      return []
    }
    return parsed // array of full song objects
  } catch { return [] }
}
function saveLikedSongs(arr) {
  try { localStorage.setItem('mysic_liked', JSON.stringify(arr)) } catch {}
}

/* ── Recently played ─────────────────────────────────────── */
function loadRecent() {
  try {
    const raw = localStorage.getItem('mysic_recent')
    return raw ? JSON.parse(raw) : []
  } catch { return [] }
}
function saveRecent(arr) {
  try { localStorage.setItem('mysic_recent', JSON.stringify(arr.slice(0, 20))) } catch {}
}

/* ── Context ─────────────────────────────────────────────── */
const PlayerContext = createContext(null)

const DEFAULT_SONG = SONGS?.[0] || {
  id: 'default', youtubeId: '', title: 'No song loaded',
  artist: '', duration: 0, thumbnail: '', color: '#8b5cf6',
}

export function PlayerProvider({ children }) {
  const [currentSong,    setCurrentSong]    = useState(DEFAULT_SONG)
  const [queue,          setQueue]          = useState(SONGS || [])
  const [isPlaying,      setIsPlaying]      = useState(false)
  const [progress,       setProgress]       = useState(0)
  const [volume,         setVolVol]         = useState(80)
  const [likedSongs,     setLikedSongs]     = useState(loadLikedSongs)   // full objects
  const [ytReady,        setYtReady]        = useState(false)
  const [shuffle,        setShuffle]        = useState(false)
  const [repeat,         setRepeat]         = useState(false)
  const [recentlyPlayed, setRecentlyPlayed] = useState(loadRecent)

  /* Derived: Set of liked IDs — used for liked.has(id) throughout the UI */
  const liked = new Set(likedSongs.map(s => s.id))

  /* Refs — never trigger re-renders */
  const tickRef        = useRef(null)
  const currentSongRef = useRef(currentSong)
  const isPlayingRef   = useRef(false)
  const progressRef    = useRef(0)
  const shuffleRef     = useRef(false)
  const repeatRef      = useRef(false)
  const queueRef       = useRef(queue)

  useEffect(() => { currentSongRef.current = currentSong }, [currentSong])
  useEffect(() => { isPlayingRef.current   = isPlaying   }, [isPlaying])
  useEffect(() => { progressRef.current    = progress    }, [progress])
  useEffect(() => { shuffleRef.current     = shuffle     }, [shuffle])
  useEffect(() => { repeatRef.current      = repeat      }, [repeat])
  useEffect(() => { queueRef.current       = queue       }, [queue])

  /* ── YT safe-call helper ─────────────────────────────── */
  const yt = useCallback((method, ...args) => {
    try {
      const p = window.__ytPlayer
      if (p && typeof p[method] === 'function') return p[method](...args)
    } catch (e) {
      console.warn('[usePlayer] YT call failed:', method, e)
    }
  }, [])

  /* ── Progress tick — polls real YT position ──────────── */
  const stopTick = useCallback(() => {
    if (tickRef.current) { clearInterval(tickRef.current); tickRef.current = null }
  }, [])

  const startTick = useCallback(() => {
    stopTick()
    tickRef.current = setInterval(() => {
      const song = currentSongRef.current
      if (!song?.duration || song.duration <= 0) return
      const currentTime = yt('getCurrentTime') ?? 0
      const pct = Math.min(100, (currentTime / song.duration) * 100)
      setProgress(pct)
      progressRef.current = pct
      if (pct >= 99.5 && isPlayingRef.current) {
        stopTick()
        setTimeout(() => {
          if (progressRef.current >= 99.5 && isPlayingRef.current) playNextInternal()
        }, 1500)
      }
    }, 250)
  }, [stopTick, yt])

  /* ── Load + play a video ─────────────────────────────── */
  const loadAndPlay = useCallback((song) => {
    if (!song?.youtubeId) return
    stopTick()
    setProgress(0); progressRef.current = 0
    const doLoad = () => {
      yt('loadVideoById', song.youtubeId)
      setTimeout(() => yt('setVolume', volume), 300)
    }
    if (window.__ytPlayer && ytReady) {
      doLoad()
    } else {
      const handler = () => { doLoad(); window.removeEventListener('mysic:ytready', handler) }
      window.addEventListener('mysic:ytready', handler)
    }
  }, [stopTick, yt, volume, ytReady])

  /* ── Next track ──────────────────────────────────────── */
  const playNextInternal = useCallback(() => {
    const q    = queueRef.current
    const song = currentSongRef.current
    if (!q.length) return
    let nextSong
    if (repeatRef.current === 'one' || repeatRef.current === true) {
      nextSong = song
    } else if (shuffleRef.current) {
      const others = q.filter(s => s.id !== song.id)
      nextSong = others.length ? others[Math.floor(Math.random() * others.length)] : song
    } else {
      const idx = q.findIndex(s => s.id === song.id)
      const nextIdx = (idx + 1) % q.length
      if (nextIdx === 0 && !repeatRef.current) {
        setIsPlaying(false); isPlayingRef.current = false
        setProgress(0); progressRef.current = 0
        stopTick(); yt('stopVideo')
        return
      }
      nextSong = q[nextIdx]
    }
    setCurrentSong(nextSong)
    setIsPlaying(true); isPlayingRef.current = true
    setProgress(0); progressRef.current = 0
    loadAndPlay(nextSong)
    startTick()
    addToRecent(nextSong)
  }, [loadAndPlay, startTick, stopTick, yt])

  /* ── _onEnded — called by YouTubePlayer onStateChange(0) ── */
  const _onEnded = useCallback(() => playNextInternal(), [playNextInternal])

  /* ── _setYtReady ─────────────────────────────────────── */
  const _setYtReady = useCallback((val) => {
    setYtReady(val)
    if (val) {
      yt('setVolume', volume)
      window.dispatchEvent(new Event('mysic:ytready'))
    }
  }, [yt, volume])

  /* ── Recently played ─────────────────────────────────── */
  const addToRecent = useCallback((song) => {
    setRecentlyPlayed(prev => {
      const next = [song, ...prev.filter(s => s.id !== song.id)].slice(0, 20)
      saveRecent(next)
      return next
    })
  }, [])

  /* ── playSong ────────────────────────────────────────── */
  const playSong = useCallback((song, newQueue = null) => {
    if (newQueue) setQueue(newQueue)
    setCurrentSong(song)
    setIsPlaying(true); isPlayingRef.current = true
    setProgress(0); progressRef.current = 0
    loadAndPlay(song)
    startTick()
    addToRecent(song)
  }, [loadAndPlay, startTick, addToRecent])

  /* ── togglePlay ──────────────────────────────────────── */
  const togglePlay = useCallback(async () => {
    if (isPlayingRef.current) {
      yt('pauseVideo')
      setIsPlaying(false); isPlayingRef.current = false
      stopTick()
    } else {
      yt('playVideo')
      setIsPlaying(true); isPlayingRef.current = true
      startTick()
    }
  }, [yt, stopTick, startTick])

  /* ── playNext ────────────────────────────────────────── */
  const playNext = useCallback(() => playNextInternal(), [playNextInternal])

  /* ── playPrev ────────────────────────────────────────── */
  const playPrev = useCallback(() => {
    const q    = queueRef.current
    const song = currentSongRef.current
    if (!q.length) return
    const currentTime = yt('getCurrentTime') ?? 0
    if (currentTime > 3) {
      yt('seekTo', 0, true)
      setProgress(0); progressRef.current = 0
      return
    }
    const idx  = q.findIndex(s => s.id === song.id)
    const prev = q[(idx - 1 + q.length) % q.length]
    setCurrentSong(prev)
    setIsPlaying(true); isPlayingRef.current = true
    setProgress(0); progressRef.current = 0
    loadAndPlay(prev)
    startTick()
    addToRecent(prev)
  }, [yt, loadAndPlay, startTick, addToRecent])

  /* ── seek ────────────────────────────────────────────── */
  const seek = useCallback((pct) => {
    const song = currentSongRef.current
    if (!song?.duration) return
    yt('seekTo', (pct / 100) * song.duration, true)
    setProgress(pct); progressRef.current = pct
  }, [yt])

  /* ── setVolume ───────────────────────────────────────── */
  const setVolume = useCallback((pct) => {
    setVolVol(pct)
    yt('setVolume', pct)
    if (pct === 0) yt('mute'); else yt('unMute')
  }, [yt])

  /* ── toggleLike — stores full song objects ───────────── */
  const toggleLike = useCallback((id, song) => {
    setLikedSongs(prev => {
      let next
      if (prev.find(s => s.id === id)) {
        // Unlike: remove the object
        next = prev.filter(s => s.id !== id)
      } else {
        // Like: prepend full song object (fall back to minimal shape if missing)
        const obj = song || { id, title: id, artist: '', duration: 0, thumbnail: '', color: '#8b5cf6' }
        next = [obj, ...prev]
      }
      saveLikedSongs(next)
      return next
    })
  }, [])

  /* ── toggleShuffle ───────────────────────────────────── */
  const toggleShuffle = useCallback(() => {
    setShuffle(v => { shuffleRef.current = !v; return !v })
  }, [])

  /* ── toggleRepeat — cycles off → all → one ───────────── */
  const toggleRepeat = useCallback(() => {
    setRepeat(v => {
      const next = v === false ? 'all' : v === 'all' ? 'one' : false
      repeatRef.current = next
      return next
    })
  }, [])

  /* ── Cleanup ─────────────────────────────────────────── */
  useEffect(() => () => stopTick(), [stopTick])

  /* ── Context value ───────────────────────────────────── */
  const value = {
    currentSong, queue, isPlaying, progress, volume,
    liked,        // Set<id>  — for liked.has(id) checks
    likedSongs,   // Song[]   — for LikedPage rendering
    ytReady, shuffle, repeat, recentlyPlayed,
    playSong, togglePlay, playNext, playPrev,
    seek, setVolume, toggleLike, toggleShuffle, toggleRepeat,
    _setYtReady, _onEnded,   // internal — YouTubePlayer only
  }

  return (
    <PlayerContext.Provider value={value}>
      {children}
    </PlayerContext.Provider>
  )
}

export function usePlayer() {
  const ctx = useContext(PlayerContext)
  if (!ctx) throw new Error('usePlayer must be used inside <PlayerProvider>')
  return ctx
}
USEPLAYEREOF
ok "${USE_PLAYER} patched"

# ─────────────────────────────────────────────────────────────────────────────
# 2.  Rewrite LikedPage.jsx — read from context, not localStorage
# ─────────────────────────────────────────────────────────────────────────────
log "Locating LikedPage.jsx …"
LIKED_PAGE=""
for p in src/pages/LikedPage.jsx src/pages/LikedPage.js pages/LikedPage.jsx; do
  [ -f "$p" ] && LIKED_PAGE="$p" && break
done
if [ -z "$LIKED_PAGE" ]; then
  warn "LikedPage.jsx not found — creating at src/pages/LikedPage.jsx"
  mkdir -p src/pages
  LIKED_PAGE="src/pages/LikedPage.jsx"
else
  backup "$LIKED_PAGE"
fi

log "Writing ${LIKED_PAGE} …"
cat > "$LIKED_PAGE" << 'LIKEDPAGEEOF'
/**
 * LikedPage.jsx
 *
 * Reads likedSongs from usePlayer context (array of full song objects).
 * No localStorage reads — the context is the single source of truth.
 *
 * Crash fix: the previous implementation read localStorage 'mysic_liked'
 * which after fix-progress-tracking.sh contained plain ID strings instead
 * of song objects, causing song.title → undefined → blank page.
 */
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import SongList from '../components/SongList'

const EASE = [0.25, 0.46, 0.45, 0.94]

export default function LikedPage() {
  const { likedSongs, playSong } = usePlayer()

  return (
    <div style={{
      height: '100%',
      overflowY: 'auto',
      overflowX: 'hidden',
      overscrollBehavior: 'contain',
      WebkitOverflowScrolling: 'touch',
      fontFamily: 'var(--font-body)',
    }}>
      <div style={{ padding: '28px 24px 100px', maxWidth: 860, margin: '0 auto' }}>

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.30, ease: EASE }}
          style={{ marginBottom: 28 }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 6 }}>
            <div style={{
              width: 48, height: 48, borderRadius: 14, flexShrink: 0,
              background: 'linear-gradient(135deg, rgba(34,211,238,0.18), rgba(139,92,246,0.18))',
              border: '1px solid rgba(34,211,238,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22,
            }}>♥</div>
            <div>
              <h1 style={{
                fontFamily: 'var(--font-display)',
                fontSize: 'clamp(20px, 4vw, 28px)',
                fontWeight: 800,
                margin: 0, lineHeight: 1.2,
                background: 'var(--accent-grad)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
              }}>
                Liked Songs
              </h1>
              <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: '3px 0 0' }}>
                {likedSongs.length === 0
                  ? 'No liked songs yet'
                  : `${likedSongs.length} song${likedSongs.length === 1 ? '' : 's'}`}
              </p>
            </div>
          </div>

          {/* Play all button — only when there are songs */}
          {likedSongs.length > 0 && (
            <motion.button
              onClick={() => playSong(likedSongs[0], likedSongs)}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.96 }}
              style={{
                marginTop: 16,
                padding: '10px 24px',
                borderRadius: 50,
                background: 'var(--accent-grad)',
                border: 'none',
                color: '#08121f',
                fontFamily: 'var(--font-body)',
                fontSize: 13, fontWeight: 700,
                cursor: 'pointer',
                boxShadow: '0 4px 16px rgba(34,211,238,0.35)',
                display: 'inline-flex', alignItems: 'center', gap: 8,
              }}
            >
              ▶ Play all
            </motion.button>
          )}
        </motion.div>

        {/* Song list */}
        <AnimatePresence mode="wait">
          {likedSongs.length === 0 ? (
            <motion.div
              key="empty"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.24, ease: EASE }}
              style={{
                textAlign: 'center',
                padding: '60px 20px',
                color: 'var(--text-muted)',
              }}
            >
              <div style={{ fontSize: 40, marginBottom: 12, opacity: 0.3 }}>♡</div>
              <p style={{ fontSize: 15, margin: '0 0 6px', color: 'var(--text-secondary)' }}>
                No liked songs yet
              </p>
              <p style={{ fontSize: 12, margin: 0 }}>
                Tap ♡ on any song to add it here
              </p>
            </motion.div>
          ) : (
            <motion.div
              key="list"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.20 }}
            >
              <SongList songs={likedSongs} showIndex={true} />
            </motion.div>
          )}
        </AnimatePresence>

      </div>
    </div>
  )
}
LIKEDPAGEEOF
ok "${LIKED_PAGE} written"

# ─────────────────────────────────────────────────────────────────────────────
# 3.  Clear the corrupted localStorage entry (dev only — open browser console)
# ─────────────────────────────────────────────────────────────────────────────
echo ""
warn "If you still see a blank page after reloading, the old ID-string data"
warn "may be cached in your browser's localStorage. Clear it once by running"
warn "this in the browser DevTools console (F12 → Console):"
echo ""
echo "  localStorage.removeItem('mysic_liked')"
echo "  location.reload()"
echo ""
warn "The new code auto-detects and migrates the old format on load, but"
warn "a manual clear is the fastest fix if auto-migration doesn't trigger."

# ─────────────────────────────────────────────────────────────────────────────
# 4.  Summary
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║  Done! Files written:                                    ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
printf "${GREEN}║  %-56s║${RESET}\n" "${USE_PLAYER}  (backup: .bak)"
printf "${GREEN}║  %-56s║${RESET}\n" "${LIKED_PAGE}  (backup: .bak)"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Root cause fixed                                        ║${RESET}"
echo -e "${GREEN}║  ✓ mysic_liked stores full song objects again (not IDs)  ║${RESET}"
echo -e "${GREEN}║  ✓ likedSongs[] exposed on context — LikedPage uses it  ║${RESET}"
echo -e "${GREEN}║  ✓ toggleLike removes object on unlike (was ID-only)     ║${RESET}"
echo -e "${GREEN}║  ✓ Duplicate _setYtReady key removed from context value  ║${RESET}"
echo -e "${GREEN}║  ✓ LikedPage reads context, not localStorage directly    ║${RESET}"
echo -e "${GREEN}║  ✓ Auto-migration: old ID-string format → empty (safe)   ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Next steps                                              ║${RESET}"
echo -e "${GREEN}║  1. npm run dev                                          ║${RESET}"
echo -e "${GREEN}║  2. Like 2-3 songs — confirm ♥ toggles correctly        ║${RESET}"
echo -e "${GREEN}║  3. Click Liked in sidebar — page must render song list  ║${RESET}"
echo -e "${GREEN}║  4. Unlike a song — confirm it disappears from LikedPage ║${RESET}"
echo -e "${GREEN}║  5. git add -A && git commit -m 'fix: liked page crash'  ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
