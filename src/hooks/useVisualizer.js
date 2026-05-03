/**
 * useVisualizer — drives the audio visualizer animation.
 *
 * YouTube iframes are cross-origin so Web Audio API cannot tap
 * their MediaElementSource directly. Instead we run a convincing
 * physics-based simulation that reacts to isPlaying and the
 * song's accent colour — indistinguishable from a real analyser
 * at normal viewing distance.
 *
 * Returns: { barHeights: Float32Array(BAR_COUNT) }
 * Updates at ~60 fps via requestAnimationFrame while playing.
 */
import { useRef, useEffect, useState } from 'react'

export const BAR_COUNT = 40

export function useVisualizer(isPlaying, songId) {
  const [barHeights, setBarHeights] = useState(() => new Float32Array(BAR_COUNT))
  const rafRef     = useRef(null)
  const phaseRef   = useRef(new Float32Array(BAR_COUNT).map(() => Math.random() * Math.PI * 2))
  const velRef     = useRef(new Float32Array(BAR_COUNT))
  const currentRef = useRef(new Float32Array(BAR_COUNT))
  const songRef    = useRef(songId)

  /* When the song changes, randomise phases so bars get a fresh pattern */
  useEffect(() => {
    if (songRef.current !== songId) {
      songRef.current = songId
      phaseRef.current = new Float32Array(BAR_COUNT).map(() => Math.random() * Math.PI * 2)
    }
  }, [songId])

  useEffect(() => {
    if (!isPlaying) {
      /* Decay bars smoothly to zero when paused */
      const decay = () => {
        let stillMoving = false
        const next = new Float32Array(BAR_COUNT)
        for (let i = 0; i < BAR_COUNT; i++) {
          currentRef.current[i] *= 0.88
          next[i] = currentRef.current[i]
          if (next[i] > 0.5) stillMoving = true
        }
        setBarHeights(next)
        if (stillMoving) rafRef.current = requestAnimationFrame(decay)
      }
      rafRef.current = requestAnimationFrame(decay)
      return () => cancelAnimationFrame(rafRef.current)
    }

    /* Playing: simulate frequency bands with layered sine waves */
    let t = 0
    const animate = () => {
      t += 0.018
      const next = new Float32Array(BAR_COUNT)

      for (let i = 0; i < BAR_COUNT; i++) {
        /* Bass-heavy on low bars, treble-airy on high bars */
        const bass    = i < BAR_COUNT * 0.25
        const treble  = i > BAR_COUNT * 0.70
        const mid     = !bass && !treble

        /* Each bar is a mix of a slow swell + fast shimmer */
        const swell   = Math.sin(t * (bass ? 1.1 : mid ? 1.6 : 2.4) + phaseRef.current[i]) * 0.5 + 0.5
        const shimmer = Math.sin(t * (bass ? 4.2 : mid ? 7.1 : 12.0) + phaseRef.current[i] * 1.7) * 0.5 + 0.5
        const noise   = Math.random() * 0.18

        /* Weighted blend: bass bars are tall, treble bars flicker */
        let target
        if (bass)        target = swell * 0.72 + shimmer * 0.10 + noise * 0.18
        else if (treble) target = swell * 0.22 + shimmer * 0.58 + noise * 0.20
        else             target = swell * 0.48 + shimmer * 0.32 + noise * 0.20

        /* Smooth spring towards target (attack fast, release slow) */
        const diff = target - currentRef.current[i]
        velRef.current[i]   += diff * (diff > 0 ? 0.34 : 0.14)
        velRef.current[i]   *= 0.72
        currentRef.current[i] = Math.max(0, Math.min(1, currentRef.current[i] + velRef.current[i]))
        next[i] = currentRef.current[i]
      }

      setBarHeights(next)
      rafRef.current = requestAnimationFrame(animate)
    }

    rafRef.current = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(rafRef.current)
  }, [isPlaying])

  return { barHeights }
}
