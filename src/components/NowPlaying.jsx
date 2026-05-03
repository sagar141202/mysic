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
