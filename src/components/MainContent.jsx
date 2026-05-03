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

const EASE = [0.25, 0.46, 0.45, 0.94]

const listVariants = {
  hidden: {},
  show:  { transition: { staggerChildren: 0.045 } },
  exit:  { transition: { staggerChildren: 0.02, staggerDirection: -1 } },
}
const rowVariants = {
  hidden: { opacity: 0, x: -14 },
  show:   { opacity: 1, x: 0, transition: { duration: 0.26, ease: EASE } },
  exit:   { opacity: 0, x: 14, transition: { duration: 0.18, ease: EASE } },
}
const cardVariants = {
  hidden: { opacity: 0, y: 20, scale: 0.96 },
  show:   (i) => ({ opacity: 1, y: 0, scale: 1, transition: { duration: 0.30, delay: i * 0.055, ease: EASE } }),
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

  /* responsive padding: 14px on mobile → 28px on desktop */
  const hPad = isMobile ? 14 : isTablet ? 20 : 28

  return (
    <div style={{
      height: '100%',
      overflowY: 'auto',
      overscrollBehavior: 'contain',
      WebkitOverflowScrolling: 'touch',
      padding: `${isMobile ? 16 : 24}px ${hPad}px ${isMobile ? 8 : 16}px`,
      fontFamily: 'var(--font-body)',
      /* ensure nothing pokes outside */
      boxSizing: 'border-box',
      maxWidth: '100%',
    }}>

      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.38, ease: EASE }}
        style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: isMobile ? 16 : 22,
          /* prevent header content from wrapping oddly */
          gap: 12, minWidth: 0,
        }}
      >
        <div style={{ minWidth: 0 }}>
          <p style={{ fontSize: 10, color: 'var(--text-muted)', letterSpacing: '0.10em', textTransform: 'uppercase', marginBottom: 3, margin: '0 0 3px' }}>
            Good Evening
          </p>
          <h1 style={{
            fontFamily: 'var(--font-display)',
            /* clamp: min 18px (small phone) → max 28px (desktop) */
            fontSize: 'clamp(18px, 5vw, 28px)',
            fontWeight: 800, lineHeight: 1.15, margin: 0,
            background: 'var(--accent-grad)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
            /* prevent overflow on narrow screens */
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>
            What's the vibe?
          </h1>
        </div>

        <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
          {(isMobile ? ['🔔'] : ['🔔', '⊙', '⚙']).map((icon, i) => (
            <motion.button
              key={icon}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.28, delay: 0.08 + i * 0.05, ease: EASE }}
              whileHover={{ scale: 1.12 }}
              whileTap={{ scale: 0.90 }}
              /* 44px tap target */
              style={{
                width: 44, height: 44, borderRadius: '50%',
                background: 'var(--glass-bg)',
                border: '1px solid var(--glass-border)',
                backdropFilter: 'blur(12px)',
                color: 'var(--text-secondary)', fontSize: 15,
                cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                WebkitTapHighlightColor: 'transparent',
                touchAction: 'manipulation',
              }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(34,211,238,0.35)'; e.currentTarget.style.background = 'rgba(34,211,238,0.06)'; e.currentTarget.style.color = 'var(--accent-primary)' }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--glass-border)'; e.currentTarget.style.background = 'var(--glass-bg)'; e.currentTarget.style.color = 'var(--text-secondary)' }}
            >
              {icon}
            </motion.button>
          ))}
        </div>
      </motion.div>

      {/* Search bar */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.32, delay: 0.07, ease: EASE }}
        style={{ position: 'relative', marginBottom: isMobile ? 20 : 26 }}
      >
        <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14, pointerEvents: 'none', zIndex: 1 }}>⊙</span>
        <AnimatePresence>
          {searching && (
            <motion.span
              key="spinner"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--accent-primary)', fontSize: 12, zIndex: 1 }}
            >
              ···
            </motion.span>
          )}
        </AnimatePresence>
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder={isMobile ? 'Search songs…' : 'Search any song, artist, mood on YouTube…'}
          style={{
            width: '100%', boxSizing: 'border-box',
            /* 48px height = comfortable mobile tap */
            padding: isMobile ? '14px 42px 14px 42px' : '13px 42px 13px 42px',
            background: 'rgba(255,255,255,0.03)',
            border: '1px solid rgba(255,255,255,0.07)',
            borderRadius: 14, outline: 'none',
            color: 'var(--text-primary)',
            /* 16px prevents iOS auto-zoom on focus */
            fontSize: isMobile ? 16 : 13,
            fontFamily: 'var(--font-body)',
            backdropFilter: 'blur(12px)',
            transition: 'all 0.22s',
            /* stop mobile keyboard from resizing layout */
            WebkitAppearance: 'none',
          }}
          onFocus={e => { e.target.style.borderColor = 'rgba(34,211,238,0.42)'; e.target.style.background = 'rgba(34,211,238,0.04)'; e.target.style.boxShadow = '0 0 0 3px rgba(34,211,238,0.08)' }}
          onBlur={e  => { e.target.style.borderColor = 'rgba(255,255,255,0.07)'; e.target.style.background = 'rgba(255,255,255,0.03)'; e.target.style.boxShadow = 'none' }}
        />
      </motion.div>

      {/* Collections grid — 2 col on mobile, 2 on tablet, 4 on desktop */}
      <AnimatePresence mode="wait">
        {!showSearch && (
          <motion.div
            key="collections"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.22 }}
            style={{ marginBottom: isMobile ? 20 : 26 }}
          >
            <SectionHeader title="Collections" />
            <div style={{
              display: 'grid',
              gridTemplateColumns: isMobile
                ? 'repeat(2, 1fr)'
                : isTablet ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)',
              gap: isMobile ? 8 : 10,
            }}>
              {COLLECTIONS.map((c, i) => (
                <motion.div
                  key={c.name}
                  custom={i}
                  variants={cardVariants}
                  initial="hidden"
                  animate="show"
                  whileHover={{ scale: 1.03, y: -3, transition: { duration: 0.16 } }}
                  whileTap={{ scale: 0.96 }}
                >
                  <GlassCard
                    variant="elevated"
                    padding={isMobile ? '12px' : '14px'}
                    radius={14}
                    onClick={() => setSearch(c.name.toLowerCase())}
                    style={{ overflow: 'hidden', cursor: 'pointer' }}
                  >
                    <div style={{ position: 'absolute', top: -16, right: -16, width: 64, height: 64, borderRadius: '50%', background: `${c.color}22`, filter: 'blur(14px)', pointerEvents: 'none' }} />
                    <div style={{ width: 34, height: 34, borderRadius: 10, marginBottom: 8, background: `${c.color}18`, border: `1px solid ${c.color}35`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, boxShadow: `0 4px 12px ${c.color}20`, flexShrink: 0 }}>♪</div>
                    <p style={{ fontSize: isMobile ? 12 : 13, fontWeight: 600, color: 'var(--text-primary)', margin: '0 0 2px', fontFamily: 'var(--font-display)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.name}</p>
                    <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>{c.count}</p>
                  </GlassCard>
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Song list */}
      <div style={{ paddingBottom: 20 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <AnimatePresence mode="wait">
            <motion.h2
              key={showSearch ? 'search' : 'trending'}
              initial={{ opacity: 0, x: -8 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 8 }}
              transition={{ duration: 0.18 }}
              style={{
                fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700,
                color: 'var(--text-primary)', margin: 0,
                /* prevent long search queries from overflowing */
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                maxWidth: '70%',
              }}
            >
              {showSearch ? `Results for "${search}"` : 'Trending Now'}
            </motion.h2>
          </AnimatePresence>

          <AnimatePresence>
            {(searching || trendingLoad) && (
              <motion.span
                key="loading"
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                style={{ fontSize: 11, color: 'var(--accent-primary)', flexShrink: 0 }}
              >
                {searching ? 'Searching…' : 'Loading…'}
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
              key={showSearch ? `s-${search}` : 'trending'}
              variants={listVariants}
              initial="hidden" animate="show" exit="exit"
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

/* ── Skeleton ─────────────────────────────────────────────── */
function SkeletonList({ count }) {
  return (
    <motion.div
      variants={listVariants} initial="hidden" animate="show"
      style={{ display: 'flex', flexDirection: 'column', gap: 8 }}
    >
      {Array.from({ length: count }).map((_, i) => (
        <motion.div key={i} variants={rowVariants}
          style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', borderRadius: 12, minHeight: 44 }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(255,255,255,0.05)', animation: 'pulse-glow 1.5s ease-in-out infinite', flexShrink: 0 }} />
          <div style={{ flex: 1, minWidth: 0 }}>
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
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
      <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>{title}</h2>
    </div>
  )
}

/* ── Song Row ─────────────────────────────────────────────── */
function SongRow({ song, index, active, isPlaying, isLiked, isMobile, isTablet, onClick, onLike }) {
  const accentCol = song.color || 'rgba(34,211,238,'

  return (
    <motion.div
      onClick={onClick}
      whileHover={{ x: isMobile ? 0 : 3, transition: { duration: 0.14 } }}
      whileTap={{ scale: 0.985 }}
      style={{
        display: 'grid',
        /* mobile: thumb | info | like  (no index, no duration to save space) */
        /* tablet+: index | thumb | info | like | duration */
        gridTemplateColumns: isMobile
          ? 'auto 1fr auto'
          : '28px auto 1fr auto auto',
        gap: isMobile ? 10 : 12,
        /* 44px min ensures comfortable tap target */
        minHeight: 44,
        padding: isMobile ? '8px 6px' : '9px 12px',
        borderRadius: 12,
        cursor: 'pointer',
        alignItems: 'center',
        background: active
          ? `linear-gradient(90deg, ${accentCol}18) 0%, ${accentCol}08) 100%)`
          : 'transparent',
        border: `1px solid ${active ? `${accentCol}28)` : 'transparent'}`,
        boxShadow: active ? `inset 3px 0 0 0 ${accentCol}80)` : 'none',
        transition: 'background 0.22s, border-color 0.22s, box-shadow 0.22s',
        /* prevent row from expanding beyond container */
        minWidth: 0,
        WebkitTapHighlightColor: 'transparent',
        touchAction: 'manipulation',
      }}
      onMouseEnter={e => { if (!active) { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}}
      onMouseLeave={e => { if (!active) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}}
    >
      {/* Index — hidden on mobile */}
      {!isMobile && (
        <span style={{ fontSize: 11, textAlign: 'center', color: active ? 'var(--accent-primary)' : 'var(--text-muted)', fontWeight: active ? 600 : 400 }}>
          {isPlaying ? '▶' : active ? '❚❚' : index + 1}
        </span>
      )}

      {/* Thumbnail */}
      <div style={{
        width: isMobile ? 42 : 40, height: isMobile ? 42 : 40,
        borderRadius: 10, flexShrink: 0, overflow: 'hidden',
        background: `linear-gradient(135deg, ${song.color}28, ${song.color}0d)`,
        border: `1px solid ${song.color}${active ? '55' : '30'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: active ? `0 0 14px ${song.color}40` : 'none',
      }}>
        {song.thumbnail
          ? <img src={song.thumbnail} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={e => { e.target.style.display = 'none' }} />
          : <span style={{ fontSize: 16 }}>♪</span>
        }
      </div>

      {/* Title + artist */}
      <div style={{ minWidth: 0 }}>
        <p style={{
          fontSize: isMobile ? 14 : 13, margin: 0,
          fontWeight: active ? 600 : 400,
          color: active ? 'var(--accent-primary)' : 'var(--text-primary)',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          transition: 'color 0.2s',
        }}>{song.title}</p>
        <p style={{
          fontSize: isMobile ? 12 : 11, margin: 0,
          color: 'var(--text-secondary)',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{song.artist}</p>
      </div>

      {/* Like */}
      <motion.button
        onClick={onLike}
        whileHover={{ scale: 1.22 }} whileTap={{ scale: 0.80 }}
        aria-label={isLiked ? 'Unlike' : 'Like'}
        style={{
          background: 'none', border: 'none', cursor: 'pointer',
          /* 44px tap target */
          width: 44, height: 44,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 16,
          color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)',
          filter: isLiked ? 'drop-shadow(0 0 4px rgba(34,211,238,0.55))' : 'none',
          transition: 'color 0.2s, filter 0.2s',
          WebkitTapHighlightColor: 'transparent',
          touchAction: 'manipulation',
          flexShrink: 0,
        }}
      >
        {isLiked ? '♥' : '♡'}
      </motion.button>

      {/* Duration — hidden on mobile to reclaim space */}
      {!isMobile && (
        <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 32, textAlign: 'right', fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
          {formatTime(song.duration)}
        </span>
      )}
    </motion.div>
  )
}
