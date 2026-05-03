import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]
const listVariants = {
  hidden: {},
  show:   { transition: { staggerChildren: 0.04 } },
}
const rowVariants = {
  hidden: { opacity: 0, x: -12 },
  show:   { opacity: 1, x: 0, transition: { duration: 0.26, ease: EASE } },
}

export default function SongList({ songs, showIndex = true }) {
  const { currentSong, isPlaying, playSong, togglePlay, toggleLike, liked } = usePlayer()

  if (!songs?.length) return (
    <motion.div
      initial={{ opacity: 0 }} animate={{ opacity: 1 }}
      style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}
    >
      No songs found
    </motion.div>
  )

  return (
    <motion.div
      variants={listVariants} initial="hidden" animate="show"
      style={{ display: 'flex', flexDirection: 'column', gap: 2 }}
    >
      {songs.map((song, i) => {
        const active  = currentSong.id === song.id
        const playing = active && isPlaying
        const isLiked = liked.has(song.id)
        return (
          <motion.div
            key={song.id}
            variants={rowVariants}
            layout
            onClick={() => active ? togglePlay() : playSong(song, songs)}
            whileHover={{ x: 3, transition: { duration: 0.15 } }}
            whileTap={{ scale: 0.99 }}
            style={{ display: 'grid', gridTemplateColumns: showIndex ? '28px auto 1fr auto auto' : 'auto 1fr auto auto', gap: 12, padding: '9px 12px', borderRadius: 12, cursor: 'pointer', alignItems: 'center', background: active ? 'rgba(34,211,238,0.06)' : 'transparent', border: `1px solid ${active ? 'rgba(34,211,238,0.18)' : 'transparent'}`, transition: 'background 0.2s, border-color 0.2s' }}
            onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
            onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}}
          >
            {showIndex && (
              <span style={{ fontSize: 11, textAlign: 'center', color: active ? 'var(--accent-primary)' : 'var(--text-muted)', fontWeight: active ? 600 : 400 }}>
                {playing ? '▶' : active ? '❚❚' : i + 1}
              </span>
            )}
            <AlbumArt song={song} size="sm" isPlaying={playing} />
            <div style={{ minWidth: 0 }}>
              <p style={{ fontSize: 13, margin: 0, fontWeight: active ? 500 : 400, color: active ? 'var(--accent-primary)' : 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
              <p style={{ fontSize: 11, margin: 0, color: 'var(--text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.artist}</p>
            </div>
            <motion.button
              onClick={e => { e.stopPropagation(); toggleLike(song.id, song) }}
              whileHover={{ scale: 1.25 }} whileTap={{ scale: 0.8 }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.5))' : 'none', transition: 'color 0.2s, filter 0.2s', padding: '0 4px' }}
            >{isLiked ? '\u2665' : '\u2661'}</motion.button>
            <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 32, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(song.duration)}</span>
          </motion.div>
        )
      })}
    </motion.div>
  )
}
