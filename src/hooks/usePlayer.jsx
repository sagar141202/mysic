import { createContext, useContext, useState, useRef, useCallback } from 'react'
import { SONGS } from '../data/songs'

const PlayerContext = createContext(null)

const ytPlay  = () => { try { window.__ytPlayer?.playVideo()  } catch(_){} }
const ytPause = () => { try { window.__ytPlayer?.pauseVideo() } catch(_){} }
const ytSeek  = (s) => { try { window.__ytPlayer?.seekTo(s, true) } catch(_){} }
const ytVol   = (v) => { try { window.__ytPlayer?.setVolume(v)    } catch(_){} }

export function PlayerProvider({ children }) {
  const [currentSong, setCurrentSong] = useState(SONGS[0])
  const [isPlaying,   setIsPlaying]   = useState(false)
  const [progress,    setProgress]    = useState(0)
  const [volume,      setVolume_]     = useState(72)
  const [liked,       setLiked]       = useState(new Set())
  const [queue,       setQueue]       = useState(SONGS)
  const [_ytReady,    _setYtReady]    = useState(false)
  const intervalRef = useRef(null)

  const startTick = useCallback((song, fromProgress) => {
    clearInterval(intervalRef.current)
    let prog = fromProgress ?? 0
    intervalRef.current = setInterval(() => {
      prog += (100 / song.duration)
      if (prog >= 100) {
        clearInterval(intervalRef.current)
        setCurrentSong(prev => {
          setQueue(q => {
            const idx  = q.findIndex(s => s.id === prev.id)
            const next = q[(idx + 1) % q.length]
            setTimeout(() => startTick(next, 0), 0)
            return q
          })
          return prev // will be updated by startTick callback
        })
        setProgress(0)
      } else {
        setProgress(prog)
      }
    }, 1000)
  }, [])

  const stopTick = useCallback(() => clearInterval(intervalRef.current), [])

  const playSong = useCallback((song, newQueue) => {
    stopTick()
    setCurrentSong(song)
    setProgress(0)
    setIsPlaying(true)
    if (newQueue) setQueue(newQueue)
    startTick(song, 0)
    if (window.__ytPlayer?.loadVideoById) {
      window.__ytPlayer.loadVideoById({ videoId: song.youtubeId, startSeconds: 0 })
    }
  }, [startTick, stopTick])

  const togglePlay = useCallback(() => {
    setIsPlaying(prev => {
      if (prev) { stopTick(); ytPause() }
      else      { startTick(currentSong, progress); ytPlay() }
      return !prev
    })
  }, [currentSong, progress, startTick, stopTick])

  const playNext = useCallback(() => {
    setQueue(q => {
      const idx  = q.findIndex(s => s.id === currentSong.id)
      const next = q[(idx + 1) % q.length]
      stopTick()
      setCurrentSong(next)
      setProgress(0)
      setIsPlaying(true)
      startTick(next, 0)
      if (window.__ytPlayer?.loadVideoById) {
        window.__ytPlayer.loadVideoById({ videoId: next.youtubeId, startSeconds: 0 })
      }
      return q
    })
  }, [currentSong, startTick, stopTick])

  const playPrev = useCallback(() => {
    setQueue(q => {
      const idx  = q.findIndex(s => s.id === currentSong.id)
      const prev = q[(idx - 1 + q.length) % q.length]
      stopTick()
      setCurrentSong(prev)
      setProgress(0)
      setIsPlaying(true)
      startTick(prev, 0)
      if (window.__ytPlayer?.loadVideoById) {
        window.__ytPlayer.loadVideoById({ videoId: prev.youtubeId, startSeconds: 0 })
      }
      return q
    })
  }, [currentSong, startTick, stopTick])

  const seek = useCallback(pct => {
    const clamped = Math.max(0, Math.min(100, pct))
    setProgress(clamped)
    if (isPlaying) { stopTick(); startTick(currentSong, clamped) }
    ytSeek((clamped / 100) * currentSong.duration)
  }, [isPlaying, currentSong, startTick, stopTick])

  const setVolume = useCallback(v => {
    setVolume_(v)
    ytVol(v)
  }, [])

  const toggleLike = useCallback(id => {
    setLiked(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }, [])

  return (
    <PlayerContext.Provider value={{
      currentSong, isPlaying, progress, volume, liked, queue,
      playSong, togglePlay, playNext, playPrev, seek, setVolume, toggleLike,
      setQueue, _ytReady, _setYtReady,
    }}>
      {children}
    </PlayerContext.Provider>
  )
}

export function usePlayer() {
  const ctx = useContext(PlayerContext)
  if (!ctx) throw new Error('usePlayer must be inside PlayerProvider')
  return ctx
}
