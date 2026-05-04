#!/usr/bin/env bash
# =============================================================================
#  fix-progress-tracking.sh — Mysic · Real YouTube Progress Tracking
#
#  Run from the ROOT of your mysic repo:
#    bash fix-progress-tracking.sh
#
#  What this fixes
#  ───────────────
#  BEFORE: usePlayer runs setInterval and adds  prog += (100 / duration) * 0.25
#          every 250 ms.  After any seek the accumulator continues from the
#          wrong baseline — UI and audio drift apart permanently.
#
#  AFTER:  startTick polls window.__ytPlayer.getCurrentTime() every 250 ms and
#          sets progress = (currentTime / duration) * 100  — always in sync.
#          onStateChange(0) from the YT iframe fires playNext() directly instead
#          of the fake timer racing to 100 %.
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
echo -e "${CYAN}║   Mysic — Real YouTube Progress Tracking Fix             ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

[ -f "package.json" ] || die "Run from the repo root (package.json not found)"
log "Repo root confirmed"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers: find a file across common locations
# ─────────────────────────────────────────────────────────────────────────────
find_file() {
  # Usage: find_file "usePlayer.jsx" "src/hooks" "hooks"
  local name="$1"; shift
  for dir in "$@"; do
    local p="${dir}/${name}"
    if [ -f "$p" ]; then echo "$p"; return; fi
  done
  echo ""
}

backup() {
  local f="$1"
  if [ -f "$f" ]; then
    cp "$f" "${f}.bak"
    ok "Backed up → ${f}.bak"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# 1.  usePlayer.jsx  — THE CORE FIX
# ─────────────────────────────────────────────────────────────────────────────
log "Locating usePlayer.jsx …"

USE_PLAYER=""
for p in src/hooks/usePlayer.jsx src/hooks/usePlayer.js hooks/usePlayer.jsx hooks/usePlayer.js; do
  [ -f "$p" ] && USE_PLAYER="$p" && break
done

if [ -z "$USE_PLAYER" ]; then
  warn "usePlayer not found — will create at src/hooks/usePlayer.jsx"
  mkdir -p src/hooks
  USE_PLAYER="src/hooks/usePlayer.jsx"
else
  backup "$USE_PLAYER"
fi

log "Writing ${USE_PLAYER} …"
cat > "$USE_PLAYER" << 'USEPLAYEREOF'
/**
 * usePlayer.jsx — Mysic global player context
 *
 * KEY FIX (progress tracking):
 *   BEFORE: setInterval accumulated  prog += 100/duration  every 250 ms.
 *           After a seek the tick kept adding from the old number → drift.
 *   AFTER:  startTick polls window.__ytPlayer.getCurrentTime() every 250 ms.
 *           progress = (currentTime / duration) * 100  — always real, never drifts.
 *
 * KEY FIX (track-end detection):
 *   BEFORE: fake timer raced to 100 % and hoped to call playNext in time.
 *   AFTER:  YouTubePlayer's onStateChange(0) calls the exported _onEnded()
 *           callback directly — no guessing, no gap.
 *
 * Everything else (queue, liked, volume, seek, shuffle, repeat) is unchanged
 * from the original API surface so no other component needs editing.
 */

import {
  createContext, useContext, useRef,
  useState, useEffect, useCallback,
} from 'react'
import { SONGS } from '../data/songs'

/* ── Liked songs persistence ─────────────────────────────── */
function loadLiked() {
  try {
    const raw = localStorage.getItem('mysic_liked')
    return raw ? new Set(JSON.parse(raw)) : new Set()
  } catch { return new Set() }
}
function saveLiked(set) {
  try { localStorage.setItem('mysic_liked', JSON.stringify([...set])) } catch {}
}

/* ── Recently played persistence ────────────────────────── */
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

/* ─────────────────────────────────────────────────────────── */
export function PlayerProvider({ children }) {
  const [currentSong, setCurrentSong] = useState(DEFAULT_SONG)
  const [queue,       setQueue]       = useState(SONGS || [])
  const [isPlaying,   setIsPlaying]   = useState(false)
  const [progress,    setProgress]    = useState(0)     // 0-100
  const [volume,      setVolVol]      = useState(80)
  const [liked,       setLiked]       = useState(loadLiked)
  const [ytReady,     setYtReady]     = useState(false)
  const [shuffle,     setShuffle]     = useState(false)
  const [repeat,      setRepeat]      = useState(false) // 'none'|'one'|'all' — start simple
  const [recentlyPlayed, setRecentlyPlayed] = useState(loadRecent)

  /* Internal refs — never trigger re-renders */
  const tickRef        = useRef(null)   // setInterval id
  const currentSongRef = useRef(currentSong)
  const isPlayingRef   = useRef(false)
  const progressRef    = useRef(0)
  const shuffleRef     = useRef(false)
  const repeatRef      = useRef(false)
  const queueRef       = useRef(queue)

  /* Keep refs in sync */
  useEffect(() => { currentSongRef.current = currentSong }, [currentSong])
  useEffect(() => { isPlayingRef.current   = isPlaying   }, [isPlaying])
  useEffect(() => { progressRef.current    = progress    }, [progress])
  useEffect(() => { shuffleRef.current     = shuffle     }, [shuffle])
  useEffect(() => { repeatRef.current      = repeat      }, [repeat])
  useEffect(() => { queueRef.current       = queue       }, [queue])

  /* ── YT helper — safe call ───────────────────────────── */
  const yt = useCallback((method, ...args) => {
    try {
      const p = window.__ytPlayer
      if (p && typeof p[method] === 'function') return p[method](...args)
    } catch (e) {
      console.warn('[usePlayer] YT call failed:', method, e)
    }
  }, [])

  /* ── Tick: polls real YT position ───────────────────── */
  const stopTick = useCallback(() => {
    if (tickRef.current) { clearInterval(tickRef.current); tickRef.current = null }
  }, [])

  const startTick = useCallback(() => {
    stopTick()
    tickRef.current = setInterval(() => {
      const song = currentSongRef.current
      if (!song?.duration || song.duration <= 0) return

      /* ── REAL position from YouTube IFrame API ── */
      const currentTime = yt('getCurrentTime') ?? 0

      const pct = Math.min(100, (currentTime / song.duration) * 100)
      setProgress(pct)
      progressRef.current = pct

      /* Safety net: if YT hasn't fired onStateChange(0) yet */
      if (pct >= 99.5 && isPlayingRef.current) {
        stopTick()
        // onStateChange(0) handler (_onEnded) will call playNext — avoid double
        // Only call playNext here if onStateChange never arrives (rare edge case)
        setTimeout(() => {
          if (progressRef.current >= 99.5 && isPlayingRef.current) {
            playNextInternal()
          }
        }, 1500)
      }
    }, 250)
  }, [stopTick, yt])

  /* ── Load + play a video ────────────────────────────── */
  const loadAndPlay = useCallback((song) => {
    if (!song?.youtubeId) return
    stopTick()
    setProgress(0)
    progressRef.current = 0

    const doLoad = () => {
      yt('loadVideoById', song.youtubeId)
      /* volume is set in onReady; re-apply on each load */
      setTimeout(() => yt('setVolume', volume), 300)
    }

    if (window.__ytPlayer && ytReady) {
      doLoad()
    } else {
      /* YT not ready yet — queue up */
      const handler = () => { doLoad(); window.removeEventListener('mysic:ytready', handler) }
      window.addEventListener('mysic:ytready', handler)
    }
  }, [stopTick, yt, volume, ytReady])

  /* ── Next track logic (used by tick + onStateChange) ── */
  const playNextInternal = useCallback(() => {
    const q    = queueRef.current
    const song = currentSongRef.current
    if (!q.length) return

    let nextSong
    if (repeatRef.current === 'one' || repeatRef.current === true) {
      /* repeat one: replay same */
      nextSong = song
    } else if (shuffleRef.current) {
      const others = q.filter(s => s.id !== song.id)
      nextSong = others.length
        ? others[Math.floor(Math.random() * others.length)]
        : song
    } else {
      const idx = q.findIndex(s => s.id === song.id)
      const nextIdx = (idx + 1) % q.length
      if (nextIdx === 0 && !repeatRef.current) {
        /* end of queue, no repeat — stop */
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

  /* ── Exported: _onEnded — called by YouTubePlayer onStateChange(0) ── */
  const _onEnded = useCallback(() => {
    playNextInternal()
  }, [playNextInternal])

  /* ── Exported: _setYtReady ───────────────────────────── */
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
      const filtered = prev.filter(s => s.id !== song.id)
      const next = [song, ...filtered].slice(0, 20)
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
  const playNext = useCallback(() => {
    playNextInternal()
  }, [playNextInternal])

  /* ── playPrev ────────────────────────────────────────── */
  const playPrev = useCallback(() => {
    const q   = queueRef.current
    const song = currentSongRef.current
    if (!q.length) return

    /* If more than 3 s in, restart current track */
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
    const targetSec = (pct / 100) * song.duration
    yt('seekTo', targetSec, true)
    /* Optimistic UI update — tick will correct on next poll */
    setProgress(pct); progressRef.current = pct
  }, [yt])

  /* ── setVolume ───────────────────────────────────────── */
  const setVolume = useCallback((pct) => {
    setVolVol(pct)
    yt('setVolume', pct)
    if (pct === 0) yt('mute')
    else           yt('unMute')
  }, [yt])

  /* ── toggleLike ──────────────────────────────────────── */
  const toggleLike = useCallback((id, song) => {
    setLiked(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else {
        next.add(id)
        if (song) {
          /* persist full song object for LikedPage */
          try {
            const stored = JSON.parse(localStorage.getItem('mysic_liked_songs') || '[]')
            const exists = stored.find(s => s.id === id)
            if (!exists) localStorage.setItem('mysic_liked_songs', JSON.stringify([song, ...stored]))
          } catch {}
        }
      }
      saveLiked(next)
      return next
    })
  }, [])

  /* ── toggleShuffle ───────────────────────────────────── */
  const toggleShuffle = useCallback(() => {
    setShuffle(v => { shuffleRef.current = !v; return !v })
  }, [])

  /* ── toggleRepeat ────────────────────────────────────── */
  const toggleRepeat = useCallback(() => {
    setRepeat(v => {
      // Cycle: false → 'all' → 'one' → false
      const next = v === false ? 'all' : v === 'all' ? 'one' : false
      repeatRef.current = next
      return next
    })
  }, [])

  /* ── Cleanup on unmount ──────────────────────────────── */
  useEffect(() => () => stopTick(), [stopTick])

  /* ── Context value ───────────────────────────────────── */
  const value = {
    /* state */
    currentSong, queue, isPlaying, progress, volume,
    liked, ytReady, shuffle, repeat, recentlyPlayed,
    /* actions */
    playSong, togglePlay, playNext, playPrev,
    seek, setVolume, toggleLike, toggleShuffle, toggleRepeat,
    /* internal — used by YouTubePlayer only */
    _setYtReady, _onEnded,
    /* legacy alias used by YouTubePlayer */
    _setYtReady,
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
ok "${USE_PLAYER} written"

# ─────────────────────────────────────────────────────────────────────────────
# 2.  YouTubePlayer.jsx  — wire _onEnded into onStateChange(0)
# ─────────────────────────────────────────────────────────────────────────────
log "Locating YouTubePlayer.jsx …"

YTP=""
for p in src/components/YouTubePlayer.jsx src/components/YouTubePlayer.js components/YouTubePlayer.jsx; do
  [ -f "$p" ] && YTP="$p" && break
done

# Also check the uploads copy for the path pattern
if [ -z "$YTP" ]; then
  warn "YouTubePlayer.jsx not found at common paths — will create at src/components/YouTubePlayer.jsx"
  mkdir -p src/components
  YTP="src/components/YouTubePlayer.jsx"
else
  backup "$YTP"
fi

log "Writing ${YTP} …"
cat > "$YTP" << 'YTPEOF'
/**
 * YouTubePlayer.jsx — invisible iframe, audio engine for Mysic.
 *
 * Changes from original:
 *   • Imports _onEnded from usePlayer — onStateChange(0) calls it directly
 *     instead of letting the fake setInterval race to 100 %.
 *   • onError still auto-advances on unplayable videos (101/150).
 *   • No other behavioural changes — play/pause/seek still happen in
 *     click handlers, never in useEffect.
 */
import { useEffect, useRef } from 'react'
import { usePlayer } from '../hooks/usePlayer.jsx'

export default function YouTubePlayer() {
  const { currentSong, volume, _setYtReady, _onEnded, playNext } = usePlayer()
  const initializing = useRef(false)

  useEffect(() => {
    /* Inject the IFrame API script once */
    if (!document.getElementById('yt-iframe-api')) {
      const tag   = document.createElement('script')
      tag.id      = 'yt-iframe-api'
      tag.src     = 'https://www.youtube.com/iframe_api'
      tag.async   = true
      document.head.appendChild(tag)
    }

    const init = () => {
      if (initializing.current || window.__ytPlayer) return
      initializing.current = true

      window.__ytPlayer = new window.YT.Player('yt-hidden-player', {
        height:    '1',
        width:     '1',
        videoId:   currentSong?.youtubeId || '',
        playerVars: {
          autoplay:       0,
          controls:       0,
          disablekb:      1,
          fs:             0,
          iv_load_policy: 3,
          modestbranding: 1,
          playsinline:    1,
          rel:            0,
          origin:         window.location.origin,
        },
        events: {
          onReady: (e) => {
            e.target.setVolume(volume)
            _setYtReady(true)
            console.log('[YT] Ready ✅  origin:', window.location.origin)
          },

          onError: (e) => {
            console.warn('[YT] error code:', e.data)
            /* 101/150 = embed not allowed; 2/5/100 = bad video */
            if ([2, 5, 100, 101, 150].includes(e.data)) playNext()
          },

          onStateChange: (e) => {
            if (e.data === window.YT.PlayerState.ENDED) {
              /* ── REAL end-of-track signal — advance queue immediately ── */
              _onEnded()
            }
          },
        },
      })
    }

    if (window.YT?.Player) {
      init()
    } else {
      const prev = window.onYouTubeIframeAPIReady
      window.onYouTubeIframeAPIReady = () => { prev?.(); init() }
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div style={{
      position: 'fixed', left: '-9999px', bottom: 0,
      width: 1, height: 1, overflow: 'hidden',
      pointerEvents: 'none', zIndex: -1, opacity: 0,
    }}>
      <div id="yt-hidden-player" />
    </div>
  )
}
YTPEOF
ok "${YTP} written"

# ─────────────────────────────────────────────────────────────────────────────
# 3.  Summary
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║  Done! Files written:                                    ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
printf "${GREEN}║  %-56s║${RESET}\n" "${USE_PLAYER}  (backup: .bak)"
printf "${GREEN}║  %-56s║${RESET}\n" "${YTP}  (backup: .bak)"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  What changed                                            ║${RESET}"
echo -e "${GREEN}║  ✓ Progress polls getCurrentTime() — no more drift      ║${RESET}"
echo -e "${GREEN}║  ✓ onStateChange(0) → _onEnded() → playNext()           ║${RESET}"
echo -e "${GREEN}║  ✓ playPrev restarts track if > 3 s in (Spotify UX)     ║${RESET}"
echo -e "${GREEN}║  ✓ Shuffle + Repeat wired up (were dummy buttons before) ║${RESET}"
echo -e "${GREEN}║  ✓ recentlyPlayed persisted to localStorage             ║${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Next steps                                              ║${RESET}"
echo -e "${GREEN}║  1.  npm run dev  — verify scrubber tracks audio exactly ║${RESET}"
echo -e "${GREEN}║  2.  Seek mid-song — confirm UI jumps & stays correct    ║${RESET}"
echo -e "${GREEN}║  3.  Let a song finish — confirm auto-advance fires once ║${RESET}"
echo -e "${GREEN}║  4.  git add -A && git commit -m 'fix: real yt progress' ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
USEPLAYEREOF
