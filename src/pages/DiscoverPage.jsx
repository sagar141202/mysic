import { useState, useEffect } from 'react'
import GlassCard from '../components/GlassCard'
import SongList from '../components/SongList'
import { GENRES } from '../data/songs'
import { searchYouTube } from '../utils/ytSearch'
import { usePlayer } from '../hooks/usePlayer.jsx'

const GENRE_QUERIES = {
  bollywood: 'best bollywood songs 2025',
  pop:       'top pop hits 2025',
  edm:       'best edm electronic 2025',
  indie:     'best indie songs 2025',
  kpop:      'best kpop songs 2025',
  latin:     'best latin songs 2025',
  afrobeats: 'best afrobeats 2025',
}

function SkeletonList({ count = 5 }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px' }}>
          <div style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(255,255,255,0.05)', flexShrink: 0 }} />
          <div style={{ flex: 1 }}>
            <div style={{ height: 12, borderRadius: 6, background: 'rgba(255,255,255,0.05)', marginBottom: 8, width: '55%' }} />
            <div style={{ height: 10, borderRadius: 6, background: 'rgba(255,255,255,0.03)', width: '35%' }} />
          </div>
        </div>
      ))}
    </div>
  )
}

export default function DiscoverPage() {
  const [activeGenre, setActiveGenre] = useState('pop')
  const [songs,       setSongs]       = useState([])
  const [loading,     setLoading]     = useState(true)
  const { playSong } = usePlayer()

  useEffect(() => {
    setLoading(true)
    setSongs([])
    const query = GENRE_QUERIES[activeGenre] || `best ${activeGenre} songs 2025`
    searchYouTube(query, 20).then(res => {
      setSongs(res)
      setLoading(false)
    })
  }, [activeGenre])

  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: '24px 22px', fontFamily: 'var(--font-body)' }}>
      <div style={{ marginBottom: 26 }}>
        <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', marginBottom: 4 }}>Browse</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 800, margin: 0, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>Discover</h1>
      </div>

      {/* Genre chips */}
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 24 }}>
        {GENRES.map(g => (
          <button key={g.key} onClick={() => setActiveGenre(g.key)} style={{
            padding: '8px 18px', borderRadius: 20, fontSize: 12, fontWeight: 500,
            background: activeGenre === g.key ? `${g.color}22` : 'rgba(255,255,255,0.04)',
            border: `1px solid ${activeGenre === g.key ? g.color + '55' : 'rgba(255,255,255,0.08)'}`,
            color: activeGenre === g.key ? g.color : 'var(--text-secondary)',
            cursor: 'pointer', transition: 'all 0.2s', fontFamily: 'var(--font-body)',
            boxShadow: activeGenre === g.key ? `0 0 12px ${g.color}25` : 'none',
          }}>{g.name}</button>
        ))}
      </div>

      {/* Results */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>
          {GENRES.find(g => g.key === activeGenre)?.name} Songs
        </h2>
        {loading && <span style={{ fontSize: 11, color: 'var(--accent-primary)' }}>Loading from YouTube…</span>}
      </div>

      {loading ? <SkeletonList count={8} /> : <SongList songs={songs} />}
    </div>
  )
}
