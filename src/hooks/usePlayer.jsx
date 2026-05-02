import { createContext, useContext, useState, useRef, useCallback } from 'react'
import { SONGS } from '../data/songs'

const PlayerContext = createContext(null)

export function PlayerProvider({ children }) {
  const [currentSong, setCurrentSong] = useState(SONGS[0])
  const [isPlaying,   setIsPlaying]   = useState(false)
  const [progress,    setProgress]    = useState(0)
  const [volume,      setVolume]      = useState(72)
  const [liked,       setLiked]       = useState(new Set())
  const [queue]                       = useState(SONGS)
  const intervalRef = useRef(null)

  const startTick = useCallback((song, fromProgress) => {
    clearInterval(intervalRef.current)
    let prog = fromProgress ?? 0
    intervalRef.current = setInterval(() => {
      prog += (100 / song.duration)
      if (prog >= 100) {
        clearInterval(intervalRef.current)
        setCurrentSong(prev => {
          const idx  = queue.findIndex(s => s.id === prev.id)
          const next = queue[(idx + 1) % queue.length]
          setTimeout(() => startTick(next, 0), 0)
          return next
        })
        setProgress(0)
      } else {
        setProgress(prog)
      }
    }, 1000)
  }, [queue])

  const stopTick = useCallback(() => clearInterval(intervalRef.current), [])

  const playSong = useCallback(song => {
    stopTick()
    setCurrentSong(song)
    setProgress(0)
    setIsPlaying(true)
    startTick(song, 0)
  }, [startTick, stopTick])

  const togglePlay = useCallback(() => {
    setIsPlaying(prev => {
      if (prev) { stopTick() }
      else      { startTick(currentSong, progress) }
      return !prev
    })
  }, [currentSong, progress, startTick, stopTick])

  const playNext = useCallback(() => {
    const idx  = queue.findIndex(s => s.id === currentSong.id)
    playSong(queue[(idx + 1) % queue.length])
  }, [currentSong, queue, playSong])

  const playPrev = useCallback(() => {
    const idx  = queue.findIndex(s => s.id === currentSong.id)
    playSong(queue[(idx - 1 + queue.length) % queue.length])
  }, [currentSong, queue, playSong])

  const seek = useCallback(pct => {
    const clamped = Math.max(0, Math.min(100, pct))
    setProgress(clamped)
    if (isPlaying) { stopTick(); startTick(currentSong, clamped) }
  }, [isPlaying, currentSong, startTick, stopTick])

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
