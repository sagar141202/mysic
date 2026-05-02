import { useState, useEffect, useRef, useCallback } from 'react'
import { songs } from '../data/songs'

export function usePlayer() {
  const [currentId,  setCurrentId]  = useState(3)
  const [isPlaying,  setIsPlaying]  = useState(false)
  const [progress,   setProgress]   = useState(0)      // 0–1
  const [volume,     setVolume]      = useState(0.72)   // 0–1
  const [isShuffle,  setIsShuffle]  = useState(false)
  const [isRepeat,   setIsRepeat]   = useState(false)
  const [elapsed,    setElapsed]    = useState(0)       // seconds

  const intervalRef = useRef(null)
  const song = songs.find(s => s.id === currentId) || songs[0]

  /* ── tick ── */
  useEffect(() => {
    if (isPlaying) {
      intervalRef.current = setInterval(() => {
        setElapsed(prev => {
          const next = prev + 1
          if (next >= song.duration) {
            // auto-advance
            handleNext()
            return 0
          }
          setProgress(next / song.duration)
          return next
        })
      }, 1000)
    } else {
      clearInterval(intervalRef.current)
    }
    return () => clearInterval(intervalRef.current)
  }, [isPlaying, currentId])

  /* ── reset elapsed when track changes ── */
  useEffect(() => {
    setElapsed(0)
    setProgress(0)
  }, [currentId])

  const play  = useCallback(() => setIsPlaying(true),  [])
  const pause = useCallback(() => setIsPlaying(false), [])
  const toggle = useCallback(() => setIsPlaying(p => !p), [])

  const handleNext = useCallback(() => {
    setCurrentId(id => {
      if (isShuffle) {
        const others = songs.filter(s => s.id !== id)
        return others[Math.floor(Math.random() * others.length)].id
      }
      const idx = songs.findIndex(s => s.id === id)
      return songs[(idx + 1) % songs.length].id
    })
    setIsPlaying(true)
  }, [isShuffle])

  const handlePrev = useCallback(() => {
    setCurrentId(id => {
      const idx = songs.findIndex(s => s.id === id)
      return songs[(idx - 1 + songs.length) % songs.length].id
    })
    setIsPlaying(true)
  }, [])

  const seek = useCallback((ratio) => {
    const newElapsed = Math.floor(ratio * song.duration)
    setElapsed(newElapsed)
    setProgress(ratio)
  }, [song.duration])

  const playSong = useCallback((id) => {
    setCurrentId(id)
    setIsPlaying(true)
  }, [])

  return {
    song, isPlaying, progress, volume, isShuffle, isRepeat,
    elapsed,
    play, pause, toggle,
    next: handleNext,
    prev: handlePrev,
    seek,
    playSong,
    setVolume,
    toggleShuffle: () => setIsShuffle(s => !s),
    toggleRepeat:  () => setIsRepeat(r => !r),
  }
}