import { useState } from 'react'

const tabs = [
  { icon: '⌂', label: 'Home' },
  { icon: '⊙', label: 'Search' },
  { icon: '♪', label: 'Library' },
  { icon: '♡', label: 'Liked' },
]

export default function MobileNav() {
  const [active, setActive] = useState('Home')
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-around', padding: '8px 8px 14px', background: 'rgba(8,12,20,0.96)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.06)', fontFamily: 'var(--font-body)' }}>
      {tabs.map(t => (
        <button key={t.label} onClick={() => setActive(t.label)} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, background: 'none', border: 'none', cursor: 'pointer', padding: '4px 16px', borderRadius: 10, color: active === t.label ? 'var(--accent-primary)' : 'var(--text-muted)', minWidth: 56, transition: 'all 0.2s' }}>
          <span style={{ fontSize: 19 }}>{t.icon}</span>
          <span style={{ fontSize: 9, fontWeight: active === t.label ? 600 : 400, letterSpacing: '0.06em', textTransform: 'uppercase' }}>{t.label}</span>
          {active === t.label && <div style={{ width: 4, height: 4, borderRadius: '50%', background: 'var(--accent-primary)', boxShadow: '0 0 6px var(--accent-primary)', marginTop: -2 }} />}
        </button>
      ))}
    </div>
  )
}
