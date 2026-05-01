import { useState } from 'react'
import GlassCard from './GlassCard'

const featured = [
  { title: 'Blinding Lights', artist: 'The Weeknd', color: '#22d3ee', bg: 'rgba(34,211,238,0.08)', icon: '◈' },
  { title: 'Param Sundari', artist: 'A.R. Rahman', color: '#f59e0b', bg: 'rgba(245,158,11,0.08)', icon: '◉' },
  { title: 'Psychedelic', artist: 'D3m0n X Diablo', color: '#818cf8', bg: 'rgba(129,140,248,0.08)', icon: '◍' },
]

const songs = [
  { id: 1, title: 'Rait Zara Si', artist: 'A.R. Rahman', album: 'Atrangi Re', duration: '4:02', color: '#22d3ee' },
  { id: 2, title: 'Dholida', artist: 'Jonita Gandhi', album: 'Gangubai', duration: '3:45', color: '#f59e0b' },
  { id: 3, title: 'Blinding Lights', artist: 'The Weeknd', album: 'After Hours', duration: '3:20', color: '#818cf8' },
  { id: 4, title: 'Doobey', artist: 'Rekha Bhardwaj', album: 'Gehraiyaan', duration: '4:30', color: '#22d3ee' },
  { id: 5, title: 'Hum Nashe Mein', artist: 'Arijit Singh', album: 'Bhoot Police', duration: '3:58', color: '#f59e0b' },
  { id: 6, title: 'Shape of You', artist: 'Ed Sheeran', album: 'Divide', duration: '3:53', color: '#0ea5e9' },
  { id: 7, title: 'Secrets', artist: 'Tiësto & KSHMR', album: 'Singles', duration: '3:12', color: '#818cf8' },
  { id: 8, title: 'Mi Cama', artist: 'Karol G', album: 'Ocean', duration: '3:07', color: '#22d3ee' },
]

export default function MainContent({ screenSize = 'desktop' }) {
  const [activeSong, setActiveSong] = useState(3)
  const isMobile = screenSize === 'mobile'
  const isTablet = screenSize === 'tablet'

  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: isMobile ? '18px 14px 8px' : '24px 22px', fontFamily: 'var(--font-body)' }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 3 }}>Good Evening</p>
          <h1 style={{ fontFamily: 'var(--font-display)', fontSize: isMobile ? 20 : 26, fontWeight: 800, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text', lineHeight: 1.15, margin: 0 }}>
            What's the vibe?
          </h1>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {(isMobile ? ['🔔'] : ['🔔', '⊙', '⚙']).map(icon => (
            <button key={icon} style={{ width: isMobile ? 34 : 36, height: isMobile ? 34 : 36, borderRadius: '50%', background: 'var(--glass-bg)', border: '1px solid var(--glass-border)', color: 'var(--text-secondary)', fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}
            onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(34,211,238,0.3)'; e.currentTarget.style.color = 'var(--text-primary)' }}
            onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--glass-border)'; e.currentTarget.style.color = 'var(--text-secondary)' }}
            >{icon}</button>
          ))}
        </div>
      </div>

      {/* Search */}
      <div style={{ position: 'relative', marginBottom: 28 }}>
        <span style={{ position: 'absolute', left: 13, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14 }}>⊙</span>
        <input placeholder="Search songs, artists, playlists..." style={{ width: '100%', padding: '11px 14px 11px 38px', background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 13, color: 'var(--text-primary)', fontSize: 13, fontFamily: 'var(--font-body)', outline: 'none', transition: 'all 0.2s' }}
        onFocus={e => { e.target.style.borderColor = 'rgba(34,211,238,0.4)'; e.target.style.background = 'rgba(34,211,238,0.04)'; e.target.style.boxShadow = '0 0 0 3px rgba(34,211,238,0.07)' }}
        onBlur={e => { e.target.style.borderColor = 'rgba(255,255,255,0.07)'; e.target.style.background = 'rgba(255,255,255,0.03)'; e.target.style.boxShadow = 'none' }}
        />
      </div>

      {/* Featured */}
      <div style={{ marginBottom: 28 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', margin: 0, letterSpacing: '-0.2px' }}>Featured</h2>
          <button style={{ fontSize: 12, color: 'var(--accent-primary)', background: 'none', border: 'none', cursor: 'pointer', opacity: 0.8 }}>See all →</button>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(3,1fr)', gap: 10 }}>
          {(isMobile ? featured.slice(0,1) : featured).map(f => (
            <GlassCard key={f.title} padding="18px 16px" radius={16} onClick={() => {}} style={{ position: 'relative', overflow: 'hidden' }}>
              {/* color glow top-right */}
              <div style={{ position: 'absolute', top: -20, right: -20, width: 80, height: 80, borderRadius: '50%', background: `radial-gradient(circle, ${f.color}30, transparent 70%)`, filter: 'blur(10px)', pointerEvents: 'none' }} />
              <div style={{ fontSize: 28, marginBottom: 10, filter: `drop-shadow(0 0 8px ${f.color}60)` }}>{f.icon}</div>
              <p style={{ fontFamily: 'var(--font-display)', fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', margin: '0 0 3px' }}>{f.title}</p>
              <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{f.artist}</p>
              <div style={{ position: 'absolute', top: 14, right: 14, width: 28, height: 28, borderRadius: '50%', background: `${f.color}18`, border: `1px solid ${f.color}40`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, color: f.color, cursor: 'pointer', transition: 'all 0.2s' }}
              onMouseEnter={e => { e.currentTarget.style.background = `${f.color}35`; e.currentTarget.style.boxShadow = `0 0 12px ${f.color}50` }}
              onMouseLeave={e => { e.currentTarget.style.background = `${f.color}18`; e.currentTarget.style.boxShadow = 'none' }}
              >▶</div>
            </GlassCard>
          ))}
        </div>
      </div>

      {/* Song list */}
      <div style={{ paddingBottom: 12 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Recently Played</h2>
          <button style={{ fontSize: 12, color: 'var(--accent-primary)', background: 'none', border: 'none', cursor: 'pointer', opacity: 0.8 }}>See all →</button>
        </div>

        {!isMobile && (
          <div style={{ display: 'grid', gridTemplateColumns: isTablet ? '24px 1fr auto' : '24px 1fr 1fr auto', gap: 12, padding: '0 12px 8px', marginBottom: 4 }}>
            {(isTablet ? ['#','Title','⏱'] : ['#','Title','Album','⏱']).map(h => (
              <span key={h} style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.1em', fontWeight: 600 }}>{h}</span>
            ))}
          </div>
        )}

        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {songs.map((song, i) => (
            <div key={song.id} onClick={() => setActiveSong(song.id)} style={{
              display: 'grid',
              gridTemplateColumns: isMobile ? 'auto 1fr auto' : isTablet ? '24px 1fr auto' : '24px 1fr 1fr auto',
              gap: 12, padding: isMobile ? '10px 8px' : '9px 12px',
              borderRadius: 12, cursor: 'pointer', transition: 'all 0.2s',
              background: activeSong === song.id ? 'rgba(34,211,238,0.06)' : 'transparent',
              border: `1px solid ${activeSong === song.id ? 'rgba(34,211,238,0.2)' : 'transparent'}`,
              alignItems: 'center',
            }}
            onMouseEnter={e => { if (activeSong !== song.id) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' } }}
            onMouseLeave={e => { if (activeSong !== song.id) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' } }}
            >
              {isMobile
                ? <div style={{ width: 34, height: 34, borderRadius: 10, background: `${song.color}15`, border: `1px solid ${song.color}30`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, color: song.color, flexShrink: 0 }}>♪</div>
                : <span style={{ fontSize: 11, color: activeSong === song.id ? 'var(--accent-primary)' : 'var(--text-muted)', textAlign: 'center', fontWeight: activeSong === song.id ? 600 : 400 }}>{activeSong === song.id ? '▶' : i + 1}</span>
              }
              <div style={{ minWidth: 0 }}>
                <p style={{ fontSize: 13, fontWeight: activeSong === song.id ? 500 : 400, color: activeSong === song.id ? 'var(--accent-primary)' : 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
                <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.artist}</p>
              </div>
              {!isMobile && !isTablet && <span style={{ fontSize: 12, color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.album}</span>}
              <span style={{ fontSize: 12, color: 'var(--text-muted)', textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{song.duration}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
