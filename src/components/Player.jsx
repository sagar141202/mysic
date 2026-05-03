import { useRef, useCallback } from 'react'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'

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

function AlbumThumb({ song, size = 44, radius = 12 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: radius, flexShrink: 0,
      background: `linear-gradient(135deg, ${song.color}28, ${song.color}0d)`,
      border: `1px solid ${song.color}35`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.45, boxShadow: `0 4px 14px ${song.color}25`,
    }}>&#9672;</div>
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
        <AlbumThumb song={currentSong} size={40} radius={10} />
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
        <AlbumThumb song={currentSong} size={44} radius={12} />
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
