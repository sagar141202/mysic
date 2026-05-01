import { useState } from 'react'

const navItems = [
  { icon: '⌂', label: 'Home', active: true },
  { icon: '⊙', label: 'Discover', active: false },
  { icon: '♪', label: 'Library', active: false },
  { icon: '♡', label: 'Liked Songs', active: false },
  { icon: '⊞', label: 'Playlists', active: false },
]

const playlists = [
  { name: 'Late Night Vibes', count: '24 songs' },
  { name: 'Workout Mix', count: '18 songs' },
  { name: 'Chill Afternoon', count: '31 songs' },
  { name: 'Bollywood Hits', count: '47 songs' },
  { name: 'Focus Mode', count: '12 songs' },
]

export default function Sidebar() {
  const [active, setActive] = useState('Home')

  return (
    <div style={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      padding: '24px 16px',
      background: 'rgba(255,255,255,0.02)',
      backdropFilter: 'blur(20px)',
      borderRight: '1px solid var(--glass-border)',
      fontFamily: 'var(--font-body)',
      overflowY: 'auto',
    }}>

      {/* Logo */}
      <div style={{ padding: '0 8px 32px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <div style={{
          width: 36, height: 36, borderRadius: '10px',
          background: 'var(--accent-grad)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '18px', flexShrink: 0,
        }}>🎵</div>
        <span style={{
          fontFamily: 'var(--font-display)',
          fontSize: '22px', fontWeight: 700,
          background: 'var(--accent-grad)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text',
          letterSpacing: '-0.5px',
        }}>mysic</span>
      </div>

      {/* Nav */}
      <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
        {navItems.map(item => (
          <button
            key={item.label}
            onClick={() => setActive(item.label)}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px',
              padding: '10px 12px', borderRadius: '12px',
              border: active === item.label ? '1px solid rgba(168,85,247,0.3)' : '1px solid transparent',
              background: active === item.label
                ? 'linear-gradient(135deg, rgba(168,85,247,0.15), rgba(236,72,153,0.08))'
                : 'transparent',
              color: active === item.label ? 'var(--text-primary)' : 'var(--text-secondary)',
              cursor: 'pointer',
              fontSize: '14px',
              fontFamily: 'var(--font-body)',
              fontWeight: active === item.label ? 500 : 400,
              transition: 'all 0.2s ease',
              textAlign: 'left',
              width: '100%',
            }}
            onMouseEnter={e => {
              if (active !== item.label) e.currentTarget.style.background = 'rgba(255,255,255,0.04)'
            }}
            onMouseLeave={e => {
              if (active !== item.label) e.currentTarget.style.background = 'transparent'
            }}
          >
            <span style={{ fontSize: '16px', width: '20px', textAlign: 'center' }}>{item.icon}</span>
            <span>{item.label}</span>
            {active === item.label && (
              <div style={{
                marginLeft: 'auto', width: 6, height: 6, borderRadius: '50%',
                background: 'var(--accent-purple)',
                boxShadow: '0 0 8px var(--accent-purple)',
              }} />
            )}
          </button>
        ))}
      </nav>

      {/* Divider */}
      <div style={{ margin: '24px 0 16px', borderTop: '1px solid var(--glass-border)' }} />

      {/* Playlists */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        <p style={{ fontSize: '11px', fontWeight: 600, letterSpacing: '0.1em', color: 'var(--text-muted)', padding: '0 12px 12px', textTransform: 'uppercase' }}>
          Your Playlists
        </p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
          {playlists.map(p => (
            <button key={p.name} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'flex-start',
              padding: '8px 12px', borderRadius: '10px', border: 'none',
              background: 'transparent', color: 'var(--text-secondary)',
              cursor: 'pointer', width: '100%', transition: 'all 0.2s ease',
              fontFamily: 'var(--font-body)',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.color = 'var(--text-primary)'; }}
            onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = 'var(--text-secondary)'; }}
            >
              <span style={{ fontSize: '13px', fontWeight: 400 }}>{p.name}</span>
              <span style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '1px' }}>{p.count}</span>
            </button>
          ))}
        </div>
      </div>

      {/* User */}
      <div style={{
        marginTop: '16px',
        padding: '12px',
        borderRadius: '14px',
        background: 'var(--glass-bg)',
        border: '1px solid var(--glass-border)',
        display: 'flex', alignItems: 'center', gap: '10px',
      }}>
        <div style={{
          width: 34, height: 34, borderRadius: '50%',
          background: 'var(--accent-grad)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '14px', fontWeight: 600, color: '#fff',
          flexShrink: 0,
        }}>S</div>
        <div style={{ minWidth: 0 }}>
          <p style={{ fontSize: '13px', fontWeight: 500, color: 'var(--text-primary)', margin: 0 }}>Sagar</p>
          <p style={{ fontSize: '11px', color: 'var(--text-muted)', margin: 0 }}>Premium</p>
        </div>
        <div style={{ marginLeft: 'auto', fontSize: '16px', color: 'var(--text-muted)', cursor: 'pointer' }}>⚙</div>
      </div>
    </div>
  )
}
