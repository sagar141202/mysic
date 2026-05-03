import { useState } from 'react';
import { getYtThumbnail } from '../utils/ytSearch';

/**
 * AlbumArt — displays a song thumbnail with glassmorphism fallback.
 *
 * Props:
 *   song        — song object (needs .thumbnail and/or .youtubeId)
 *   size        — 'xs' | 'sm' | 'md' | 'lg' | 'xl' (default 'md')
 *   className   — extra classes
 *   animated    — pulse/spin animation when playing (default false)
 *   isPlaying   — whether the song is currently playing (for animation)
 */

const SIZE_MAP = {
  xs: 'w-8 h-8 rounded-md',
  sm: 'w-10 h-10 rounded-lg',
  md: 'w-12 h-12 rounded-xl',
  lg: 'w-16 h-16 rounded-2xl',
  xl: 'w-full aspect-square rounded-2xl',
};

export default function AlbumArt({ song, size = 'md', className = '', animated = false, isPlaying = false }) {
  const [failed, setFailed] = useState(false);
  const [loaded, setLoaded] = useState(false);

  const sizeClass = SIZE_MAP[size] || SIZE_MAP.md;

  // Resolve thumbnail URL
  const thumbUrl = !failed && (
    song?.thumbnail ||
    (song?.youtubeId ? getYtThumbnail(song.youtubeId, 'hq') : null)
  );

  const animClass = animated && isPlaying
    ? 'animate-[spin_20s_linear_infinite]'
    : '';

  return (
    <div
      className={`relative overflow-hidden flex-shrink-0 ${sizeClass} ${className}`}
      style={{ background: 'var(--glass-bg)' }}
    >
      {/* Shimmer skeleton while loading */}
      {!loaded && !failed && (
        <div className="absolute inset-0 animate-pulse rounded-inherit"
          style={{ background: 'linear-gradient(135deg, var(--glass-bg) 0%, rgba(255,255,255,0.08) 50%, var(--glass-bg) 100%)' }} />
      )}

      {thumbUrl ? (
        <img
          src={thumbUrl}
          alt={song?.title || 'Album art'}
          className={`w-full h-full object-cover transition-opacity duration-300 ${loaded ? 'opacity-100' : 'opacity-0'} ${animClass}`}
          onLoad={() => setLoaded(true)}
          onError={() => { setFailed(true); setLoaded(true); }}
          loading="lazy"
          crossOrigin="anonymous"
        />
      ) : null}

      {/* Fallback: music note gradient */}
      {(!thumbUrl || failed) && (
        <div className="absolute inset-0 flex items-center justify-center"
          style={{
            background: 'linear-gradient(135deg, rgba(139,92,246,0.4) 0%, rgba(236,72,153,0.4) 100%)',
          }}>
          <svg viewBox="0 0 24 24" fill="none" className="w-1/2 h-1/2 opacity-70">
            <path d="M9 18V5l12-2v13" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <circle cx="6" cy="18" r="3" stroke="white" strokeWidth="2"/>
            <circle cx="18" cy="16" r="3" stroke="white" strokeWidth="2"/>
          </svg>
        </div>
      )}
    </div>
  );
}
