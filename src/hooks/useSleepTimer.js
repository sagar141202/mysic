/**
 * useSleepTimer
 *
 * Returns:
 *   remaining   number | null   — seconds left, null = inactive
 *   start(mins) fn              — start timer for N minutes
 *   cancel()    fn              — cancel active timer
 *
 * When timer reaches 0:
 *   1. Fades volume from current → 0 over 20 seconds
 *   2. Calls togglePlay() to pause
 *   3. Restores volume to original level after 1 s
 */
import { useState, useEffect, useRef, useCallback } from 'react'
import { usePlayer } from './usePlayer.jsx'

const LS_KEY = 'mysic:sleeptimer'

export function useSleepTimer() {
  const { setVolume, volume, togglePlay, isPlaying } = usePlayer()
  const volRef      = useRef(volume)
  const isPlayingRef = useRef(isPlaying)
  useEffect(() => { volRef.current = volume },       [volume])
  useEffect(() => { isPlayingRef.current = isPlaying }, [isPlaying])

  /* Restore persisted timer across reloads */
  const [remaining, setRemaining] = useState(() => {
    try {
      const saved = localStorage.getItem(LS_KEY)
      if (!saved) return null
      const { endsAt } = JSON.parse(saved)
      const left = Math.round((endsAt - Date.now()) / 1000)
      return left > 0 ? left : null
    } catch { return null }
  })

  const fadingRef    = useRef(false)
  const tickRef      = useRef(null)

  const cancel = useCallback(() => {
    clearInterval(tickRef.current)
    setRemaining(null)
    fadingRef.current = false
    localStorage.removeItem(LS_KEY)
  }, [])

  const start = useCallback((mins) => {
    cancel()
    const secs  = mins * 60
    const endsAt = Date.now() + secs * 1000
    localStorage.setItem(LS_KEY, JSON.stringify({ endsAt }))
    setRemaining(secs)
  }, [cancel])

  /* Countdown tick every second */
  useEffect(() => {
    if (remaining === null) return
    if (remaining <= 0) {
      /* Already at 0 — start the fade */
      if (!fadingRef.current) {
        fadingRef.current = true
        const startVol  = volRef.current || 70
        const FADE_SECS = 20
        let elapsed     = 0
        const fade = setInterval(() => {
          elapsed++
          const newVol = Math.max(0, startVol * (1 - elapsed / FADE_SECS))
          setVolume(Math.round(newVol))
          if (elapsed >= FADE_SECS) {
            clearInterval(fade)
            if (isPlayingRef.current) togglePlay()
            /* restore volume after brief pause */
            setTimeout(() => setVolume(startVol), 1000)
            cancel()
          }
        }, 1000)
      }
      return
    }

    tickRef.current = setInterval(() => {
      setRemaining(r => {
        if (r === null) return null
        const next = r - 1
        /* Update localStorage with fresh endsAt */
        const endsAt = Date.now() + next * 1000
        localStorage.setItem(LS_KEY, JSON.stringify({ endsAt }))
        return next
      })
    }, 1000)

    return () => clearInterval(tickRef.current)
  }, [remaining])  // eslint-disable-line

  return { remaining, start, cancel }
}
