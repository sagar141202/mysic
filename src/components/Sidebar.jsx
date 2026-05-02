import { useState } from 'react'
import GlassCard from './GlassCard'

const nav = [
  { icon: '⌂', label: 'Home' },
  { icon: '⊙', label: 'Discover' },
  { icon: '♪', label: 'Library' },
  { icon: '♡', label: 'Liked' },
  { icon: '⊞', label: 'Playlists' },
]

const playlists = [
  { name: 'Late Night Drive', count: '24 songs' },
  { name: 'Workout Beast',    count: '18 songs' },
  { name: 'Chill Sunday',     count: '31 songs' },
  { name: 'Bollywood Fire',   count: '47 songs' },
  { name: 'Deep Focus',       count: '12 songs' },
]

export default function Sidebar({ collapsed = false, onClose }) {
  const [active, setActive] = useState('Home')

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      padding: collapsed ? '20px 10px' : '22px 14px',
      background: 'rgba(8,12,20,0.65)',
      backdropFilter: 'blur(28px)', WebkitBackdropFilter: 'blur(28px)',
      borderRight: '1px solid rgba(255,255,255,0.06)',
      fontFamily: 'var(--font-body)', overflowY: 'auto', overflowX: 'hidden',
    }}>

      {/* ── Logo ── */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        justifyContent: collapsed ? 'center' : 'flex-start',
        padding: collapsed ? '0 0 24px' : '0 6px 24px',
      }}>
        <div style={{
          width: 34, height: 34, borderRadius: 10, flexShrink: 0,
          background: 'var(--accent-grad)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 16, boxShadow: '0 4px 16px rgba(34,211,238,0.28)',
        }}>♫</div>
        {!collapsed && (
          <span style={{
            fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 800,
            background: 'var(--accent-grad)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
            letterSpacing: '-0.5px',
          }}>mysic</span>
        )}
        {onClose && !collapsed && (
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 18, cursor: 'pointer', transition: 'color 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
          >✕</button>
        )}
      </div>

      {/* ── Nav ── */}
      <nav style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {nav.map(item => (
          <button key={item.label} onClick={() => setActive(item.label)} title={collapsed ? item.label : ''} style={{
            display: 'flex', alignItems: 'center',
            gap: collapsed ? 0 : 10,
            justifyContent: collapsed ? 'center' : 'flex-start',
            padding: collapsed ? '10px 8px' : '10px 12px',
            borderRadius: 12, width: '100%',
            border: active === item.label ? '1px solid rgba(34,211,238,0.28)' : '1px solid transparent',
            background: active === item.label
              ? 'rgba(34,211,238,0.07)'
              : 'transparent',
            color: active === item.label ? 'var(--accent-primary)' : 'var(--text-secondary)',
            cursor: 'pointer', fontSize: 13, fontFamily: 'var(--font-body)',
            fontWeight: active === item.label ? 500 : 400,
            transition: 'all 0.2s ease',
            boxShadow: active === item.label ? '0 2px 12px rgba(34,211,238,0.07)' : 'none',
          }}
          onMouseEnter={e => {
            if (active !== item.label) {
              e.currentTarget.style.background  = 'rgba(255,255,255,0.04)'
              e.currentTarget.style.color       = 'var(--text-primary)'
              e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)'
            }
          }}
          onMouseLeave={e => {
            if (active !== item.label) {
              e.currentTarget.style.background  = 'transparent'
              e.currentTarget.style.color       = 'var(--text-secondary)'
              e.currentTarget.style.borderColor = 'transparent'
            }
          }}
          >
            <span style={{ fontSize: 17, width: collapsed ? 'auto' : 20, textAlign: 'center', flexShrink: 0 }}>{item.icon}</span>
            {!collapsed && <span style={{ whiteSpace: 'nowrap' }}>{item.label}</span>}
            {!collapsed && active === item.label && (
              <div style={{ marginLeft: 'auto', width: 5, height: 5, borderRadius: '50%', background: 'var(--accent-primary)', boxShadow: '0 0 8px var(--accent-primary)', animation: 'pulse-glow 2s infinite' }} />
            )}
          </button>
        ))}
      </nav>

      {/* ── Playlists ── */}
      {!collapsed && (
        <>
          <div style={{ margin: '20px 0 14px', borderTop: '1px solid rgba(255,255,255,0.06)' }} />
          <p style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.12em', color: 'var(--text-muted)', padding: '0 12px 10px', textTransform: 'uppercase' }}>
            Playlists
          </p>
          <div style={{ flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 1 }}>
            {playlists.map(p => (
              <button key={p.name} style={{
                display: 'flex', alignItems: 'center', gap: 10,
                padding: '8px 12px', borderRadius: 10,
                border: '1px solid transparent', background: 'transparent',
                color: 'var(--text-secondary)', cursor: 'pointer', width: '100%',
                fontFamily: 'var(--font-body)', textAlign: 'left',
                transition: 'all 0.2s ease',
              }}
              onMouseEnter={e => {
                e.currentTarget.style.background  = 'rgba(255,255,255,0.04)'
                e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)'
                e.currentTarget.style.color       = 'var(--text-primary)'
              }}
              onMouseLeave={e => {
                e.currentTarget.style.background  = 'transparent'
                e.currentTarget.style.borderColor = 'transparent'
                e.currentTarget.style.color       = 'var(--text-secondary)'
              }}
              >
                <div style={{
                  width: 28, height: 28, borderRadius: 8, flexShrink: 0,
                  background: 'rgba(34,211,238,0.07)', border: '1px solid rgba(34,211,238,0.12)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12,
                }}>♪</div>
                <div style={{ minWidth: 0 }}>
                  <p style={{ fontSize: 13, margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{p.name}</p>
                  <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: 0 }}>{p.count}</p>
                </div>
              </button>
            ))}
          </div>
        </>
      )}

      {/* ── User card ── */}
      <GlassCard padding="10px 12px" radius={14} hoverable={false} style={{
        marginTop: 16, display: 'flex', alignItems: 'center',
        gap: collapsed ? 0 : 10, justifyContent: collapsed ? 'center' : 'flex-start',
        boxShadow: '0 2px 12px rgba(0,0,0,0.20), inset 0 1px 0 rgba(255,255,255,0.05)',
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: '50%', flexShrink: 0,
          background: 'var(--accent-grad)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 12, fontWeight: 700, color: '#08121f',
        }}>S</div>
        {!collapsed && (
          <>
            <div style={{ minWidth: 0 }}>
              <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0 }}>Sagar</p>
              <p style={{ fontSize: 10, color: 'var(--accent-primary)', margin: 0 }}>Premium ✦</p>
            </div>
            <button style={{ marginLeft: 'auto', background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 15, cursor: 'pointer', transition: 'color 0.2s' }}
            onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
            onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
            >⚙</button>
          </>
        )}
      </GlassCard>
    </div>
  )
}