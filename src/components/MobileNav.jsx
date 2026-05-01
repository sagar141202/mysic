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
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-around', padding: '10px 8px 14px', background: 'rgba(10,10,15,0.95)', backdropFilter: 'blur(20px)', borderTop: '1px solid var(--glass-border)', fontFamily: 'var(--font-body)' }}>
      {tabs.map(t => (
        <button key={t.label} onClick={() => setActive(t.label)} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px', background: 'none', border: 'none', cursor: 'pointer', padding: '4px 12px', borderRadius: '10px', transition: 'all 0.2s', color: active === t.label ? 'var(--accent-purple)' : 'var(--text-muted)', minWidth: '56px' }}>
          <span style={{ fontSize: '20px' }}>{t.icon}</span>
          <span style={{ fontSize: '10px', fontWeight: active === t.label ? 500 : 400, letterSpacing: '0.03em' }}>{t.label}</span>
          {active === t.label && <div style={{ width: 4, height: 4, borderRadius: '50%', background: 'var(--accent-purple)', boxShadow: '0 0 6px var(--accent-purple)', marginTop: '-2px' }} />}
        </button>
      ))}
    </div>
  )
}
