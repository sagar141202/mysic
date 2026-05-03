import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'

export default function SongList({ songs, showIndex = true }) {
  const { currentSong, isPlaying, playSong, togglePlay, toggleLike, liked } = usePlayer()

  if (!songs?.length) return (
    <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}>No songs found</div>
  )

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      {songs.map((song, i) => {
        const active  = currentSong.id === song.id
        const playing = active && isPlaying
        const isLiked = liked.has(song.id)
        return (
          <div key={song.id} onClick={() => active ? togglePlay() : playSong(song, songs)}
            style={{ display: 'grid', gridTemplateColumns: showIndex ? '28px auto 1fr auto auto' : 'auto 1fr auto auto', gap: 12, padding: '9px 12px', borderRadius: 12, cursor: 'pointer', alignItems: 'center', background: active ? 'rgba(34,211,238,0.06)' : 'transparent', border: `1px solid ${active ? 'rgba(34,211,238,0.18)' : 'transparent'}`, transition: 'all 0.2s' }}
            onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
            onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}}
          >
            {showIndex && (
              <span style={{ fontSize: 11, textAlign: 'center', color: active ? 'var(--accent-primary)' : 'var(--text-muted)', fontWeight: active ? 600 : 400 }}>
                {playing ? '▶' : active ? '❚❚' : i + 1}
              </span>
            )}
            <div style={{ width: 38, height: 38, borderRadius: 10, flexShrink: 0, overflow: 'hidden', background: `linear-gradient(135deg, ${song.color}28, ${song.color}0d)`, border: `1px solid ${song.color}${active ? '55' : '30'}`, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: active ? `0 0 14px ${song.color}40` : 'none' }}>
              {song.thumbnail
                ? <img src={song.thumbnail} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={e => { e.target.style.display = 'none' }} />
                : <span style={{ fontSize: 14 }}>&#9834;</span>
              }
            </div>
            <div style={{ minWidth: 0 }}>
              <p style={{ fontSize: 13, margin: 0, fontWeight: active ? 500 : 400, color: active ? 'var(--accent-primary)' : 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
              <p style={{ fontSize: 11, margin: 0, color: 'var(--text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.artist}</p>
            </div>
            <button
              onClick={e => { e.stopPropagation(); toggleLike(song.id, song) }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.5))' : 'none', transition: 'all 0.2s', padding: '0 4px' }}
              onMouseEnter={e => { if (!isLiked) e.currentTarget.style.color = 'var(--text-primary)' }}
              onMouseLeave={e => { if (!isLiked) e.currentTarget.style.color = 'var(--text-muted)' }}
            >{isLiked ? '\u2665' : '\u2661'}</button>
            <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 32, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(song.duration)}</span>
          </div>
        )
      })}
    </div>
  )
}
