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
