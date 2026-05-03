import { useState } from 'react'
import { getYtThumbnail } from '../utils/ytSearch'

/**
 * AlbumArt — song thumbnail with shimmer skeleton + graceful gradient fallback.
 *
 * Props:
 *   song       — song object (.thumbnail and/or .youtubeId)
 *   size       — 'xs' | 'sm' | 'md' | 'lg' | 'xl'
 *   className  — extra CSS classes
 *   isPlaying  — pulse ring animation when true
 */
const SIZE_MAP = {
  xs: { box: 28,  radius: 8,  note: 12 },
  sm: { box: 40,  radius: 10, note: 16 },
  md: { box: 48,  radius: 12, note: 20 },
  lg: { box: 64,  radius: 16, note: 26 },
  xl: { box: '100%', radius: 18, note: 36, aspect: true },
}

export default function AlbumArt({ song, size = 'md', className = '', isPlaying = false }) {
  const [failed, setFailed] = useState(false)
  const [loaded, setLoaded] = useState(false)

  const s = SIZE_MAP[size] || SIZE_MAP.md
  const boxStyle = s.aspect
    ? { width: '100%', aspectRatio: '1', borderRadius: s.radius }
    : { width: s.box, height: s.box, borderRadius: s.radius }

  const thumbUrl = !failed && (
    song?.thumbnail ||
    (song?.youtubeId ? getYtThumbnail(song.youtubeId, 'hq') : null)
  )

  const accentColor = song?.color || '#8b5cf6'

  return (
    <div
      className={className}
      style={{
        ...boxStyle,
        position: 'relative',
        overflow: 'hidden',
        flexShrink: 0,
        background: `linear-gradient(135deg, ${accentColor}28, ${accentColor}0d)`,
        border: `1px solid ${accentColor}${isPlaying ? '55' : '30'}`,
        boxShadow: isPlaying ? `0 0 0 2px ${accentColor}40, 0 0 16px ${accentColor}30` : 'none',
        transition: 'box-shadow 0.3s ease',
      }}
    >
      {/* Shimmer skeleton while loading */}
      {!loaded && !failed && thumbUrl && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'linear-gradient(90deg, rgba(255,255,255,0.03) 0%, rgba(255,255,255,0.08) 50%, rgba(255,255,255,0.03) 100%)',
          backgroundSize: '200% 100%',
          animation: 'shimmer 1.5s infinite',
        }} />
      )}

      {/* Thumbnail image */}
      {thumbUrl && (
        <img
          src={thumbUrl}
          alt={song?.title || 'Album art'}
          style={{
            width: '100%', height: '100%', objectFit: 'cover',
            opacity: loaded ? 1 : 0,
            transition: 'opacity 0.3s ease',
            display: 'block',
          }}
          onLoad={e => {
            setLoaded(true)
            /* For the large NowPlaying art, pre-warm colour extraction */
            if (size === 'xl' && thumbUrl) {
              extractColors(thumbUrl, 3).then(({ hex }) => {
                /* Dispatch so any listener can react; useDynamicTheme
                   already handles this via song id — this is a fast-path
                   for when the image loads before the hook fires.       */
                window.dispatchEvent(new CustomEvent('mysic:palette', {
                  detail: { hex, src: thumbUrl }
                }))
              })
            }
          }}
          onError={() => { setFailed(true); setLoaded(true) }}
          loading="lazy"
          crossOrigin="anonymous"
        />
      )}

      {/* Fallback: music note on gradient */}
      {(!thumbUrl || failed) && (
        <div style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg
            viewBox="0 0 24 24" fill="none"
            style={{ width: s.note, height: s.note, opacity: 0.7 }}
          >
            <path d="M9 18V5l12-2v13" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <circle cx="6" cy="18" r="3" stroke="white" strokeWidth="2"/>
            <circle cx="18" cy="16" r="3" stroke="white" strokeWidth="2"/>
          </svg>
        </div>
      )}
    </div>
  )
}
