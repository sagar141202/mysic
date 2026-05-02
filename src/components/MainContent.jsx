import { useState } from 'react'
import GlassCard from './GlassCard'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { SONGS, FEATURED, COLLECTIONS, getSongById, formatTime } from '../data/songs'

export default function MainContent({ screenSize = 'desktop' }) {
  const [search, setSearch] = useState('')
  const isMobile = screenSize === 'mobile'
  const isTablet = screenSize === 'tablet'
  const { currentSong, isPlaying, playSong, togglePlay, toggleLike, liked } = usePlayer()

  const filtered = SONGS.filter(s =>
    s.title.toLowerCase().includes(search.toLowerCase()) ||
    s.artist.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: isMobile ? '18px 14px 8px' : '24px 22px', fontFamily: 'var(--font-body)' }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', marginBottom: 4 }}>Good Evening</p>
          <h1 style={{ fontFamily: 'var(--font-display)', fontSize: isMobile ? 20 : 26, fontWeight: 800, lineHeight: 1.15, margin: 0, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>
            What's the vibe?
          </h1>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {(isMobile ? ['\uD83D\uDD14'] : ['\uD83D\uDD14', '\u2299', '\u2699']).map(icon => (
            <button key={icon} style={{
              width: 36, height: 36, borderRadius: '50%',
              background: 'var(--glass-bg)', border: '1px solid var(--glass-border)',
              backdropFilter: 'blur(12px)', color: 'var(--text-secondary)',
              fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: 'all 0.25s',
            }}
            onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(34,211,238,0.35)'; e.currentTarget.style.background = 'rgba(34,211,238,0.06)'; e.currentTarget.style.color = 'var(--accent-primary)' }}
            onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--glass-border)'; e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.color = 'var(--text-secondary)' }}
            >{icon}</button>
          ))}
        </div>
      </div>

      {/* Search */}
      <div style={{ position: 'relative', marginBottom: 28 }}>
        <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14, pointerEvents: 'none' }}>&#8857;</span>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search songs, artists, playlists..."
          style={{
            width: '100%', boxSizing: 'border-box', padding: '12px 16px 12px 40px',
            background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)',
            borderRadius: 14, outline: 'none', color: 'var(--text-primary)', fontSize: 13,
            fontFamily: 'var(--font-body)', backdropFilter: 'blur(12px)', transition: 'all 0.25s',
          }}
          onFocus={e => { e.target.style.borderColor = 'rgba(34,211,238,0.40)'; e.target.style.background = 'rgba(34,211,238,0.04)'; e.target.style.boxShadow = '0 0 0 3px rgba(34,211,238,0.07)' }}
          onBlur={e => { e.target.style.borderColor = 'rgba(255,255,255,0.07)'; e.target.style.background = 'rgba(255,255,255,0.03)'; e.target.style.boxShadow = 'none' }}
        />
      </div>

      {/* Collections */}
      {!isMobile && !search && (
        <div style={{ marginBottom: 28 }}>
          <SectionHeader title="Collections" />
          <div style={{ display: 'grid', gridTemplateColumns: isTablet ? 'repeat(2,1fr)' : 'repeat(4,1fr)', gap: 10 }}>
            {COLLECTIONS.map(c => (
              <GlassCard key={c.name} variant="elevated" padding="14px" radius={14} onClick={() => {}} style={{ overflow: 'hidden' }}>
                <div style={{ position: 'absolute', top: -16, right: -16, width: 64, height: 64, borderRadius: '50%', background: `${c.color}20`, filter: 'blur(14px)', pointerEvents: 'none' }} />
                <div style={{ width: 36, height: 36, borderRadius: 10, marginBottom: 10, background: `${c.color}18`, border: `1px solid ${c.color}35`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, boxShadow: `0 4px 12px ${c.color}20` }}>&#9834;</div>
                <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', margin: '0 0 2px', fontFamily: 'var(--font-display)' }}>{c.name}</p>
                <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>{c.count}</p>
              </GlassCard>
            ))}
          </div>
        </div>
      )}

      {/* Featured */}
      {!search && (
        <div style={{ marginBottom: 28 }}>
          <SectionHeader title="Featured" />
          <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(3,1fr)', gap: 10 }}>
            {(isMobile ? FEATURED.slice(0, 1) : FEATURED).map(f => {
              const song    = getSongById(f.songId)
              if (!song) return null
              const isActive = currentSong.id === song.id
              return (
                <GlassCard key={song.id} variant="elevated" padding="18px 16px" radius={16}
                  active={isActive}
                  onClick={() => isActive ? togglePlay() : playSong(song)}
                  style={{ overflow: 'hidden' }}
                >
                  <div style={{ position: 'absolute', top: -24, right: -24, width: 96, height: 96, borderRadius: '50%', background: `radial-gradient(circle, ${song.color}28, transparent 70%)`, filter: 'blur(16px)', pointerEvents: 'none' }} />
                  <div style={{ position: 'relative', zIndex: 1 }}>
                    <div style={{ fontSize: 26, marginBottom: 10, filter: `drop-shadow(0 0 10px ${song.color}70)` }}>&#9672;</div>
                    <p style={{ fontFamily: 'var(--font-display)', fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', margin: '0 0 3px' }}>{song.title}</p>
                    <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: '0 0 8px' }}>{song.artist}</p>
                    <p style={{ fontSize: 10, color: song.color, margin: 0, opacity: 0.8 }}>{f.plays} plays</p>
                  </div>
                  <button style={{
                    position: 'absolute', top: 14, right: 14, zIndex: 2,
                    width: 30, height: 30, borderRadius: '50%',
                    background: `${song.color}18`, border: `1px solid ${song.color}40`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 10, color: song.color, cursor: 'pointer', transition: 'all 0.2s',
                  }}
                  onMouseEnter={e => { e.currentTarget.style.background = `${song.color}35`; e.currentTarget.style.transform = 'scale(1.12)' }}
                  onMouseLeave={e => { e.currentTarget.style.background = `${song.color}18`; e.currentTarget.style.transform = 'scale(1)' }}
                  onClick={e => { e.stopPropagation(); isActive ? togglePlay() : playSong(song) }}
                  >{isActive && isPlaying ? '\u23F8' : '\u25B6'}</button>
                </GlassCard>
              )
            })}
          </div>
        </div>
      )}

      {/* Song list */}
      <div style={{ paddingBottom: 16 }}>
        <SectionHeader title={search ? 'Results' : 'Recently Played'} hideAction={!!search} />
        {!isMobile && (
          <div style={{
            display: 'grid',
            gridTemplateColumns: isTablet ? '28px 1fr auto auto' : '28px 1fr 1fr auto auto',
            gap: 12, padding: '0 12px 10px',
            borderBottom: '1px solid rgba(255,255,255,0.05)', marginBottom: 6,
          }}>
            {(isTablet ? ['#','Title','\u2661','\u23F1'] : ['#','Title','Album','\u2661','\u23F1']).map(h => (
              <span key={h} style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.10em', fontWeight: 600 }}>{h}</span>
            ))}
          </div>
        )}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {filtered.map((song, i) => (
            <SongRow
              key={song.id} song={song} index={i}
              active={currentSong.id === song.id}
              isPlaying={isPlaying && currentSong.id === song.id}
              isLiked={liked.has(song.id)}
              isMobile={isMobile} isTablet={isTablet}
              onClick={() => currentSong.id === song.id ? togglePlay() : playSong(song)}
              onLike={e => { e.stopPropagation(); toggleLike(song.id) }}
            />
          ))}
          {filtered.length === 0 && (
            <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}>No results for "{search}"</div>
          )}
        </div>
      </div>
    </div>
  )
}

function SectionHeader({ title, hideAction = false }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
      <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>{title}</h2>
      {!hideAction && (
        <button style={{ fontSize: 11, color: 'var(--accent-primary)', background: 'none', border: 'none', cursor: 'pointer', opacity: 0.75, transition: 'opacity 0.2s' }}
        onMouseEnter={e => e.currentTarget.style.opacity = 1}
        onMouseLeave={e => e.currentTarget.style.opacity = 0.75}
        >See all &#8594;</button>
      )}
    </div>
  )
}

function SongRow({ song, index, active, isPlaying, isLiked, isMobile, isTablet, onClick, onLike }) {
  return (
    <div onClick={onClick} style={{
      display: 'grid',
      gridTemplateColumns: isMobile ? 'auto 1fr auto' : isTablet ? '28px 1fr auto auto' : '28px 1fr 1fr auto auto',
      gap: 12, padding: isMobile ? '10px 8px' : '9px 12px',
      borderRadius: 12, cursor: 'pointer', alignItems: 'center',
      transition: 'background 0.2s, border-color 0.2s, box-shadow 0.2s',
      background: active ? 'rgba(34,211,238,0.06)' : 'transparent',
      border: `1px solid ${active ? 'rgba(34,211,238,0.18)' : 'transparent'}`,
      boxShadow: active ? '0 2px 12px rgba(34,211,238,0.07)' : 'none',
    }}
    onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' } }}
    onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' } }}
    >
      {isMobile
        ? <div style={{ width: 36, height: 36, borderRadius: 10, flexShrink: 0, background: `${song.color}14`, border: `1px solid ${song.color}30`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, color: song.color, boxShadow: active ? `0 0 12px ${song.color}30` : 'none' }}>{isPlaying ? '\u25B6' : '&#9834;'}</div>
        : <span style={{ fontSize: 11, textAlign: 'center', fontWeight: active ? 600 : 400, color: active ? 'var(--accent-primary)' : 'var(--text-muted)' }}>{isPlaying ? '\u25B6' : active ? '\u275A\u275A' : index + 1}</span>
      }
      <div style={{ minWidth: 0 }}>
        <p style={{ fontSize: 13, margin: 0, fontWeight: active ? 500 : 400, color: active ? 'var(--accent-primary)' : 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
        <p style={{ fontSize: 11, margin: 0, color: 'var(--text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.artist}</p>
      </div>
      {!isMobile && !isTablet && (
        <span style={{ fontSize: 12, color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.album}</span>
      )}
      {!isMobile && (
        <button onClick={onLike} style={{
          background: 'none', border: 'none', cursor: 'pointer', fontSize: 13,
          color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
          filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.5))' : 'none',
          transition: 'all 0.2s',
        }}
        onMouseEnter={e => { if (!isLiked) e.currentTarget.style.color = 'var(--text-primary)' }}
        onMouseLeave={e => { if (!isLiked) e.currentTarget.style.color = 'var(--text-muted)' }}
        >{isLiked ? '\u2665' : '\u2661'}</button>
      )}
      <span style={{ fontSize: 12, color: 'var(--text-muted)', textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(song.duration)}</span>
    </div>
  )
}
