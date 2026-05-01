export default function Player({ mobile = false, onNowPlayingClick }) {
  if (mobile) return (
    <div onClick={onNowPlayingClick} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px', background: 'rgba(8,12,20,0.95)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.06)', cursor: 'pointer', fontFamily: 'var(--font-body)' }}>
      <div style={{ width: 40, height: 40, borderRadius: 10, background: 'linear-gradient(135deg, rgba(34,211,238,0.2), rgba(14,165,233,0.1))', border: '1px solid rgba(34,211,238,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, flexShrink: 0 }}>◈</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Blinding Lights</p>
        <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>The Weeknd</p>
      </div>
      <button onClick={e => e.stopPropagation()} style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--accent-grad)', border: 'none', color: '#08121f', fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, boxShadow: '0 4px 12px rgba(34,211,238,0.35)' }}>⏸</button>
      <button onClick={e => e.stopPropagation()} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 16, cursor: 'pointer' }}>⏭</button>
    </div>
  )

  return (
    <div style={{ height: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', alignItems: 'center', padding: '0 22px', background: 'rgba(8,12,20,0.9)', backdropFilter: 'blur(30px)', borderTop: '1px solid rgba(255,255,255,0.06)', fontFamily: 'var(--font-body)' }}>

      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ width: 44, height: 44, borderRadius: 12, flexShrink: 0, background: 'linear-gradient(135deg, rgba(34,211,238,0.2), rgba(14,165,233,0.1))', border: '1px solid rgba(34,211,238,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, boxShadow: '0 4px 14px rgba(34,211,238,0.15)' }}>◈</div>
        <div style={{ minWidth: 0 }}>
          <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 130 }}>Blinding Lights</p>
          <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>The Weeknd</p>
        </div>
        <button style={{ background: 'none', border: 'none', fontSize: 16, color: 'var(--text-muted)', cursor: 'pointer', flexShrink: 0, transition: 'all 0.2s' }}
        onMouseEnter={e => { e.currentTarget.style.color = 'var(--accent-primary)' }}
        onMouseLeave={e => { e.currentTarget.style.color = 'var(--text-muted)' }}
        >♡</button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          {['⇄','⏮'].map(c => <button key={c} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s' }} onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'} onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}>{c}</button>)}
          <button style={{ width: 36, height: 36, borderRadius: '50%', background: 'var(--accent-grad)', border: 'none', color: '#08121f', fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 14px rgba(34,211,238,0.35)', transition: 'transform 0.2s' }} onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.06)'} onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}>⏸</button>
          {['⏭','↻'].map(c => <button key={c} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s' }} onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'} onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}>{c}</button>)}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', maxWidth: 320 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 26, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>1:15</span>
          <div style={{ flex: 1, height: 3, borderRadius: 3, background: 'rgba(255,255,255,0.08)', cursor: 'pointer', position: 'relative' }}>
            <div style={{ width: '38%', height: '100%', borderRadius: 3, background: 'var(--accent-grad)', position: 'relative' }}>
              <div style={{ position: 'absolute', right: -4, top: -4, width: 10, height: 10, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(34,211,238,0.8)' }} />
            </div>
          </div>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 26, fontVariantNumeric: 'tabular-nums' }}>3:20</span>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 12, justifyContent: 'flex-end' }}>
        {['☰','⊞'].map(icon => <button key={icon} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s' }} onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'} onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}>{icon}</button>)}
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>🔈</span>
          <div style={{ width: 75, height: 3, borderRadius: 3, background: 'rgba(255,255,255,0.08)', cursor: 'pointer' }}>
            <div style={{ width: '72%', height: '100%', borderRadius: 3, background: 'linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))' }} />
          </div>
          <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>🔊</span>
        </div>
      </div>
    </div>
  )
}
