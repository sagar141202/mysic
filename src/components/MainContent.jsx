const featured = [
  { title: 'Blinding Lights', artist: 'The Weeknd', color: '#a855f7', emoji: '🌙' },
  { title: 'Param Sundari', artist: 'A.R. Rahman', color: '#ec4899', emoji: '✨' },
  { title: 'Psychedelic', artist: 'D3m0n X Diablo', color: '#3b82f6', emoji: '🔮' },
]

const songs = [
  { id: 1, title: 'Rait Zara Si', artist: 'A.R. Rahman', album: 'Atrangi Re', duration: '4:02', emoji: '🌊' },
  { id: 2, title: 'Dholida', artist: 'Jonita Gandhi', album: 'Gangubai', duration: '3:45', emoji: '🎶' },
  { id: 3, title: 'Blinding Lights', artist: 'The Weeknd', album: 'After Hours', duration: '3:20', emoji: '💜' },
  { id: 4, title: 'Doobey', artist: 'Rekha Bhardwaj', album: 'Gehraiyaan', duration: '4:30', emoji: '��' },
  { id: 5, title: 'Hum Nashe Mein', artist: 'Arijit Singh', album: 'Bhoot Police', duration: '3:58', emoji: '🔥' },
  { id: 6, title: 'Shape of You', artist: 'Ed Sheeran', album: 'Divide', duration: '3:53', emoji: '💛' },
  { id: 7, title: 'Secrets', artist: 'Tiësto & KSHMR', album: 'Singles', duration: '3:12', emoji: '🎵' },
  { id: 8, title: 'Mi Cama', artist: 'Karol G', album: 'Ocean', duration: '3:07', emoji: '🌺' },
]

export default function MainContent({ screenSize = 'desktop' }) {
  const isMobile = screenSize === 'mobile'
  const isTablet = screenSize === 'tablet'

  return (
    <div style={{
      height: '100%', overflowY: 'auto',
      padding: isMobile ? '20px 16px 8px' : isTablet ? '24px 20px' : '28px 24px',
      fontFamily: 'var(--font-body)',
    }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: isMobile ? 'flex-start' : 'center', justifyContent: 'space-between', marginBottom: isMobile ? '20px' : '28px', gap: '12px' }}>
        <div>
          <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '3px' }}>Good Evening,</p>
          <h1 style={{ fontFamily: 'var(--font-display)', fontSize: isMobile ? '22px' : '28px', fontWeight: 700, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text', lineHeight: 1.2, margin: 0 }}>
            What's the vibe?
          </h1>
        </div>
        <div style={{ display: 'flex', gap: '8px', flexShrink: 0 }}>
          {(isMobile ? ['🔔'] : ['🔔', '🕐', '⚙']).map(icon => (
            <button key={icon} style={{ width: isMobile ? 34 : 38, height: isMobile ? 34 : 38, borderRadius: '50%', background: 'var(--glass-bg)', border: '1px solid var(--glass-border)', color: 'var(--text-secondary)', fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--glass-bg-hover)'; e.currentTarget.style.borderColor = 'var(--glass-border-hover)' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.borderColor = 'var(--glass-border)' }}
            >{icon}</button>
          ))}
        </div>
      </div>

      {/* Search bar */}
      <div style={{ position: 'relative', marginBottom: isMobile ? '24px' : '32px' }}>
        <span style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: '15px' }}>⊙</span>
        <input placeholder="Search songs, artists, playlists..." style={{ width: '100%', padding: isMobile ? '11px 14px 11px 40px' : '12px 16px 12px 42px', background: 'var(--glass-bg)', border: '1px solid var(--glass-border)', borderRadius: '14px', color: 'var(--text-primary)', fontSize: '14px', fontFamily: 'var(--font-body)', outline: 'none', backdropFilter: 'blur(20px)', transition: 'all 0.2s' }}
        onFocus={e => { e.target.style.borderColor = 'rgba(168,85,247,0.5)'; e.target.style.boxShadow = '0 0 0 3px rgba(168,85,247,0.1)' }}
        onBlur={e => { e.target.style.borderColor = 'var(--glass-border)'; e.target.style.boxShadow = 'none' }}
        />
      </div>

      {/* Featured */}
      <div style={{ marginBottom: isMobile ? '28px' : '32px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
          <h2 style={{ fontFamily: 'var(--font-display)', fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', margin: 0 }}>Featured</h2>
          <button style={{ fontSize: '13px', color: 'var(--accent-purple)', background: 'none', border: 'none', cursor: 'pointer' }}>See all</button>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: isMobile ? 'repeat(1, 1fr)' : 'repeat(3, 1fr)', gap: '12px' }}>
          {(isMobile ? featured.slice(0, 1) : featured).map(f => (
            <div key={f.title} style={{ borderRadius: '18px', padding: isMobile ? '20px 18px' : '22px 20px', background: `linear-gradient(135deg, ${f.color}22, ${f.color}08)`, border: `1px solid ${f.color}30`, cursor: 'pointer', position: 'relative', overflow: 'hidden', transition: 'all 0.3s ease', display: isMobile ? 'flex' : 'block', alignItems: isMobile ? 'center' : 'unset', gap: isMobile ? '14px' : '0' }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.boxShadow = `0 16px 40px ${f.color}25` }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = 'none' }}
            >
              <div style={{ fontSize: isMobile ? '36px' : '32px', marginBottom: isMobile ? 0 : '12px', flexShrink: 0 }}>{f.emoji}</div>
              <div>
                <p style={{ fontFamily: 'var(--font-display)', fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '3px', margin: 0 }}>{f.title}</p>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: '3px 0 0' }}>{f.artist}</p>
              </div>
              <div style={{ position: 'absolute', top: '16px', right: '16px', width: 30, height: 30, borderRadius: '50%', background: `${f.color}30`, border: `1px solid ${f.color}50`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px' }}>▶</div>
            </div>
          ))}
        </div>
      </div>

      {/* Song list */}
      <div style={{ paddingBottom: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
          <h2 style={{ fontFamily: 'var(--font-display)', fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', margin: 0 }}>Recently Played</h2>
          <button style={{ fontSize: '13px', color: 'var(--accent-purple)', background: 'none', border: 'none', cursor: 'pointer' }}>See all</button>
        </div>

        {!isMobile && (
          <div style={{ display: 'grid', gridTemplateColumns: isTablet ? '28px 1fr auto' : '28px 1fr 1fr auto', gap: '12px', padding: '0 12px 10px', borderBottom: '1px solid var(--glass-border)' }}>
            {(isTablet ? ['#', 'Title', '⏱'] : ['#', 'Title', 'Album', '⏱']).map(h => (
              <span key={h} style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 500 }}>{h}</span>
            ))}
          </div>
        )}

        <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', marginTop: '6px' }}>
          {songs.map((song) => (
            <div key={song.id} style={{ display: 'grid', gridTemplateColumns: isMobile ? 'auto 1fr auto' : isTablet ? '28px 1fr auto' : '28px 1fr 1fr auto', gap: isMobile ? '12px' : '12px', padding: isMobile ? '10px 8px' : '10px 12px', borderRadius: '10px', cursor: 'pointer', transition: 'all 0.2s ease', border: '1px solid transparent', alignItems: 'center' }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.borderColor = 'var(--glass-border)' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}
            >
              <span style={{ fontSize: isMobile ? '22px' : '14px', textAlign: 'center', width: isMobile ? 'auto' : '28px' }}>{song.emoji}</span>
              <div style={{ minWidth: 0 }}>
                <p style={{ fontSize: '14px', fontWeight: 400, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.artist}</p>
              </div>
              {!isMobile && !isTablet && <span style={{ fontSize: '13px', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.album}</span>}
              <span style={{ fontSize: '13px', color: 'var(--text-muted)', textAlign: 'right' }}>{song.duration}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
