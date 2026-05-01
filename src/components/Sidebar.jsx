import { useState } from 'react'

const navItems = [
  { icon: '⌂', label: 'Home' },
  { icon: '⊙', label: 'Discover' },
  { icon: '♪', label: 'Library' },
  { icon: '♡', label: 'Liked Songs' },
  { icon: '⊞', label: 'Playlists' },
]

const playlists = [
  { name: 'Late Night Vibes', count: '24 songs' },
  { name: 'Workout Mix', count: '18 songs' },
  { name: 'Chill Afternoon', count: '31 songs' },
  { name: 'Bollywood Hits', count: '47 songs' },
  { name: 'Focus Mode', count: '12 songs' },
]

export default function Sidebar({ collapsed = false, onClose }) {
  const [active, setActive] = useState('Home')

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      padding: collapsed ? '24px 10px' : '24px 16px',
      background: 'rgba(255,255,255,0.02)',
      backdropFilter: 'blur(20px)',
      borderRight: '1px solid var(--glass-border)',
      fontFamily: 'var(--font-body)',
      overflowY: 'auto',
      overflowX: 'hidden',
    }}>

      {/* Logo row */}
      <div style={{ padding: collapsed ? '0 0 28px' : '0 8px 28px', display: 'flex', alignItems: 'center', gap: '10px', justifyContent: collapsed ? 'center' : 'flex-start' }}>
        <div style={{ width: 34, height: 34, borderRadius: '10px', background: 'var(--accent-grad)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '16px', flexShrink: 0 }}>🎵</div>
        {!collapsed && (
          <span style={{ fontFamily: 'var(--font-display)', fontSize: '20px', fontWeight: 700, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text', letterSpacing: '-0.5px' }}>mysic</span>
        )}
        {onClose && !collapsed && (
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '20px', cursor: 'pointer', lineHeight: 1 }}>✕</button>
        )}
      </div>

      {/* Nav items */}
      <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
        {navItems.map(item => (
          <button key={item.label} onClick={() => setActive(item.label)} title={collapsed ? item.label : ''} style={{
            display: 'flex', alignItems: 'center', gap: collapsed ? 0 : '12px',
            justifyContent: collapsed ? 'center' : 'flex-start',
            padding: collapsed ? '10px' : '10px 12px',
            borderRadius: '12px',
            border: active === item.label ? '1px solid rgba(168,85,247,0.3)' : '1px solid transparent',
            background: active === item.label ? 'linear-gradient(135deg, rgba(168,85,247,0.15), rgba(236,72,153,0.08))' : 'transparent',
            color: active === item.label ? 'var(--text-primary)' : 'var(--text-secondary)',
            cursor: 'pointer', fontSize: '14px', fontFamily: 'var(--font-body)',
            fontWeight: active === item.label ? 500 : 400, transition: 'all 0.2s ease',
            textAlign: 'left', width: '100%',
          }}
          onMouseEnter={e => { if (active !== item.label) e.currentTarget.style.background = 'rgba(255,255,255,0.04)' }}
          onMouseLeave={e => { if (active !== item.label) e.currentTarget.style.background = 'transparent' }}
          >
            <span style={{ fontSize: '18px', width: collapsed ? 'auto' : '20px', textAlign: 'center', flexShrink: 0 }}>{item.icon}</span>
            {!collapsed && <span style={{ whiteSpace: 'nowrap' }}>{item.label}</span>}
            {!collapsed && active === item.label && <div style={{ marginLeft: 'auto', width: 6, height: 6, borderRadius: '50%', background: 'var(--accent-purple)', boxShadow: '0 0 8px var(--accent-purple)' }} />}
          </button>
        ))}
      </nav>

      {!collapsed && (
        <>
          <div style={{ margin: '20px 0 14px', borderTop: '1px solid var(--glass-border)' }} />
          <div style={{ flex: 1, overflow: 'auto' }}>
            <p style={{ fontSize: '11px', fontWeight: 600, letterSpacing: '0.1em', color: 'var(--text-muted)', padding: '0 12px 10px', textTransform: 'uppercase' }}>Your Playlists</p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
              {playlists.map(p => (
                <button key={p.name} style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', padding: '7px 12px', borderRadius: '10px', border: 'none', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer', width: '100%', transition: 'all 0.2s', fontFamily: 'var(--font-body)' }}
                onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.color = 'var(--text-primary)' }}
                onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = 'var(--text-secondary)' }}
                >
                  <span style={{ fontSize: '13px' }}>{p.name}</span>
                  <span style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '1px' }}>{p.count}</span>
                </button>
              ))}
            </div>
          </div>
        </>
      )}

      {/* User */}
      <div style={{ marginTop: '16px', padding: collapsed ? '10px' : '10px 12px', borderRadius: '14px', background: 'var(--glass-bg)', border: '1px solid var(--glass-border)', display: 'flex', alignItems: 'center', gap: collapsed ? 0 : '10px', justifyContent: collapsed ? 'center' : 'flex-start' }}>
        <div style={{ width: 32, height: 32, borderRadius: '50%', background: 'var(--accent-grad)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 600, color: '#fff', flexShrink: 0 }}>S</div>
        {!collapsed && (
          <>
            <div style={{ minWidth: 0 }}>
              <p style={{ fontSize: '13px', fontWeight: 500, color: 'var(--text-primary)', margin: 0 }}>Sagar</p>
              <p style={{ fontSize: '11px', color: 'var(--text-muted)', margin: 0 }}>Premium</p>
            </div>
            <div style={{ marginLeft: 'auto', fontSize: '16px', color: 'var(--text-muted)', cursor: 'pointer' }}>⚙</div>
          </>
        )}
      </div>
    </div>
  )
}
