/**
 * YouTubePlayer — invisible iframe, only handles init + error/end events.
 * Play/pause/seek/load are now called directly in usePlayer gesture handlers.
 */
import { useEffect, useRef } from 'react'
import { usePlayer } from '../hooks/usePlayer.jsx'

export default function YouTubePlayer() {
  const { currentSong, volume, _setYtReady, playNext } = usePlayer()
  const initializing = useRef(false)

  useEffect(() => {
    /* inject script once */
    if (!document.getElementById('yt-iframe-api')) {
      const tag = document.createElement('script')
      tag.id    = 'yt-iframe-api'
      tag.src   = 'https://www.youtube.com/iframe_api'
      tag.async = true
      document.head.appendChild(tag)
    }

    const init = () => {
      if (initializing.current || window.__ytPlayer) return
      initializing.current = true

      window.__ytPlayer = new window.YT.Player('yt-hidden-player', {
        height:    '1',
        width:     '1',
        videoId:   currentSong.youtubeId,
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
            console.warn('[YT] error code:', e.data, '— skipping')
            /* 101/150 = embed not allowed for this video */
            if ([2, 5, 100, 101, 150].includes(e.data)) playNext()
          },
          onStateChange: (e) => {
            /* 0 = ended */
            if (e.data === 0) playNext()
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
