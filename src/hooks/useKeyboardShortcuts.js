/**
 * useKeyboardShortcuts
 *
 * Call once inside Layout. Attaches a global keydown listener
 * and maps keys → player/nav actions.
 *
 * Keys handled:
 *   Space        — play / pause
 *   ArrowRight   — seek forward  5 s
 *   ArrowLeft    — seek backward 5 s
 *   ArrowUp      — volume +10
 *   ArrowDown    — volume -10
 *   N            — next track
 *   P            — previous track
 *   M            — mute toggle
 *   L            — like / unlike current song
 *   ?            — show shortcut cheat sheet
 *   Escape       — close cheat sheet / close NowPlaying panel
 *
 * Skips entirely when the user is typing in an input/textarea/
 * contenteditable so search bar still works normally.
 *
 * Fires window CustomEvent "mysic:keyflash" with { label }
 * so the KeyFlash overlay can show a HUD bubble.
 */
import { useEffect, useRef } from 'react'
import { usePlayer }         from './usePlayer.jsx'

function flash(label) {
  window.dispatchEvent(new CustomEvent('mysic:keyflash', { detail: { label } }))
}

function isTyping() {
  const el = document.activeElement
  if (!el) return false
  const tag = el.tagName.toLowerCase()
  return tag === 'input' || tag === 'textarea' || el.isContentEditable
}

export function useKeyboardShortcuts({ setShowCheatSheet, setNowPlayingOpen }) {
  const {
    currentSong, isPlaying, progress, volume,
    togglePlay, playNext, playPrev, seek, setVolume,
    toggleLike, liked,
  } = usePlayer()

  /* Keep a ref to volume so the handler always sees latest value
     without needing to re-register the listener on every change */
  const volRef      = useRef(volume)
  const progRef     = useRef(progress)
  const songRef     = useRef(currentSong)
  const playingRef  = useRef(isPlaying)
  const likedRef    = useRef(liked)

  useEffect(() => { volRef.current     = volume       }, [volume])
  useEffect(() => { progRef.current    = progress     }, [progress])
  useEffect(() => { songRef.current    = currentSong  }, [currentSong])
  useEffect(() => { playingRef.current = isPlaying    }, [isPlaying])
  useEffect(() => { likedRef.current   = liked        }, [liked])

  useEffect(() => {
    const handler = e => {
      /* Never intercept when typing */
      if (isTyping()) return

      /* Never intercept browser shortcuts */
      if (e.ctrlKey || e.metaKey || e.altKey) return

      const key = e.key

      switch (key) {
        case ' ':
          e.preventDefault()
          togglePlay()
          flash(playingRef.current ? '⏸' : '▶')
          break

        case 'ArrowRight': {
          e.preventDefault()
          const dur = songRef.current?.duration || 0
          if (!dur) break
          const newPct = Math.min(100, progRef.current + (5 / dur) * 100)
          seek(newPct)
          flash('▶▶ +5s')
          break
        }

        case 'ArrowLeft': {
          e.preventDefault()
          const dur = songRef.current?.duration || 0
          if (!dur) break
          const newPct = Math.max(0, progRef.current - (5 / dur) * 100)
          seek(newPct)
          flash('◀◀ -5s')
          break
        }

        case 'ArrowUp':
          e.preventDefault()
          setVolume(Math.min(100, volRef.current + 10))
          flash(`🔊 ${Math.min(100, Math.round(volRef.current + 10))}%`)
          break

        case 'ArrowDown':
          e.preventDefault()
          setVolume(Math.max(0, volRef.current - 10))
          flash(`🔉 ${Math.max(0, Math.round(volRef.current - 10))}%`)
          break

        case 'n':
        case 'N':
          playNext()
          flash('⏭ Next')
          break

        case 'p':
        case 'P':
          playPrev()
          flash('⏮ Prev')
          break

        case 'm':
        case 'M':
          if (volRef.current > 0) {
            /* Store old volume in a data attr so we can restore */
            document.documentElement.dataset.prevVol = volRef.current
            setVolume(0)
            flash('🔇 Muted')
          } else {
            const prev = parseFloat(document.documentElement.dataset.prevVol || 70)
            setVolume(prev)
            flash(`🔊 ${Math.round(prev)}%`)
          }
          break

        case 'l':
        case 'L': {
          const song = songRef.current
          if (song?.id) {
            toggleLike(song.id, song)
            flash(likedRef.current.has(song.id) ? '♡ Unliked' : '♥ Liked')
          }
          break
        }

        case '?':
          setShowCheatSheet(v => !v)
          break

        case 'Escape':
          setShowCheatSheet(false)
          setNowPlayingOpen(false)
          break

        default:
          break
      }
    }

    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  /* eslint-disable-next-line react-hooks/exhaustive-deps */
  }, [togglePlay, playNext, playPrev, seek, setVolume, toggleLike])
}
