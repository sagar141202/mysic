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

export default function MainContent() {
  return (
    <div style={{
      height: '100%', overflowY: 'auto',
      padding: '28px 24px',
      fontFamily: 'var(--font-body)',
    }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '28px' }}>
        <div>
          <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '4px' }}>Good Evening,</p>
          <h1 style={{
            fontFamily: 'var(--font-display)',
            fontSize: '28px', fontWeight: 700,
            background: 'var(--accent-grad)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
            lineHeight: 1.2,
          }}>What's the vibe?</h1>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          {['🔔', '🕐', '⚙'].map(icon => (
            <button key={icon} style={{
              width: 38, height: 38, borderRadius: '50%',
              background: 'var(--glass-bg)',
              border: '1px solid var(--glass-border)',
              color: 'var(--text-secondary)', fontSize: '15px',
              cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: 'all 0.2s',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--glass-bg-hover)'; e.currentTarget.style.borderColor = 'var(--glass-border-hover)'; }}
            onMouseLeave={e => { e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.borderColor = 'var(--glass-border)'; }}
            >{icon}</button>
          ))}
        </div>
      </div>

      {/* Search bar */}
      <div style={{
        position: 'relative', marginBottom: '32px',
      }}>
        <span style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: '16px' }}>⊙</span>
        <input
          placeholder="Search songs, artists, playlists..."
          style={{
            width: '100%', padding: '12px 16px 12px 42px',
            background: 'var(--glass-bg)',
            border: '1px solid var(--glass-border)',
            borderRadius: '14px',
            color: 'var(--text-primary)',
            fontSize: '14px',
            fontFamily: 'var(--font-body)',
            outline: 'none',
            backdropFilter: 'blur(20px)',
            transition: 'all 0.2s',
          }}
          onFocus={e => { e.target.style.borderColor = 'rgba(168,85,247,0.5)'; e.target.style.boxShadow = '0 0 0 3px rgba(168,85,247,0.1)'; }}
          onBlur={e => { e.target.style.borderColor = 'var(--glass-border)'; e.target.style.boxShadow = 'none'; }}
        />
      </div>

      {/* Featured Banner */}
      <div style={{ marginBottom: '32px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
          <h2 style={{ fontFamily: 'var(--font-display)', fontSize: '16px', fontWeight: 600, color: 'var(--text-primary)' }}>Featured</h2>
          <button style={{ fontSize: '13px', color: 'var(--accent-purple)', background: 'none', border: 'none', cursor: 'pointer' }}>See all</button>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px' }}>
          {featured.map((f, i) => (
            <div key={f.title} style={{
              borderRadius: '18px', padding: '24px 20px',
              background: `linear-gradient(135deg, ${f.color}22, ${f.color}08)`,
              border: `1px solid ${f.color}30`,
              cursor: 'pointer', position: 'relative', overflow: 'hidden',
              transition: 'all 0.3s ease',
            }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.boxShadow = `0 16px 40px ${f.color}25`; }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = 'none'; }}
            >
              <div style={{ fontSize: '32px', marginBottom: '12px' }}>{f.emoji}</div>
              <p style={{ fontFamily: 'var(--font-display)', fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>{f.title}</p>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{f.artist}</p>
              <div style={{
                position: 'absolute', top: '16px', right: '16px',
                width: 32, height: 32, borderRadius: '50%',
                background: `${f.color}30`,
                border: `1px solid ${f.color}50`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: '13px',
              }}>▶</div>
            </div>
          ))}
        </div>
      </div>

      {/* Song List */}
      <div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
          <h2 style={{ fontFamily: 'var(--font-display)', fontSize: '16px', fontWeight: 600, color: 'var(--text-primary)' }}>Recently Played</h2>
          <button style={{ fontSize: '13px', color: 'var(--accent-purple)', background: 'none', border: 'none', cursor: 'pointer' }}>See all</button>
        </div>

        {/* List header */}
        <div style={{ display: 'grid', gridTemplateColumns: '32px 1fr 1fr auto', gap: '12px', padding: '0 12px 10px', borderBottom: '1px solid var(--glass-border)' }}>
          {['#', 'Title', 'Album', '⏱'].map(h => (
            <span key={h} style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 500 }}>{h}</span>
          ))}
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', marginTop: '6px' }}>
          {songs.map((song, i) => (
            <div key={song.id} style={{
              display: 'grid', gridTemplateColumns: '32px 1fr 1fr auto',
              gap: '12px', padding: '10px 12px',
              borderRadius: '10px', cursor: 'pointer',
              transition: 'all 0.2s ease',
              border: '1px solid transparent',
              alignItems: 'center',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.borderColor = 'var(--glass-border)'; }}
            onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent'; }}
            >
              <span style={{ fontSize: '12px', color: 'var(--text-muted)', textAlign: 'center' }}>{song.emoji}</span>
              <div>
                <p style={{ fontSize: '14px', fontWeight: 400, color: 'var(--text-primary)', margin: 0 }}>{song.title}</p>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: 0 }}>{song.artist}</p>
              </div>
              <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{song.album}</span>
              <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{song.duration}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
