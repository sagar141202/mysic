import { useState } from 'react'
import GlassCard from '../components/GlassCard'
import SongList from '../components/SongList'
import { PLAYLISTS, getSongsByIds } from '../data/songs'
import { usePlayer } from '../hooks/usePlayer.jsx'

export default function PlaylistsPage() {
  const [active, setActive] = useState(null)
  const { playSong } = usePlayer()

  const playlist = PLAYLISTS.find(p => p.id === active)
  const songs    = playlist ? getSongsByIds(playlist.songIds) : []

  if (active && playlist) {
    return (
      <div style={{ height: '100%', overflowY: 'auto', padding: '24px 22px', fontFamily: 'var(--font-body)' }}>
        {/* Back */}
        <button onClick={() => setActive(null)} style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: 13, marginBottom: 22, padding: 0, fontFamily: 'var(--font-body)', transition: 'color 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-secondary)'}
        >← Back to Playlists</button>

        {/* Playlist hero */}
        <GlassCard variant="elevated" padding="24px" radius={18} hoverable={false} style={{ marginBottom: 24, overflow: 'hidden', position: 'relative' }}>
          <div style={{ position: 'absolute', top: -24, right: -24, width: 140, height: 140, borderRadius: '50%', background: `radial-gradient(circle, ${playlist.color}25, transparent 70%)`, filter: 'blur(18px)', pointerEvents: 'none' }} />
          <div style={{ position: 'relative', zIndex: 1, display: 'flex', alignItems: 'center', gap: 18 }}>
            <div style={{ width: 72, height: 72, borderRadius: 16, background: `linear-gradient(135deg, ${playlist.color}30, ${playlist.color}10)`, border: `1px solid ${playlist.color}40`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28, boxShadow: `0 8px 24px ${playlist.color}30`, flexShrink: 0 }}>♪</div>
            <div style={{ minWidth: 0 }}>
              <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', margin: '0 0 4px' }}>Playlist</p>
              <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 22, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 4px' }}>{playlist.name}</h2>
              <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0 }}>{playlist.count}</p>
            </div>
            <button
              onClick={() => songs[0] && playSong(songs[0])}
              style={{ marginLeft: 'auto', width: 46, height: 46, borderRadius: '50%', background: 'var(--accent-grad)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 17, color: '#08121f', cursor: 'pointer', boxShadow: '0 4px 18px rgba(34,211,238,0.38)', transition: 'transform 0.2s', flexShrink: 0 }}
              onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.08)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
            >▶</button>
          </div>
        </GlassCard>
        <SongList songs={songs} />
      </div>
    )
  }

  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '24px 22px', fontFamily: 'var(--font-body)' }}>
      <div style={{ marginBottom: 24 }}>
        <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', marginBottom: 4 }}>Your</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 800, margin: 0, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>Playlists</h1>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {PLAYLISTS.map(p => {
          const previewSongs = getSongsByIds(p.songIds.slice(0, 3))
          return (
            <GlassCard key={p.id} variant="elevated" padding="16px" radius={16} onClick={() => setActive(p.id)}
              style={{ display: 'flex', alignItems: 'center', gap: 16, overflow: 'hidden' }}
            >
              <div style={{ position: 'relative', width: 56, height: 56, flexShrink: 0 }}>
                {previewSongs.slice(0, 2).map((s, i) => (
                  <div key={s.id} style={{ position: 'absolute', width: 40, height: 40, borderRadius: 10, background: `linear-gradient(135deg, ${s.color}30, ${s.color}10)`, border: `1px solid ${s.color}35`, top: i * 8, left: i * 8, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, zIndex: 2 - i }}>♪</div>
                ))}
              </div>
              <div style={{ minWidth: 0, flex: 1 }}>
                <p style={{ fontSize: 14, fontWeight: 600, color: 'var(--text-primary)', margin: '0 0 3px', fontFamily: 'var(--font-display)' }}>{p.name}</p>
                <p style={{ fontSize: 11, color: 'var(--text-muted)', margin: 0 }}>{p.count}</p>
              </div>
              <span style={{ color: 'var(--text-muted)', fontSize: 16, flexShrink: 0 }}>›</span>
            </GlassCard>
          )
        })}
      </div>
    </div>
  )
}
