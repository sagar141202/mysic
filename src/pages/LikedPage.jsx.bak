import GlassCard from '../components/GlassCard'
import SongList from '../components/SongList'
import { usePlayer } from '../hooks/usePlayer.jsx'

export default function LikedPage() {
  const { likedSongs, playSong } = usePlayer()

  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '24px 22px', fontFamily: 'var(--font-body)' }}>
      <GlassCard variant="elevated" padding="28px 24px" radius={20} hoverable={false}
        style={{ marginBottom: 28, overflow: 'hidden', position: 'relative' }}>
        <div style={{ position: 'absolute', top: -30, right: -30, width: 160, height: 160, borderRadius: '50%', background: 'radial-gradient(circle, rgba(34,211,238,0.15), transparent 70%)', filter: 'blur(20px)', pointerEvents: 'none' }} />
        <div style={{ position: 'relative', zIndex: 1 }}>
          <div style={{ fontSize: 40, marginBottom: 10, filter: 'drop-shadow(0 0 16px rgba(34,211,238,0.6))' }}>♥</div>
          <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 28, fontWeight: 800, margin: '0 0 6px', background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>Liked Songs</h1>
          <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0 }}>{likedSongs.length} song{likedSongs.length !== 1 ? 's' : ''}</p>
        </div>
        {likedSongs.length > 0 && (
          <button
            onClick={() => playSong(likedSongs[0], likedSongs)}
            style={{ position: 'absolute', bottom: 24, right: 24, width: 48, height: 48, borderRadius: '50%', background: 'var(--accent-grad)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, color: '#08121f', cursor: 'pointer', boxShadow: '0 4px 20px rgba(34,211,238,0.4)', transition: 'transform 0.2s', zIndex: 1 }}
            onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.08)'}
            onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
          >▶</button>
        )}
      </GlassCard>

      {likedSongs.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '60px 0', color: 'var(--text-muted)' }}>
          <div style={{ fontSize: 48, marginBottom: 14, opacity: 0.3 }}>♡</div>
          <p style={{ fontSize: 15, marginBottom: 6, color: 'var(--text-secondary)' }}>No liked songs yet</p>
          <p style={{ fontSize: 12 }}>Tap ♡ on any song to add it here</p>
        </div>
      ) : (
        <SongList songs={likedSongs} />
      )}
    </div>
  )
}
