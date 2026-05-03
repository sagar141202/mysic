#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
# Mysic — Album Art patch script
# Run from the repo root: bash patch_mysic.sh
# ─────────────────────────────────────────────

REPO_ROOT="$(pwd)"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Mysic Album Art Patcher — Starting     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Safety check ──────────────────────────────
if [ ! -f "$REPO_ROOT/vite.config.js" ]; then
  echo "❌  Run this script from the mysic repo root (where vite.config.js lives)."
  exit 1
fi
echo "✅  Repo root confirmed: $REPO_ROOT"
echo ""

# ══════════════════════════════════════════════
# STEP 1 — Patch src/utils/ytSearch.js
# ══════════════════════════════════════════════
echo "─── Step 1/4: Patching src/utils/ytSearch.js ───"

cat > "$REPO_ROOT/src/utils/ytSearch.js" << 'YTSEARCH_EOF'
// ─────────────────────────────────────────────────────────────────────────────
// ytSearch.js — free YouTube search, no API key required
//
// Exports:
//   ytSearch(query)              — primary export used by DiscoverPage, LibraryPage
//   searchYouTube(query, count)  — alias used by MainContent
//   getYtThumbnail(videoId, quality) — returns a YouTube thumbnail URL
// ─────────────────────────────────────────────────────────────────────────────

const COLORS = [
  '#06b6d4','#8b5cf6','#ec4899','#f59e0b',
  '#10b981','#3b82f6','#f97316','#14b8a6',
]

/**
 * Returns a YouTube thumbnail URL.
 * quality: 'maxres' | 'sd' | 'hq' (default) | 'mq' | 'default'
 */
export function getYtThumbnail(videoId, quality = 'hq') {
  if (!videoId) return null
  const suffix =
    quality === 'maxres' ? 'maxresdefault' :
    quality === 'sd'     ? 'sddefault'     :
    quality === 'mq'     ? 'mqdefault'     :
    quality === 'default'? 'default'        :
    'hqdefault'  // 'hq' → hqdefault
  return `https://i.ytimg.com/vi/${videoId}/${suffix}.jpg`
}

/** Pick the best thumbnail URL from a ytInitialData video renderer object */
function extractThumbnail(renderer) {
  try {
    const thumbs =
      renderer?.thumbnail?.thumbnails ||
      renderer?.thumbnailOverlays?.[0]?.thumbnailOverlayTimeStatusRenderer?.thumbnail?.thumbnails ||
      []
    if (!thumbs.length) return getYtThumbnail(renderer?.videoId, 'hq')
    // prefer largest width
    const best = thumbs.reduce((a, b) => ((b.width || 0) > (a.width || 0) ? b : a))
    return best.url || getYtThumbnail(renderer?.videoId, 'hq')
  } catch {
    return null
  }
}

/** Parse ytInitialData HTML blob → song array */
function parseResults(html, maxCount) {
  const match = html.match(/var ytInitialData\s*=\s*(\{.+?\});\s*(?:\/\/|<\/script>)/)
  if (!match) return []

  let data
  try { data = JSON.parse(match[1]) } catch { return [] }

  const contents =
    data?.contents?.twoColumnSearchResultsRenderer?.primaryContents
      ?.sectionListRenderer?.contents ?? []

  const items = []
  for (const section of contents) {
    const rows =
      section?.itemSectionRenderer?.contents ??
      section?.continuationItemRenderer ? [] : []
    for (const row of rows) {
      const vr = row?.videoRenderer
      if (!vr?.videoId) continue

      const title  = vr.title?.runs?.[0]?.text ?? 'Unknown'
      const artist = vr.ownerText?.runs?.[0]?.text ?? vr.shortBylineText?.runs?.[0]?.text ?? 'Unknown'
      const thumb  = extractThumbnail(vr)

      // duration
      let duration = 210
      try {
        const parts = vr.lengthText?.simpleText?.split(':').map(Number) ?? []
        if (parts.length === 2) duration = parts[0] * 60 + parts[1]
        if (parts.length === 3) duration = parts[0] * 3600 + parts[1] * 60 + parts[2]
      } catch { /* keep default */ }

      items.push({
        id:        vr.videoId,
        youtubeId: vr.videoId,
        title,
        artist,
        duration,
        thumbnail: thumb,
        color: COLORS[items.length % COLORS.length],
      })

      if (items.length >= maxCount) break
    }
    if (items.length >= maxCount) break
  }
  return items
}

/** Fetch via Vite proxy (dev) */
async function fetchViaProxy(query) {
  const url = `/ytproxy/results?search_query=${encodeURIComponent(query)}&hl=en`
  const res  = await fetch(url, { headers: { 'Accept-Language': 'en-US,en;q=0.9' } })
  if (!res.ok) throw new Error(`proxy ${res.status}`)
  return res.text()
}

/** Fetch via allorigins fallback */
async function fetchViaAllOrigins(query) {
  const yt  = `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}&hl=en`
  const url = `https://api.allorigins.win/get?url=${encodeURIComponent(yt)}`
  const res  = await fetch(url)
  if (!res.ok) throw new Error(`allorigins ${res.status}`)
  const json = await res.json()
  return json.contents
}

/**
 * Primary export — takes ONE argument (query).
 * DiscoverPage and other pages import this as:
 *   import { ytSearch as searchYouTube } from '../utils/ytSearch'
 */
export async function ytSearch(query) {
  const MAX = 20
  let html = ''
  try {
    html = await fetchViaProxy(query)
  } catch (e) {
    console.warn('[ytSearch] proxy failed, trying allorigins:', e.message)
    try {
      html = await fetchViaAllOrigins(query)
    } catch (e2) {
      console.error('[ytSearch] both methods failed:', e2.message)
      return []
    }
  }
  return parseResults(html, MAX)
}

/**
 * Alias for MainContent — accepts optional count arg (ignored internally,
 * kept for API compatibility so MainContent doesn't need changes).
 */
export async function searchYouTube(query, _count) {
  return ytSearch(query)
}
YTSEARCH_EOF

echo "  ✅  ytSearch.js written"
echo ""

# ══════════════════════════════════════════════
# STEP 2 — Write src/components/AlbumArt.jsx
# ══════════════════════════════════════════════
echo "─── Step 2/4: Writing src/components/AlbumArt.jsx ───"

cat > "$REPO_ROOT/src/components/AlbumArt.jsx" << 'ALBUMART_EOF'
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
          onLoad={() => setLoaded(true)}
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
ALBUMART_EOF

echo "  ✅  AlbumArt.jsx written"
echo ""

# ══════════════════════════════════════════════
# STEP 3 — Patch src/components/SongList.jsx
# (replace inline thumb div with <AlbumArt>)
# ══════════════════════════════════════════════
echo "─── Step 3/4: Patching src/components/SongList.jsx ───"

cat > "$REPO_ROOT/src/components/SongList.jsx" << 'SONGLIST_EOF'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

export default function SongList({ songs, showIndex = true }) {
  const { currentSong, isPlaying, playSong, togglePlay, toggleLike, liked } = usePlayer()

  if (!songs?.length) return (
    <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}>
      No songs found
    </div>
  )

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      {songs.map((song, i) => {
        const active  = currentSong.id === song.id
        const playing = active && isPlaying
        const isLiked = liked.has(song.id)
        return (
          <div
            key={song.id}
            onClick={() => active ? togglePlay() : playSong(song, songs)}
            style={{
              display: 'grid',
              gridTemplateColumns: showIndex ? '28px auto 1fr auto auto' : 'auto 1fr auto auto',
              gap: 12, padding: '9px 12px', borderRadius: 12,
              cursor: 'pointer', alignItems: 'center',
              background: active ? 'rgba(34,211,238,0.06)' : 'transparent',
              border: `1px solid ${active ? 'rgba(34,211,238,0.18)' : 'transparent'}`,
              transition: 'all 0.2s',
            }}
            onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
            onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}}
          >
            {showIndex && (
              <span style={{ fontSize: 11, textAlign: 'center', color: active ? 'var(--accent-primary)' : 'var(--text-muted)', fontWeight: active ? 600 : 400 }}>
                {playing ? '▶' : active ? '❚❚' : i + 1}
              </span>
            )}

            <AlbumArt song={song} size="sm" isPlaying={playing} />

            <div style={{ minWidth: 0 }}>
              <p style={{ fontSize: 13, margin: 0, fontWeight: active ? 500 : 400, color: active ? 'var(--accent-primary)' : 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {song.title}
              </p>
              <p style={{ fontSize: 11, margin: 0, color: 'var(--text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {song.artist}
              </p>
            </div>

            <button
              onClick={e => { e.stopPropagation(); toggleLike(song.id, song) }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.5))' : 'none', transition: 'all 0.2s', padding: '0 4px' }}
              onMouseEnter={e => { if (!isLiked) e.currentTarget.style.color = 'var(--text-primary)' }}
              onMouseLeave={e => { if (!isLiked) e.currentTarget.style.color = 'var(--text-muted)' }}
            >{isLiked ? '\u2665' : '\u2661'}</button>

            <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 32, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>
              {formatTime(song.duration)}
            </span>
          </div>
        )
      })}
    </div>
  )
}
SONGLIST_EOF

echo "  ✅  SongList.jsx patched"
echo ""

# ══════════════════════════════════════════════
# STEP 4 — Patch NowPlaying.jsx + Player.jsx
# (replace static emoji/gradient art with AlbumArt)
# ══════════════════════════════════════════════
echo "─── Step 4/4: Patching NowPlaying.jsx and Player.jsx ───"

# ── NowPlaying.jsx ──
cat > "$REPO_ROOT/src/components/NowPlaying.jsx" << 'NOWPLAYING_EOF'
import { useRef, useCallback } from 'react'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

function Scrubber({ pct, onSeek }) {
  const dragging = useRef(false)
  const calc = (e, el) => {
    const rect = el.getBoundingClientRect()
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left
    return Math.max(0, Math.min(100, (x / rect.width) * 100))
  }
  const onMouseDown = useCallback(e => {
    dragging.current = true
    onSeek(calc(e, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev, el)) }
    const onUp   = ()  => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }, [onSeek])
  return (
    <div onMouseDown={onMouseDown} style={{
      flex: 1, height: 4, borderRadius: 4,
      background: 'rgba(255,255,255,0.08)', cursor: 'pointer', position: 'relative',
    }}>
      <div style={{
        width: `${pct}%`, height: '100%', borderRadius: 4,
        background: 'var(--accent-grad)', position: 'relative',
        transition: 'width 0.9s linear',
      }}>
        <div style={{
          position: 'absolute', right: -5, top: '50%', transform: 'translateY(-50%)',
          width: 12, height: 12, borderRadius: '50%', background: 'white',
          boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.25)',
        }} />
      </div>
    </div>
  )
}

function Btn({ children, onClick, size = 36, primary = false, title }) {
  return (
    <button title={title} onClick={onClick} style={{
      width: size, height: size, borderRadius: '50%', flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)',
      border: primary ? 'none' : '1px solid rgba(255,255,255,0.08)',
      color: primary ? '#08121f' : 'var(--text-secondary)',
      fontSize: primary ? 19 : 14, cursor: 'pointer',
      boxShadow: primary ? '0 6px 20px rgba(34,211,238,0.38)' : 'none',
      transition: 'transform 0.18s, box-shadow 0.18s, background 0.18s, color 0.18s, border-color 0.18s',
    }}
    onMouseEnter={e => {
      if (primary) { e.currentTarget.style.transform = 'scale(1.07)'; e.currentTarget.style.boxShadow = '0 8px 28px rgba(34,211,238,0.55)' }
      else { e.currentTarget.style.background = 'rgba(34,211,238,0.09)'; e.currentTarget.style.borderColor = 'rgba(34,211,238,0.30)'; e.currentTarget.style.color = 'var(--accent-primary)' }
    }}
    onMouseLeave={e => {
      if (primary) { e.currentTarget.style.transform = 'scale(1)'; e.currentTarget.style.boxShadow = '0 6px 20px rgba(34,211,238,0.38)' }
      else { e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.08)'; e.currentTarget.style.color = 'var(--text-secondary)' }
    }}
    >{children}</button>
  )
}

export default function NowPlaying({ onClose }) {
  const { currentSong, isPlaying, progress, volume, togglePlay, playNext, playPrev, seek, setVolume, toggleLike, liked, queue } = usePlayer()
  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)

  const upNext = (() => {
    const idx = queue.findIndex(s => s.id === currentSong.id)
    return [1, 2, 3].map(o => queue[(idx + o) % queue.length])
  })()

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      padding: '22px 18px',
      background: 'rgba(8,12,20,0.74)',
      backdropFilter: 'blur(30px)', WebkitBackdropFilter: 'blur(30px)',
      borderLeft: '1px solid rgba(255,255,255,0.06)',
      fontFamily: 'var(--font-body)', overflowY: 'auto',
    }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 22 }}>
        <p style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.12em', textTransform: 'uppercase', margin: 0 }}>Now Playing</p>
        {onClose && (
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 16, cursor: 'pointer', transition: 'color 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
          >&#10005;</button>
        )}
      </div>

      {/* Album Art — large, xl size, animated when playing */}
      <div style={{
        marginBottom: 22, borderRadius: 18, overflow: 'hidden',
        boxShadow: `0 20px 60px ${currentSong.color || '#8b5cf6'}30`,
        transition: 'box-shadow 0.5s',
      }}>
        <AlbumArt song={currentSong} size="xl" isPlaying={isPlaying} />
      </div>

      {/* Track info */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 18 }}>
        <div style={{ minWidth: 0, flex: 1 }}>
          <h3 style={{ fontFamily: 'var(--font-display)', fontSize: 17, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 4px', lineHeight: 1.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.title}</h3>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
        </div>
        <button onClick={() => toggleLike(currentSong.id, currentSong)} style={{
          background: 'none', border: 'none', fontSize: 18, cursor: 'pointer', marginLeft: 8, flexShrink: 0,
          color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
          filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none',
          transition: 'all 0.2s',
        }}>{isLiked ? '\u2665' : '\u2661'}</button>
      </div>

      {/* Progress */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <Scrubber pct={progress} onSeek={seek} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 7 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSec)}</span>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSong.duration)}</span>
        </div>
      </div>

      {/* Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, marginBottom: 20 }}>
        <Btn title="Shuffle">&#8700;</Btn>
        <Btn title="Previous" onClick={playPrev}>&#9198;</Btn>
        <Btn primary size={52} title={isPlaying ? 'Pause' : 'Play'} onClick={togglePlay}>{isPlaying ? '\u23F8' : '\u25B6'}</Btn>
        <Btn title="Next" onClick={playNext}>&#9197;</Btn>
        <Btn title="Repeat">&#8635;</Btn>
      </div>

      {/* Volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 24 }}>
        <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>{volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}</span>
        <Scrubber pct={volume} onSeek={setVolume} />
        <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums' }}>{Math.round(volume)}%</span>
      </div>

      {/* Up Next */}
      <div style={{ borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: 18, flex: 1 }}>
        <p style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.12em', color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 12 }}>Up Next</p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {upNext.map((song, i) => (
            <div key={`${song.id}-${i}`} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px', borderRadius: 10, cursor: 'pointer',
              transition: 'background 0.2s, border-color 0.2s',
              border: '1px solid transparent',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}
            >
              <AlbumArt song={song} size="xs" />
              <div style={{ minWidth: 0, flex: 1 }}>
                <p style={{ fontSize: 12, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
                <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>{song.artist}</p>
              </div>
              <span style={{ fontSize: 10, color: 'var(--text-muted)', flexShrink: 0 }}>{formatTime(song.duration)}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
NOWPLAYING_EOF

echo "  ✅  NowPlaying.jsx patched"

# ── Player.jsx ──
cat > "$REPO_ROOT/src/components/Player.jsx" << 'PLAYER_EOF'
import { useRef, useCallback } from 'react'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

function useScrubber(onSeek) {
  const dragging = useRef(false)
  const calc = (e, el) => {
    const rect = el.getBoundingClientRect()
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left
    return Math.max(0, Math.min(100, (x / rect.width) * 100))
  }
  const onMouseDown = useCallback(e => {
    dragging.current = true
    onSeek(calc(e, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev, el)) }
    const onUp   = ()  => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }, [onSeek])
  return { onMouseDown }
}

function Scrubber({ pct, onSeek, width = '100%', accent = 'var(--accent-grad)' }) {
  const { onMouseDown } = useScrubber(onSeek)
  return (
    <div onMouseDown={onMouseDown} style={{
      width, height: 4, borderRadius: 4,
      background: 'rgba(255,255,255,0.08)',
      cursor: 'pointer', position: 'relative', flexShrink: 0,
    }}>
      <div style={{
        width: `${pct}%`, height: '100%', borderRadius: 4,
        background: accent, position: 'relative',
        transition: 'width 0.9s linear',
      }}>
        <div style={{
          position: 'absolute', right: -5, top: '50%', transform: 'translateY(-50%)',
          width: 12, height: 12, borderRadius: '50%', background: 'white',
          boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.25)',
        }} />
      </div>
    </div>
  )
}

function Btn({ children, onClick, size = 32, primary = false, title }) {
  return (
    <button title={title} onClick={onClick} style={{
      width: size, height: size, borderRadius: '50%', flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)',
      border: primary ? 'none' : '1px solid rgba(255,255,255,0.09)',
      color: primary ? '#08121f' : 'var(--text-secondary)',
      fontSize: primary ? 15 : 13, cursor: 'pointer',
      boxShadow: primary ? '0 4px 16px rgba(34,211,238,0.38)' : 'none',
      transition: 'transform 0.18s, box-shadow 0.18s, background 0.18s, color 0.18s, border-color 0.18s',
    }}
    onMouseEnter={e => {
      if (primary) { e.currentTarget.style.transform = 'scale(1.07)'; e.currentTarget.style.boxShadow = '0 6px 24px rgba(34,211,238,0.55)' }
      else { e.currentTarget.style.background = 'rgba(34,211,238,0.09)'; e.currentTarget.style.borderColor = 'rgba(34,211,238,0.30)'; e.currentTarget.style.color = 'var(--accent-primary)' }
    }}
    onMouseLeave={e => {
      if (primary) { e.currentTarget.style.transform = 'scale(1)'; e.currentTarget.style.boxShadow = '0 4px 16px rgba(34,211,238,0.38)' }
      else { e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.09)'; e.currentTarget.style.color = 'var(--text-secondary)' }
    }}
    >{children}</button>
  )
}

function MobilePlayer({ onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, togglePlay, playNext } = usePlayer()
  return (
    <div style={{ fontFamily: 'var(--font-body)', background: 'rgba(8,12,20,0.95)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
      <div style={{ height: 2, background: 'rgba(255,255,255,0.06)' }}>
        <div style={{ width: `${progress}%`, height: '100%', background: 'var(--accent-grad)', transition: 'width 0.9s linear' }} />
      </div>
      <div onClick={onNowPlayingClick} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px', cursor: 'pointer' }}>
        <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.title}</p>
          <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
        </div>
        <Btn primary size={34} onClick={e => { e.stopPropagation(); togglePlay() }} title={isPlaying ? 'Pause' : 'Play'}>{isPlaying ? '\u23F8' : '\u25B6'}</Btn>
        <Btn size={30} onClick={e => { e.stopPropagation(); playNext() }} title="Next">&#9197;</Btn>
      </div>
    </div>
  )
}

export default function Player({ mobile = false, onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, volume, togglePlay, playNext, playPrev, seek, setVolume, toggleLike, liked } = usePlayer()
  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)

  if (mobile) return <MobilePlayer onNowPlayingClick={onNowPlayingClick} />

  return (
    <div style={{
      height: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
      alignItems: 'center', padding: '0 22px',
      background: 'rgba(8,12,20,0.92)', backdropFilter: 'blur(30px)',
      borderTop: '1px solid rgba(255,255,255,0.06)', fontFamily: 'var(--font-body)',
    }}>

      {/* Left: track info */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
        <div style={{ minWidth: 0 }}>
          <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 140 }}>{currentSong.title}</p>
          <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
        </div>
        <button onClick={() => toggleLike(currentSong.id, currentSong)} style={{
          background: 'none', border: 'none', flexShrink: 0, fontSize: 16, cursor: 'pointer',
          color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
          filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none',
          transition: 'all 0.2s',
        }}>{isLiked ? '\u2665' : '\u2661'}</button>
      </div>

      {/* Centre: controls + scrubber */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <Btn title="Shuffle">&#8700;</Btn>
          <Btn title="Previous" onClick={playPrev}>&#9198;</Btn>
          <Btn primary size={38} title={isPlaying ? 'Pause' : 'Play'} onClick={togglePlay}>{isPlaying ? '\u23F8' : '\u25B6'}</Btn>
          <Btn title="Next" onClick={playNext}>&#9197;</Btn>
          <Btn title="Repeat">&#8635;</Btn>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', maxWidth: 340 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSec)}</span>
          <Scrubber pct={progress} onSeek={seek} />
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSong.duration)}</span>
        </div>
      </div>

      {/* Right: volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, justifyContent: 'flex-end' }}>
        {['\u2630', '\u229E'].map(icon => (
          <button key={icon} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
          >{icon}</button>
        ))}
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}</span>
          <Scrubber pct={volume} onSeek={setVolume} width="80px" accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
        </div>
      </div>
    </div>
  )
}
PLAYER_EOF

echo "  ✅  Player.jsx patched"
echo ""

# ══════════════════════════════════════════════
# STEP 5 — Add shimmer keyframe to index.css
# (only if not already there)
# ══════════════════════════════════════════════
echo "─── Step 5/5: Adding shimmer keyframe to index.css ───"

if ! grep -q "@keyframes shimmer" "$REPO_ROOT/src/index.css" 2>/dev/null; then
  cat >> "$REPO_ROOT/src/index.css" << 'CSS_EOF'

/* ── Album Art shimmer ────────────────────── */
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position:  200% 0; }
}
CSS_EOF
  echo "  ✅  shimmer keyframe added to index.css"
else
  echo "  ⏭  shimmer keyframe already present — skipped"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ✅  All patches applied successfully!  ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Files modified:                         ║"
echo "║    src/utils/ytSearch.js                 ║"
echo "║    src/components/AlbumArt.jsx           ║"
echo "║    src/components/SongList.jsx           ║"
echo "║    src/components/NowPlaying.jsx         ║"
echo "║    src/components/Player.jsx             ║"
echo "║    src/index.css  (shimmer keyframe)     ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Now run:  npm run dev                   ║"
echo "╚══════════════════════════════════════════╝"
echo ""
