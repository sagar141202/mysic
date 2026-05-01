import { useState } from 'react'
import GlassCard from './GlassCard'

const queue = [
  { title: 'Save Your Tears', artist: 'The Weeknd', color: '#22d3ee' },
  { title: 'Starboy', artist: 'The Weeknd', color: '#818cf8' },
  { title: 'Rait Zara Si', artist: 'A.R. Rahman', color: '#f59e0b' },
]

export default function NowPlaying({ onClose }) {
  const [liked, setLiked] = useState(false)

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', padding: '22px 18px', background: 'rgba(8,12,20,0.7)', backdropFilter: 'blur(28px)', WebkitBackdropFilter: 'blur(28px)', borderLeft: '1px solid rgba(255,255,255,0.06)', fontFamily: 'var(--font-body)', overflowY: 'auto' }}>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 22 }}>
        <p style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.12em', textTransform: 'uppercase', margin: 0 }}>Now Playing</p>
        {onClose && <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 16, cursor: 'pointer' }}>✕</button>}
      </div>

      {/* Album Art */}
      <GlassCard radius={18} hoverable={false} glow style={{ aspectRatio: '1', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 22, position: 'relative', overflow: 'hidden', background: 'linear-gradient(135deg, rgba(34,211,238,0.12), rgba(14,165,233,0.06))' }}>
        <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 35% 35%, rgba(34,211,238,0.18), transparent 65%)' }} />
        <div style={{ position: 'absolute', bottom: -20, right: -20, width: 120, height: 120, borderRadius: '50%', background: 'radial-gradient(circle, rgba(245,158,11,0.12), transparent 70%)', filter: 'blur(20px)' }} />
        <span style={{ fontSize: 56, filter: 'drop-shadow(0 0 20px rgba(34,211,238,0.4))', position: 'relative', zIndex: 1 }}>◈</span>
      </GlassCard>

      {/* Track info */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 18 }}>
        <div style={{ minWidth: 0, flex: 1 }}>
          <h3 style={{ fontFamily: 'var(--font-display)', fontSize: 17, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 4px', lineHeight: 1.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Blinding Lights</h3>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0 }}>The Weeknd</p>
        </div>
        <button onClick={() => setLiked(l => !l)} style={{ background: 'none', border: 'none', fontSize: 18, cursor: 'pointer', color: liked ? 'var(--accent-primary)' : 'var(--text-muted)', transition: 'all 0.2s', marginLeft: 8, flexShrink: 0, filter: liked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none' }}>
          {liked ? '♥' : '♡'}
        </button>
      </div>

      {/* Progress bar */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ height: 3, borderRadius: 3, background: 'rgba(255,255,255,0.08)', position: 'relative', cursor: 'pointer' }}>
          <div style={{ width: '38%', height: '100%', borderRadius: 3, background: 'var(--accent-grad)', position: 'relative' }}>
            <div style={{ position: 'absolute', right: -5, top: -4, width: 11, height: 11, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(34,211,238,0.8), 0 0 0 2px rgba(34,211,238,0.3)' }} />
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 7 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>1:15</span>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>3:20</span>
        </div>
      </div>

      {/* Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 14, marginBottom: 20 }}>
        {[
          { icon: '⇄', size: 34 },
          { icon: '⏮', size: 34 },
          { icon: '⏸', size: 50, isPrimary: true },
          { icon: '⏭', size: 34 },
          { icon: '↻', size: 34 },
        ].map((ctrl, i) => (
          <button key={i} style={{
            width: ctrl.size, height: ctrl.size, borderRadius: '50%', flexShrink: 0,
            background: ctrl.isPrimary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)',
            border: ctrl.isPrimary ? 'none' : '1px solid rgba(255,255,255,0.08)',
            color: ctrl.isPrimary ? '#08121f' : 'var(--text-secondary)',
            fontSize: ctrl.isPrimary ? 18 : 14, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'all 0.2s',
            boxShadow: ctrl.isPrimary ? '0 6px 20px rgba(34,211,238,0.35), 0 0 0 1px rgba(34,211,238,0.2)' : 'none',
          }}
          onMouseEnter={e => { if (!ctrl.isPrimary) { e.currentTarget.style.background = 'rgba(34,211,238,0.08)'; e.currentTarget.style.borderColor = 'rgba(34,211,238,0.25)'; e.currentTarget.style.color = 'var(--accent-primary)' } else { e.currentTarget.style.transform = 'scale(1.05)' } }}
          onMouseLeave={e => { if (!ctrl.isPrimary) { e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.08)'; e.currentTarget.style.color = 'var(--text-secondary)' } else { e.currentTarget.style.transform = 'scale(1)' } }}
          >{ctrl.icon}</button>
        ))}
      </div>

      {/* Volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 24 }}>
        <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>🔈</span>
        <div style={{ flex: 1, height: 3, borderRadius: 3, background: 'rgba(255,255,255,0.08)', cursor: 'pointer' }}>
          <div style={{ width: '72%', height: '100%', borderRadius: 3, background: 'linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))' }} />
        </div>
        <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>🔊</span>
      </div>

      {/* Queue */}
      <div style={{ borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: 18, flex: 1 }}>
        <p style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.12em', color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 12 }}>Up Next</p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {queue.map(q => (
            <div key={q.title} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px', borderRadius: 10, cursor: 'pointer', transition: 'all 0.2s' }}
            onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'transparent' }}
            >
              <div style={{ width: 30, height: 30, borderRadius: 8, background: `${q.color}12`, border: `1px solid ${q.color}25`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, color: q.color, flexShrink: 0 }}>♪</div>
              <div style={{ minWidth: 0 }}>
                <p style={{ fontSize: 12, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{q.title}</p>
                <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>{q.artist}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
