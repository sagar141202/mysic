export default function Player() {
  return (
    <div style={{
      height: '100%',
      display: 'grid',
      gridTemplateColumns: '1fr 1fr 1fr',
      alignItems: 'center',
      padding: '0 24px',
      background: 'rgba(10,10,15,0.8)',
      backdropFilter: 'blur(30px)',
      borderTop: '1px solid var(--glass-border)',
      fontFamily: 'var(--font-body)',
    }}>

      {/* Left — Track info */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        <div style={{
          width: 48, height: 48, borderRadius: '12px', flexShrink: 0,
          background: 'linear-gradient(135deg, rgba(168,85,247,0.4), rgba(236,72,153,0.3))',
          border: '1px solid rgba(168,85,247,0.3)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '22px',
          boxShadow: '0 4px 16px rgba(168,85,247,0.2)',
        }}>💜</div>
        <div>
          <p style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-primary)', margin: 0 }}>Blinding Lights</p>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: 0 }}>The Weeknd</p>
        </div>
        <button style={{ marginLeft: '8px', background: 'none', border: 'none', fontSize: '18px', color: 'var(--text-muted)', cursor: 'pointer' }}>♡</button>
      </div>

      {/* Center — Controls */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          {['⇄', '⏮'].map(ctrl => (
            <button key={ctrl} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '16px', cursor: 'pointer', transition: 'color 0.2s' }}
            onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
            onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
            >{ctrl}</button>
          ))}
          <button style={{
            width: 40, height: 40, borderRadius: '50%',
            background: 'var(--accent-grad)',
            border: 'none', color: 'white', fontSize: '16px',
            cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 16px rgba(168,85,247,0.4)',
            transition: 'transform 0.2s',
          }}
          onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
          onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
          >⏸</button>
          {['⏭', '↻'].map(ctrl => (
            <button key={ctrl} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '16px', cursor: 'pointer', transition: 'color 0.2s' }}
            onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
            onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
            >{ctrl}</button>
          ))}
        </div>
        {/* Progress */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', width: '100%', maxWidth: '360px' }}>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)', minWidth: '30px', textAlign: 'right' }}>1:15</span>
          <div style={{ flex: 1, height: '3px', borderRadius: '3px', background: 'rgba(255,255,255,0.1)', cursor: 'pointer', position: 'relative' }}>
            <div style={{ width: '38%', height: '100%', borderRadius: '3px', background: 'var(--accent-grad)', position: 'relative' }}>
              <div style={{ position: 'absolute', right: '-5px', top: '-4px', width: 11, height: 11, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(168,85,247,0.8)' }} />
            </div>
          </div>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)', minWidth: '30px' }}>3:20</span>
        </div>
      </div>

      {/* Right — Volume & extras */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px', justifyContent: 'flex-end' }}>
        {['☰', '⊞', '📻'].map(icon => (
          <button key={icon} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '16px', cursor: 'pointer' }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
          >{icon}</button>
        ))}
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
