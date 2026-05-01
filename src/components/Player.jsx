export default function Player({ mobile = false, onNowPlayingClick }) {
  if (mobile) {
    return (
      <div onClick={onNowPlayingClick} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 16px', background: 'rgba(20,20,30,0.95)', backdropFilter: 'blur(20px)', borderTop: '1px solid var(--glass-border)', cursor: 'pointer', fontFamily: 'var(--font-body)' }}>
        <div style={{ width: 42, height: 42, borderRadius: '10px', background: 'linear-gradient(135deg, rgba(168,85,247,0.4), rgba(236,72,153,0.3))', border: '1px solid rgba(168,85,247,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', flexShrink: 0 }}>��</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <p style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Blinding Lights</p>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: 0 }}>The Weeknd</p>
        </div>
        <button onClick={e => e.stopPropagation()} style={{ width: 36, height: 36, borderRadius: '50%', background: 'var(--accent-grad)', border: 'none', color: 'white', fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, boxShadow: '0 4px 12px rgba(168,85,247,0.4)' }}>⏸</button>
        <button onClick={e => e.stopPropagation()} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '18px', cursor: 'pointer', flexShrink: 0 }}>⏭</button>
      </div>
    )
  }

  return (
    <div style={{ height: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', alignItems: 'center', padding: '0 24px', background: 'rgba(10,10,15,0.85)', backdropFilter: 'blur(30px)', borderTop: '1px solid var(--glass-border)', fontFamily: 'var(--font-body)' }}>

      {/* Left */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        <div style={{ width: 46, height: 46, borderRadius: '12px', flexShrink: 0, background: 'linear-gradient(135deg, rgba(168,85,247,0.4), rgba(236,72,153,0.3))', border: '1px solid rgba(168,85,247,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', boxShadow: '0 4px 16px rgba(168,85,247,0.2)' }}>💜</div>
        <div style={{ minWidth: 0 }}>
          <p style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '140px' }}>Blinding Lights</p>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: 0 }}>The Weeknd</p>
        </div>
        <button style={{ background: 'none', border: 'none', fontSize: '17px', color: 'var(--text-muted)', cursor: 'pointer', flexShrink: 0 }}>♡</button>
      </div>

      {/* Center */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '18px' }}>
          {['⇄', '⏮'].map(c => <button key={c} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '15px', cursor: 'pointer', transition: 'color 0.2s' }} onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'} onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}>{c}</button>)}
          <button style={{ width: 38, height: 38, borderRadius: '50%', background: 'var(--accent-grad)', border: 'none', color: 'white', fontSize: '15px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 16px rgba(168,85,247,0.4)', transition: 'transform 0.2s' }} onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.06)'} onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}>⏸</button>
          {['⏭', '↻'].map(c => <button key={c} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '15px', cursor: 'pointer', transition: 'color 0.2s' }} onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'} onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}>{c}</button>)}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', width: '100%', maxWidth: '340px' }}>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)', minWidth: '28px', textAlign: 'right' }}>1:15</span>
          <div style={{ flex: 1, height: '3px', borderRadius: '3px', background: 'rgba(255,255,255,0.1)', cursor: 'pointer', position: 'relative' }}>
            <div style={{ width: '38%', height: '100%', borderRadius: '3px', background: 'var(--accent-grad)', position: 'relative' }}>
              <div style={{ position: 'absolute', right: '-5px', top: '-4px', width: 10, height: 10, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(168,85,247,0.8)' }} />
            </div>
          </div>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)', minWidth: '28px' }}>3:20</span>
        </div>
      </div>

      {/* Right */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px', justifyContent: 'flex-end' }}>
        {['☰', '⊞'].map(icon => <button key={icon} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '15px', cursor: 'pointer' }} onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'} onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}>{icon}</button>)}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{ fontSize: '14px', color: 'var(--text-muted)' }}>🔈</span>
          <div style={{ width: '80px', height: '3px', borderRadius: '3px', background: 'rgba(255,255,255,0.1)', cursor: 'pointer' }}>
            <div style={{ width: '70%', height: '100%', borderRadius: '3px', background: 'linear-gradient(90deg, var(--accent-purple), var(--accent-pink))' }} />
          </div>
          <span style={{ fontSize: '14px', color: 'var(--text-muted)' }}>🔊</span>
        </div>
      </div>
    </div>
  )
}
