/**
 * LikedPage.jsx
 *
 * Reads likedSongs from usePlayer context (array of full song objects).
 * No localStorage reads — the context is the single source of truth.
 *
 * Crash fix: the previous implementation read localStorage 'mysic_liked'
 * which after fix-progress-tracking.sh contained plain ID strings instead
 * of song objects, causing song.title → undefined → blank page.
 */
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import SongList from '../components/SongList'

const EASE = [0.25, 0.46, 0.45, 0.94]

export default function LikedPage() {
  const { likedSongs, playSong } = usePlayer()

  return (
    <div style={{
      height: '100%',
      overflowY: 'auto',
      overflowX: 'hidden',
      overscrollBehavior: 'contain',
      WebkitOverflowScrolling: 'touch',
      fontFamily: 'var(--font-body)',
    }}>
      <div style={{ padding: '28px 24px 100px', maxWidth: 860, margin: '0 auto' }}>

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.30, ease: EASE }}
          style={{ marginBottom: 28 }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 6 }}>
            <div style={{
              width: 48, height: 48, borderRadius: 14, flexShrink: 0,
              background: 'linear-gradient(135deg, rgba(34,211,238,0.18), rgba(139,92,246,0.18))',
              border: '1px solid rgba(34,211,238,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22,
            }}>♥</div>
            <div>
              <h1 style={{
                fontFamily: 'var(--font-display)',
                fontSize: 'clamp(20px, 4vw, 28px)',
                fontWeight: 800,
                margin: 0, lineHeight: 1.2,
                background: 'var(--accent-grad)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
              }}>
                Liked Songs
              </h1>
              <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: '3px 0 0' }}>
                {likedSongs.length === 0
                  ? 'No liked songs yet'
                  : `${likedSongs.length} song${likedSongs.length === 1 ? '' : 's'}`}
              </p>
            </div>
          </div>

          {/* Play all button — only when there are songs */}
          {likedSongs.length > 0 && (
            <motion.button
              onClick={() => playSong(likedSongs[0], likedSongs)}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.96 }}
              style={{
                marginTop: 16,
                padding: '10px 24px',
                borderRadius: 50,
                background: 'var(--accent-grad)',
                border: 'none',
                color: '#08121f',
                fontFamily: 'var(--font-body)',
                fontSize: 13, fontWeight: 700,
                cursor: 'pointer',
                boxShadow: '0 4px 16px rgba(34,211,238,0.35)',
                display: 'inline-flex', alignItems: 'center', gap: 8,
              }}
            >
              ▶ Play all
            </motion.button>
          )}
        </motion.div>

        {/* Song list */}
        <AnimatePresence mode="wait">
          {likedSongs.length === 0 ? (
            <motion.div
              key="empty"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.24, ease: EASE }}
              style={{
                textAlign: 'center',
                padding: '60px 20px',
                color: 'var(--text-muted)',
              }}
            >
              <div style={{ fontSize: 40, marginBottom: 12, opacity: 0.3 }}>♡</div>
              <p style={{ fontSize: 15, margin: '0 0 6px', color: 'var(--text-secondary)' }}>
                No liked songs yet
              </p>
              <p style={{ fontSize: 12, margin: 0 }}>
                Tap ♡ on any song to add it here
              </p>
            </motion.div>
          ) : (
            <motion.div
              key="list"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.20 }}
            >
              <SongList songs={likedSongs} showIndex={true} />
            </motion.div>
          )}
        </AnimatePresence>

      </div>
    </div>
  )
}
