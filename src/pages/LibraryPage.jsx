import { useState } from 'react'
import GlassCard from '../components/GlassCard'
import SongList from '../components/SongList'
import { SONGS, PLAYLISTS, getSongsByIds } from '../data/songs'
import { usePlayer } from '../hooks/usePlayer.jsx'

export default function LibraryPage() {
  const [view, setView]           = useState('all')   // 'all' | playlist id
  const [search, setSearch]       = useState('')
  const { playSong } = usePlayer()

  const filtered = SONGS.filter(s =>
    s.title.toLowerCase().includes(search.toLowerCase()) ||
    s.artist.toLowerCase().includes(search.toLowerCase())
  )

  const activePl = PLAYLISTS.find(p => p.id === view)
  const displaySongs = view === 'all'
    ? filtered
    : getSongsByIds(activePl?.songIds || []).filter(s =>
        s.title.toLowerCase().includes(search.toLowerCase()) ||
        s.artist.toLowerCase().includes(search.toLowerCase())
      )

  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '24px 22px', fontFamily: 'var(--font-body)' }}>
      <div style={{ marginBottom: 22 }}>
        <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', marginBottom: 4 }}>Your</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 800, margin: 0, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>Library</h1>
      </div>

      {/* Search */}
      <div style={{ position: 'relative', marginBottom: 20 }}>
        <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14, pointerEvents: 'none' }}>⊙</span>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search your library..."
          style={{ width: '100%', boxSizing: 'border-box', padding: '11px 16px 11px 40px', background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 14, outline: 'none', color: 'var(--text-primary)', fontSize: 13, fontFamily: 'var(--font-body)', backdropFilter: 'blur(12px)', transition: 'all 0.25s' }}
          onFocus={e => { e.target.style.borderColor = 'rgba(34,211,238,0.40)'; e.target.style.background = 'rgba(34,211,238,0.04)' }}
          onBlur={e =>  { e.target.style.borderColor = 'rgba(255,255,255,0.07)'; e.target.style.background = 'rgba(255,255,255,0.03)' }}
        />
      </div>

      {/* Playlist tabs */}
      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4, marginBottom: 20, scrollbarWidth: 'none' }}>
        <TabChip label="All Songs" active={view === 'all'} color="#22d3ee" onClick={() => setView('all')} />
        {PLAYLISTS.map(p => (
          <TabChip key={p.id} label={p.name} active={view === p.id} color={p.color} onClick={() => setView(p.id)} />
        ))}
      </div>

      {/* Header row */}
      <div style={{ display: 'grid', gridTemplateColumns: '28px auto 1fr auto auto', gap: 12, padding: '0 12px 10px', borderBottom: '1px solid rgba(255,255,255,0.05)', marginBottom: 6 }}>
        {['#', '', 'Title', '♡', '⏱'].map((h, i) => (
          <span key={i} style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.10em', fontWeight: 600 }}>{h}</span>
        ))}
      </div>

      <SongList songs={displaySongs} />
    </div>
  )
}

function TabChip({ label, active, color, onClick }) {
  return (
    <button onClick={onClick} style={{
      flexShrink: 0, padding: '7px 14px', borderRadius: 20, fontSize: 12, fontWeight: 500,
      background: active ? `${color}20` : 'rgba(255,255,255,0.04)',
      border: `1px solid ${active ? color + '50' : 'rgba(255,255,255,0.08)'}`,
      color: active ? color : 'var(--text-secondary)',
      cursor: 'pointer', transition: 'all 0.2s', fontFamily: 'var(--font-body)',
    }}>{label}</button>
  )
}
