export default function NowPlaying({ onClose }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', padding: '24px 20px', background: 'rgba(13,13,20,0.95)', backdropFilter: 'blur(24px)', borderLeft: '1px solid var(--glass-border)', fontFamily: 'var(--font-body)', overflowY: 'auto' }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <p style={{ fontSize: '11px', fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.1em', textTransform: 'uppercase', margin: 0 }}>Now Playing</p>
        {onClose && <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '20px', cursor: 'pointer', lineHeight: 1, padding: '4px' }}>✕</button>}
      </div>

      {/* Album Art */}
      <div style={{ width: '100%', aspectRatio: '1', borderRadius: '20px', background: 'linear-gradient(135deg, rgba(168,85,247,0.3), rgba(236,72,153,0.2))', border: '1px solid rgba(168,85,247,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '72px', marginBottom: '24px', position: 'relative', overflow: 'hidden', boxShadow: '0 20px 60px rgba(168,85,247,0.2)' }}>
        <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 30% 30%, rgba(168,85,247,0.2), transparent 60%)' }} />
        💜
      </div>

      {/* Track info */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '6px' }}>
        <div>
          <h3 style={{ fontFamily: 'var(--font-display)', fontSize: '18px', fontWeight: 700, color: 'var(--text-primary)', margin: 0, lineHeight: 1.2 }}>Blinding Lights</h3>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '4px', marginBottom: 0 }}>The Weeknd</p>
        </div>
        <button style={{ background: 'none', border: 'none', fontSize: '20px', color: 'var(--accent-pink)', cursor: 'pointer', paddingTop: '2px' }}>♡</button>
      </div>

      {/* Progress */}
      <div style={{ margin: '20px 0 8px' }}>
        <div style={{ height: '3px', borderRadius: '3px', background: 'rgba(255,255,255,0.1)', position: 'relative', cursor: 'pointer' }}>
          <div style={{ width: '38%', height: '100%', borderRadius: '3px', background: 'var(--accent-grad)', position: 'relative' }}>
            <div style={{ position: 'absolute', right: '-5px', top: '-4px', width: 11, height: 11, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(168,85,247,0.8)' }} />
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '8px' }}>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>1:15</span>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>3:20</span>
        </div>
      </div>

      {/* Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '16px', margin: '8px 0 24px' }}>
        {['⇄', '⏮', null, '⏭', '↻'].map((ctrl, i) => {
          const isPlay = ctrl === null
          return (
            <button key={i} style={{ width: isPlay ? 52 : 36, height: isPlay ? 52 : 36, borderRadius: '50%', background: isPlay ? 'var(--accent-grad)' : 'var(--glass-bg)', border: isPlay ? 'none' : '1px solid var(--glass-border)', color: 'white', fontSize: isPlay ? '20px' : '16px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s ease', boxShadow: isPlay ? '0 8px 24px rgba(168,85,247,0.4)' : 'none', fontFamily: 'monospace' }}
            onMouseEnter={e => { if (!isPlay) e.currentTarget.style.background = 'var(--glass-bg-hover)' }}
            onMouseLeave={e => { if (!isPlay) e.currentTarget.style.background = 'var(--glass-bg)' }}
            >{isPlay ? '⏸' : ctrl}</button>
          )
        })}
      </div>

      {/* Volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '24px' }}>
        <span style={{ fontSize: '14px', color: 'var(--text-muted)' }}>🔈</span>
        <div style={{ flex: 1, height: '3px', borderRadius: '3px', background: 'rgba(255,255,255,0.1)', cursor: 'pointer' }}>
          <div style={{ width: '70%', height: '100%', borderRadius: '3px', background: 'linear-gradient(90deg, var(--accent-purple), var(--accent-pink))' }} />
        </div>
        <span style={{ fontSize: '14px', color: 'var(--text-muted)' }}>🔊</span>
      </div>

      {/* Queue */}
      <div style={{ borderTop: '1px solid var(--glass-border)', paddingTop: '20px' }}>
        <p style={{ fontSize: '11px', fontWeight: 600, letterSpacing: '0.1em', color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: '12px' }}>Up Next</p>
        {[
          { title: 'Save Your Tears', artist: 'The Weeknd', emoji: '��' },
          { title: 'Starboy', artist: 'The Weeknd ft. Daft Punk', emoji: '⭐' },
          { title: 'Rait Zara Si', artist: 'A.R. Rahman', emoji: '🌊' },
        ].map(q => (
          <div key={q.title} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '8px', borderRadius: '10px', cursor: 'pointer', transition: 'all 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.background = 'var(--glass-bg)'}
          onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
          >
            <span style={{ fontSize: '20px' }}>{q.emoji}</span>
            <div>
              <p style={{ fontSize: '13px', color: 'var(--text-primary)', margin: 0 }}>{q.title}</p>
              <p style={{ fontSize: '11px', color: 'var(--text-muted)', margin: 0 }}>{q.artist}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
