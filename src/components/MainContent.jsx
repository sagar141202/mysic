import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import GlassCard from './GlassCard'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { COLLECTIONS, formatTime } from '../data/songs'
import { searchYouTube } from '../utils/ytSearch'

const TRENDING_QUERIES = [
  'top hindi songs 2025',
  'best english hits 2025',
  'arijit singh latest',
  'weeknd best songs',
]

// Shared easing
const EASE = [0.25, 0.46, 0.45, 0.94]

// Stagger container
const listVariants = {
  hidden: {},
  show: { transition: { staggerChildren: 0.045 } },
  exit:  { transition: { staggerChildren: 0.02, staggerDirection: -1 } },
}
const rowVariants = {
  hidden: { opacity: 0, x: -14 },
  show:   { opacity: 1, x: 0, transition: { duration: 0.28, ease: EASE } },
  exit:   { opacity: 0, x: 14, transition: { duration: 0.18, ease: EASE } },
}
const cardVariants = {
  hidden: { opacity: 0, y: 20, scale: 0.96 },
  show:   (i) => ({ opacity: 1, y: 0, scale: 1, transition: { duration: 0.32, delay: i * 0.06, ease: EASE } }),
}

export default function MainContent({ screenSize = 'desktop' }) {
  const [search,        setSearch]        = useState('')
  const [searchResults, setSearchResults] = useState([])
  const [searching,     setSearching]     = useState(false)
  const [trending,      setTrending]      = useState([])
  const [trendingLoad,  setTrendingLoad]  = useState(true)
  const debounceRef = useRef(null)

  const isMobile = screenSize === 'mobile'
  const isTablet = screenSize === 'tablet'
  const { currentSong, isPlaying, playSong, togglePlay, toggleLike, liked } = usePlayer()

  useEffect(() => {
    const q = TRENDING_QUERIES[Math.floor(Math.random() * TRENDING_QUERIES.length)]
    searchYouTube(q, 8).then(res => { setTrending(res); setTrendingLoad(false) })
  }, [])

  useEffect(() => {
    if (!search.trim()) { setSearchResults([]); return }
    setSearching(true)
    clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(async () => {
      const res = await searchYouTube(search, 20)
      setSearchResults(res)
      setSearching(false)
    }, 500)
  }, [search])

  const showSearch   = !!search.trim()
  const displaySongs = showSearch ? searchResults : trending

  return (
    <div style={{ height: '100%', overflowY: 'auto', padding: isMobile ? '18px 14px 8px' : '24px 22px', fontFamily: 'var(--font-body)' }}>

      {/* Header — fade + slide in on mount */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: EASE }}
        style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}
      >
        <div>
          <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', marginBottom: 4 }}>Good Evening</p>
          <h1 style={{ fontFamily: 'var(--font-display)', fontSize: isMobile ? 20 : 26, fontWeight: 800, lineHeight: 1.15, margin: 0, background: 'var(--accent-grad)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>
            What's the vibe?
          </h1>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {(isMobile ? ['🔔'] : ['🔔', '⊙', '⚙']).map((icon, i) => (
            <motion.button
              key={icon}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.3, delay: 0.1 + i * 0.05, ease: EASE }}
              whileHover={{ scale: 1.12 }}
              whileTap={{ scale: 0.92 }}
              style={{ width: 36, height: 36, borderRadius: '50%', background: 'var(--glass-bg)', border: '1px solid var(--glass-border)', backdropFilter: 'blur(12px)', color: 'var(--text-secondary)', fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(34,211,238,0.35)'; e.currentTarget.style.background = 'rgba(34,211,238,0.06)'; e.currentTarget.style.color = 'var(--accent-primary)' }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--glass-border)'; e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.color = 'var(--text-secondary)' }}
            >{icon}</motion.button>
          ))}
        </div>
      </motion.div>

      {/* Search bar */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35, delay: 0.08, ease: EASE }}
        style={{ position: 'relative', marginBottom: 28 }}
      >
        <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14, pointerEvents: 'none' }}>⊙</span>
        <AnimatePresence>
          {searching && (
            <motion.span
              key="spinner"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--accent-primary)', fontSize: 12 }}
            >...</motion.span>
          )}
        </AnimatePresence>
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search any song, artist, mood on YouTube..."
          style={{ width: '100%', boxSizing: 'border-box', padding: '13px 40px 13px 40px', background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 14, outline: 'none', color: 'var(--text-primary)', fontSize: 13, fontFamily: 'var(--font-body)', backdropFilter: 'blur(12px)', transition: 'all 0.25s' }}
          onFocus={e => { e.target.style.borderColor = 'rgba(34,211,238,0.40)'; e.target.style.background = 'rgba(34,211,238,0.04)'; e.target.style.boxShadow = '0 0 0 3px rgba(34,211,238,0.07)' }}
          onBlur={e =>  { e.target.style.borderColor = 'rgba(255,255,255,0.07)'; e.target.style.background = 'rgba(255,255,255,0.03)'; e.target.style.boxShadow = 'none' }}
        />
      </motion.div>

      {/* Collections grid */}
      <AnimatePresence mode="wait">
        {!isMobile && !showSearch && (
          <motion.div
            key="collections"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.25 }}
            style={{ marginBottom: 28 }}
          >
            <SectionHeader title="Collections" />
            <div style={{ display: 'grid', gridTemplateColumns: isTablet ? 'repeat(2,1fr)' : 'repeat(4,1fr)', gap: 10 }}>
              {COLLECTIONS.map((c, i) => (
                <motion.div
                  key={c.name}
                  custom={i}
                  variants={cardVariants}
                  initial="hidden"
                  animate="show"
                  whileHover={{ scale: 1.03, y: -3, transition: { duration: 0.18 } }}
                  whileTap={{ scale: 0.97 }}
                >
                  <GlassCard variant="elevated" padding="14px" radius={14} onClick={() => setSearch(c.name.toLowerCase())} style={{ overflow: 'hidden', cursor: 'pointer' }}>
                    <div style={{ position: 'absolute', top: -16, right: -16, width: 64, height: 64, borderRadius: '50%', background: `${c.color}20`, filter: 'blur(14px)', pointerEvents: 'none' }} />
                    <div style={{ width: 36, height: 36, borderRadius: 10, marginBottom: 10, background: `${c.color}18`, border: `1px solid ${c.color}35`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, boxShadow: `0 4px 12px ${c.color}20` }}>♪</div>
                    <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', margin: '0 0 2px', fontFamily: 'var(--font-display)' }}>{c.name}</p>
                    <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>{c.count}</p>
                  </GlassCard>
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Song list */}
      <div style={{ paddingBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <AnimatePresence mode="wait">
            <motion.h2
              key={showSearch ? 'search' : 'trending'}
              initial={{ opacity: 0, x: -8 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 8 }}
              transition={{ duration: 0.2 }}
              style={{ fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}
            >
              {showSearch ? `Results for "${search}"` : 'Trending Now'}
            </motion.h2>
          </AnimatePresence>
          <AnimatePresence>
            {(searching || trendingLoad) && (
              <motion.span
                key="loading"
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                style={{ fontSize: 11, color: 'var(--accent-primary)' }}
              >
                {searching ? 'Searching YouTube…' : 'Loading…'}
              </motion.span>
            )}
          </AnimatePresence>
        </div>

        {(trendingLoad && !showSearch) || (searching && showSearch) ? (
          <SkeletonList count={6} />
        ) : displaySongs.length === 0 && showSearch ? (
          <motion.div
            initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
            style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}
          >
            No results for "{search}"
          </motion.div>
        ) : (
          <AnimatePresence mode="wait">
            <motion.div
              key={showSearch ? `search-${search}` : 'trending'}
              variants={listVariants}
              initial="hidden"
              animate="show"
              exit="exit"
              style={{ display: 'flex', flexDirection: 'column', gap: 2 }}
            >
              {displaySongs.map((song, i) => (
                <motion.div key={song.id} variants={rowVariants} layout>
                  <SongRow
                    song={song} index={i}
                    active={currentSong.id === song.id}
                    isPlaying={isPlaying && currentSong.id === song.id}
                    isLiked={liked.has(song.id)}
                    isMobile={isMobile} isTablet={isTablet}
                    onClick={() => currentSong.id === song.id ? togglePlay() : playSong(song, displaySongs)}
                    onLike={e => { e.stopPropagation(); toggleLike(song.id, song) }}
                  />
                </motion.div>
              ))}
            </motion.div>
          </AnimatePresence>
        )}
      </div>
    </div>
  )
}

function SkeletonList({ count }) {
  return (
    <motion.div
      variants={listVariants} initial="hidden" animate="show"
      style={{ display: 'flex', flexDirection: 'column', gap: 8 }}
    >
      {Array.from({ length: count }).map((_, i) => (
        <motion.div key={i} variants={rowVariants} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', borderRadius: 12 }}>
          <div style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(255,255,255,0.05)', animation: 'pulse-glow 1.5s ease-in-out infinite', flexShrink: 0 }} />
          <div style={{ flex: 1 }}>
            <div style={{ height: 12, borderRadius: 6, background: 'rgba(255,255,255,0.05)', marginBottom: 8, width: `${50 + (i * 13) % 30}%`, animation: 'pulse-glow 1.5s ease-in-out infinite' }} />
            <div style={{ height: 10, borderRadius: 6, background: 'rgba(255,255,255,0.03)', width: '35%', animation: 'pulse-glow 1.5s ease-in-out infinite' }} />
          </div>
        </motion.div>
      ))}
    </motion.div>
  )
}

function SectionHeader({ title }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
      <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>{title}</h2>
    </div>
  )
}

function SongRow({ song, index, active, isPlaying, isLiked, isMobile, onClick, onLike }) {
  return (
    <motion.div
      onClick={onClick}
      whileHover={{ x: 3, transition: { duration: 0.15 } }}
      whileTap={{ scale: 0.99 }}
      style={{
        display: 'grid',
        gridTemplateColumns: isMobile ? 'auto 1fr auto' : '28px auto 1fr auto auto',
        gap: 12, padding: isMobile ? '10px 8px' : '9px 12px',
        borderRadius: 12, cursor: 'pointer', alignItems: 'center',
        background: active ? 'rgba(34,211,238,0.06)' : 'transparent',
        border: `1px solid ${active ? 'rgba(34,211,238,0.18)' : 'transparent'}`,
        transition: 'background 0.2s, border-color 0.2s',
      }}
      onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
      onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}}
    >
      {!isMobile && (
        <span style={{ fontSize: 11, textAlign: 'center', color: active ? 'var(--accent-primary)' : 'var(--text-muted)', fontWeight: active ? 600 : 400 }}>
          {isPlaying ? '▶' : active ? '❚❚' : index + 1}
        </span>
      )}
      <div style={{ width: 40, height: 40, borderRadius: 10, flexShrink: 0, overflow: 'hidden', background: `linear-gradient(135deg, ${song.color}28, ${song.color}0d)`, border: `1px solid ${song.color}${active ? '55' : '30'}`, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: active ? `0 0 14px ${song.color}40` : 'none' }}>
        {song.thumbnail
          ? <img src={song.thumbnail} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={e => { e.target.style.display = 'none' }} />
          : <span style={{ fontSize: 16 }}>♪</span>
        }
      </div>
      <div style={{ minWidth: 0 }}>
        <p style={{ fontSize: 13, margin: 0, fontWeight: active ? 500 : 400, color: active ? 'var(--accent-primary)' : 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
        <p style={{ fontSize: 11, margin: 0, color: 'var(--text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.artist}</p>
      </div>
      <motion.button
        onClick={onLike}
        whileHover={{ scale: 1.2 }} whileTap={{ scale: 0.85 }}
        style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.5))' : 'none', transition: 'color 0.2s, filter 0.2s', padding: '0 4px' }}
      >{isLiked ? '♥' : '♡'}</motion.button>
      <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 32, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(song.duration)}</span>
    </motion.div>
  )
}
