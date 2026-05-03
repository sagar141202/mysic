const tabs = [
  { icon: '⌂', label: 'Home' },
  { icon: '⊙', label: 'Discover' },
  { icon: '♪', label: 'Library' },
  { icon: '♡', label: 'Liked' },
  { icon: '⊞', label: 'Playlists' },
]

export default function MobileNav({ activePage = 'Home', onNavigate }) {
  return (
    <div style={{ display: 'flex', background: 'rgba(8,12,20,0.96)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.06)', padding: '8px 0 12px' }}>
      {tabs.map(tab => {
        const active = activePage === tab.label
        return (
          <button key={tab.label} onClick={() => onNavigate?.(tab.label)} style={{
            flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            background: 'none', border: 'none', cursor: 'pointer', padding: '6px 0',
            color: active ? 'var(--accent-primary)' : 'var(--text-muted)',
            transition: 'color 0.2s', fontFamily: 'var(--font-body)',
          }}>
            <span style={{ fontSize: 18, filter: active ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none', transition: 'filter 0.2s' }}>{tab.icon}</span>
            <span style={{ fontSize: 9, letterSpacing: '0.04em' }}>{tab.label}</span>
          </button>
        )
      })}
    </div>
  )
}
