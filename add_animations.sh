#!/usr/bin/env bash
set -e

REPO_ROOT="$(pwd)"

if [ ! -f "$REPO_ROOT/vite.config.js" ]; then
  echo "❌  Run from the mysic repo root."
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Mysic — Framer Motion Animation Patch      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Ensure framer-motion is installed ─────────────
echo "─── Checking framer-motion ───"
if ! grep -q '"framer-motion"' "$REPO_ROOT/package.json" 2>/dev/null; then
  echo "  Installing framer-motion..."
  cd "$REPO_ROOT" && npm install framer-motion
else
  echo "  ✅  framer-motion already in package.json"
fi
echo ""

# ══════════════════════════════════════════════════
# 1. PageTransition.jsx — already good, just ensure
#    it uses AnimatePresence-compatible style
# ══════════════════════════════════════════════════
echo "─── 1/7  PageTransition.jsx ───"
cat > "$REPO_ROOT/src/components/PageTransition.jsx" << 'EOF'
import { motion } from 'framer-motion'

export default function PageTransition({ children, pageKey }) {
  return (
    <motion.div
      key={pageKey}
      initial={{ opacity: 0, y: 16, scale: 0.99 }}
      animate={{ opacity: 1, y: 0,  scale: 1    }}
      exit={{    opacity: 0, y: -8, scale: 0.99 }}
      transition={{ duration: 0.28, ease: [0.25, 0.46, 0.45, 0.94] }}
      style={{ height: '100%' }}
    >
      {children}
    </motion.div>
  )
}
EOF
echo "  ✅  done"

# ══════════════════════════════════════════════════
# 2. AnimatedCard.jsx — keep, already good
# ══════════════════════════════════════════════════
echo "─── 2/7  AnimatedCard.jsx ───"
cat > "$REPO_ROOT/src/components/AnimatedCard.jsx" << 'EOF'
import { motion } from 'framer-motion'

export default function AnimatedCard({ children, className = '', style = {}, delay = 0, onClick, ...props }) {
  return (
    <motion.div
      className={className}
      style={style}
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0  }}
      exit={{    opacity: 0, y: -10 }}
      transition={{ duration: 0.32, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      whileHover={{ scale: 1.018, transition: { duration: 0.16 } }}
      whileTap={{  scale: 0.97,  transition: { duration: 0.10 } }}
      onClick={onClick}
      {...props}
    >
      {children}
    </motion.div>
  )
}
EOF
echo "  ✅  done"

# ══════════════════════════════════════════════════
# 3. Layout.jsx — wrap PageRouter in AnimatePresence
#    so page transitions fire on navigation
# ══════════════════════════════════════════════════
echo "─── 3/7  Layout.jsx ───"
cat > "$REPO_ROOT/src/components/Layout.jsx" << 'EOF'
import { useState, useEffect } from 'react'
import { AnimatePresence } from 'framer-motion'
import Sidebar from './Sidebar'
import MainContent from './MainContent'
import NowPlaying from './NowPlaying'
import Player from './Player'
import MobileNav from './MobileNav'
import YouTubePlayer from './YouTubePlayer'
import PageTransition from './PageTransition'
import DiscoverPage from '../pages/DiscoverPage'
import LibraryPage from '../pages/LibraryPage'
import LikedPage from '../pages/LikedPage'
import PlaylistsPage from '../pages/PlaylistsPage'

function PageRouter({ page, screenSize }) {
  switch (page) {
    case 'Discover':  return <DiscoverPage />
    case 'Library':   return <LibraryPage />
    case 'Liked':     return <LikedPage />
    case 'Playlists': return <PlaylistsPage />
    default:          return <MainContent screenSize={screenSize} />
  }
}

export default function Layout() {
  const [screen,         setScreen]         = useState('desktop')
  const [nowPlayingOpen, setNowPlayingOpen] = useState(false)
  const [activePage,     setActivePage]     = useState('Home')

  useEffect(() => {
    const upd = () => {
      const w = window.innerWidth
      setScreen(w < 640 ? 'mobile' : w < 1024 ? 'tablet' : 'desktop')
    }
    upd()
    window.addEventListener('resize', upd)
    return () => window.removeEventListener('resize', upd)
  }, [])

  const isMobile  = screen === 'mobile'
  const isTablet  = screen === 'tablet'
  const isDesktop = screen === 'desktop'

  return (
    <div style={{ height: '100dvh', width: '100vw', overflow: 'hidden', background: 'var(--bg-base)', position: 'relative', display: 'flex', flexDirection: 'column', fontFamily: 'var(--font-body)' }}>
      <YouTubePlayer />

      {/* Ambient orbs */}
      <div style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 0, overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: '-15%', left: '-8%', width: isMobile?280:520, height: isMobile?280:520, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-1) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift1 20s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', top: '40%', right: '-12%', width: isMobile?220:420, height: isMobile?220:420, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-2) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift2 25s ease-in-out infinite alternate' }} />
        <div style={{ position: 'absolute', bottom: '-8%', left: '38%', width: isMobile?180:360, height: isMobile?180:360, borderRadius: '50%', background: 'radial-gradient(circle, var(--orb-3) 0%, transparent 70%)', filter: 'blur(50px)', animation: 'drift3 28s ease-in-out infinite alternate' }} />
      </div>

      {/* Desktop */}
      {isDesktop && (
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'var(--sidebar-width) 1fr var(--right-panel-width)', gridTemplateRows: '1fr var(--player-height)', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ gridColumn: 1, gridRow: 1, overflow: 'hidden' }}><Sidebar activePage={activePage} onNavigate={setActivePage} /></div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden', position: 'relative' }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <div style={{ gridColumn: 3, gridRow: 1, overflow: 'hidden' }}><NowPlaying /></div>
          <div style={{ gridColumn: '1/-1', gridRow: 2 }}><Player /></div>
        </div>
      )}

      {/* Tablet */}
      {isTablet && (
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '68px 1fr', gridTemplateRows: '1fr var(--player-height)', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ gridColumn: 1, gridRow: 1 }}><Sidebar collapsed activePage={activePage} onNavigate={setActivePage} /></div>
          <div style={{ gridColumn: 2, gridRow: 1, overflow: 'hidden', position: 'relative' }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <div style={{ gridColumn: '1/-1', gridRow: 2 }}><Player onNowPlayingClick={() => setNowPlayingOpen(true)} /></div>
          {nowPlayingOpen && <>
            <div onClick={() => setNowPlayingOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 40, animation: 'fadeIn 0.2s ease' }} />
            <div style={{ position: 'fixed', top: 0, right: 0, width: 300, height: '100dvh', zIndex: 50, animation: 'slideInRight 0.3s ease' }}><NowPlaying onClose={() => setNowPlayingOpen(false)} /></div>
          </>}
        </div>
      )}

      {/* Mobile */}
      {isMobile && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative', zIndex: 1 }}>
          <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
            <AnimatePresence mode="wait">
              <PageTransition pageKey={activePage}>
                <PageRouter page={activePage} screenSize={screen} />
              </PageTransition>
            </AnimatePresence>
          </div>
          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} />
          <MobileNav activePage={activePage} onNavigate={setActivePage} />
          {nowPlayingOpen && <>
            <div onClick={() => setNowPlayingOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', zIndex: 40, animation: 'fadeIn 0.2s ease' }} />
            <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, height: '90dvh', borderRadius: '22px 22px 0 0', zIndex: 50, animation: 'slideInUp 0.3s ease', overflow: 'hidden' }}><NowPlaying onClose={() => setNowPlayingOpen(false)} /></div>
          </>}
        </div>
      )}
    </div>
  )
}
EOF
echo "  ✅  done"

# ══════════════════════════════════════════════════
# 4. MainContent.jsx — animate header, collection
#    cards, and song rows staggered on load/search
# ══════════════════════════════════════════════════
echo "─── 4/7  MainContent.jsx ───"
cat > "$REPO_ROOT/src/components/MainContent.jsx" << 'EOF'
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
EOF
echo "  ✅  done"

# ══════════════════════════════════════════════════
# 5. SongList.jsx — staggered rows + like animation
# ══════════════════════════════════════════════════
echo "─── 5/7  SongList.jsx ───"
cat > "$REPO_ROOT/src/components/SongList.jsx" << 'EOF'
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
EOF
echo "  ✅  done"

# ══════════════════════════════════════════════════
# 6. NowPlaying.jsx — animate album art + track
#    change, and control buttons
# ══════════════════════════════════════════════════
echo "─── 6/7  NowPlaying.jsx ───"
cat > "$REPO_ROOT/src/components/NowPlaying.jsx" << 'EOF'
import { useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]

function Scrubber({ pct, onSeek }) {
  const dragging = useRef(false)
  const calc = (e, el) => {
    const rect = el.getBoundingClientRect()
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left
    return Math.max(0, Math.min(100, (x / rect.width) * 100))
  }
  const onMouseDown = useCallback(e => {
    dragging.current = true
    onSeek(calc(e, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev, el)) }
    const onUp   = ()  => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }, [onSeek])
  return (
    <div onMouseDown={onMouseDown} style={{ flex: 1, height: 4, borderRadius: 4, background: 'rgba(255,255,255,0.08)', cursor: 'pointer', position: 'relative' }}>
      <div style={{ width: `${pct}%`, height: '100%', borderRadius: 4, background: 'var(--accent-grad)', position: 'relative', transition: 'width 0.9s linear' }}>
        <div style={{ position: 'absolute', right: -5, top: '50%', transform: 'translateY(-50%)', width: 12, height: 12, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.25)' }} />
      </div>
    </div>
  )
}

function Btn({ children, onClick, size = 36, primary = false, title }) {
  return (
    <motion.button
      title={title} onClick={onClick}
      whileHover={{ scale: primary ? 1.08 : 1.12 }}
      whileTap={{ scale: primary ? 0.94 : 0.88 }}
      style={{ width: size, height: size, borderRadius: '50%', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)', border: primary ? 'none' : '1px solid rgba(255,255,255,0.08)', color: primary ? '#08121f' : 'var(--text-secondary)', fontSize: primary ? 19 : 14, cursor: 'pointer', boxShadow: primary ? '0 6px 20px rgba(34,211,238,0.38)' : 'none' }}
    >{children}</motion.button>
  )
}

export default function NowPlaying({ onClose }) {
  const { currentSong, isPlaying, progress, volume, togglePlay, playNext, playPrev, seek, setVolume, toggleLike, liked, queue } = usePlayer()
  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)

  const upNext = (() => {
    const idx = queue.findIndex(s => s.id === currentSong.id)
    return [1, 2, 3].map(o => queue[(idx + o) % queue.length])
  })()

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', padding: '22px 18px', background: 'rgba(8,12,20,0.74)', backdropFilter: 'blur(30px)', WebkitBackdropFilter: 'blur(30px)', borderLeft: '1px solid rgba(255,255,255,0.06)', fontFamily: 'var(--font-body)', overflowY: 'auto' }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 22 }}>
        <p style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.12em', textTransform: 'uppercase', margin: 0 }}>Now Playing</p>
        {onClose && (
          <motion.button onClick={onClose} whileHover={{ scale: 1.2, rotate: 90 }} whileTap={{ scale: 0.9 }} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 16, cursor: 'pointer' }}>&#10005;</motion.button>
        )}
      </div>

      {/* Album Art — cross-fades on track change */}
      <AnimatePresence mode="wait">
        <motion.div
          key={currentSong.id}
          initial={{ opacity: 0, scale: 0.9, y: 12 }}
          animate={{ opacity: 1, scale: 1,   y: 0  }}
          exit={{    opacity: 0, scale: 0.9, y: -12 }}
          transition={{ duration: 0.35, ease: EASE }}
          style={{ marginBottom: 22, borderRadius: 18, overflow: 'hidden', boxShadow: `0 20px 60px ${currentSong.color || '#8b5cf6'}30`, transition: 'box-shadow 0.5s' }}
        >
          <AlbumArt song={currentSong} size="xl" isPlaying={isPlaying} />
        </motion.div>
      </AnimatePresence>

      {/* Track info — slides in on track change */}
      <AnimatePresence mode="wait">
        <motion.div
          key={`info-${currentSong.id}`}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0  }}
          exit={{    opacity: 0, x: -20 }}
          transition={{ duration: 0.25, ease: EASE }}
          style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 18 }}
        >
          <div style={{ minWidth: 0, flex: 1 }}>
            <h3 style={{ fontFamily: 'var(--font-display)', fontSize: 17, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 4px', lineHeight: 1.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.title}</h3>
            <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
          </div>
          <motion.button
            onClick={() => toggleLike(currentSong.id, currentSong)}
            whileHover={{ scale: 1.2 }} whileTap={{ scale: 0.75 }}
            style={{ background: 'none', border: 'none', fontSize: 18, cursor: 'pointer', marginLeft: 8, flexShrink: 0, color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none', transition: 'color 0.2s, filter 0.2s' }}
          >{isLiked ? '\u2665' : '\u2661'}</motion.button>
        </motion.div>
      </AnimatePresence>

      {/* Progress */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', alignItems: 'center' }}><Scrubber pct={progress} onSeek={seek} /></div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 7 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSec)}</span>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSong.duration)}</span>
        </div>
      </div>

      {/* Controls */}
      <motion.div
        initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3, delay: 0.1 }}
        style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, marginBottom: 20 }}
      >
        <Btn title="Shuffle">&#8700;</Btn>
        <Btn title="Previous" onClick={playPrev}>&#9198;</Btn>
        <Btn primary size={52} title={isPlaying ? 'Pause' : 'Play'} onClick={togglePlay}>{isPlaying ? '\u23F8' : '\u25B6'}</Btn>
        <Btn title="Next" onClick={playNext}>&#9197;</Btn>
        <Btn title="Repeat">&#8635;</Btn>
      </motion.div>

      {/* Volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 24 }}>
        <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>{volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}</span>
        <Scrubber pct={volume} onSeek={setVolume} />
        <span style={{ fontSize: 11, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums' }}>{Math.round(volume)}%</span>
      </div>

      {/* Up Next */}
      <div style={{ borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: 18, flex: 1 }}>
        <p style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.12em', color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 12 }}>Up Next</p>
        <AnimatePresence>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {upNext.map((song, i) => (
              <motion.div
                key={`${song.id}-${i}`}
                initial={{ opacity: 0, x: 12 }}
                animate={{ opacity: 1, x: 0  }}
                transition={{ duration: 0.22, delay: i * 0.06, ease: EASE }}
                whileHover={{ x: 4, transition: { duration: 0.15 } }}
                style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px', borderRadius: 10, cursor: 'pointer', border: '1px solid transparent', transition: 'background 0.2s, border-color 0.2s' }}
                onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)' }}
                onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'transparent' }}
              >
                <AlbumArt song={song} size="xs" />
                <div style={{ minWidth: 0, flex: 1 }}>
                  <p style={{ fontSize: 12, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{song.title}</p>
                  <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>{song.artist}</p>
                </div>
                <span style={{ fontSize: 10, color: 'var(--text-muted)', flexShrink: 0 }}>{formatTime(song.duration)}</span>
              </motion.div>
            ))}
          </div>
        </AnimatePresence>
      </div>
    </div>
  )
}
EOF
echo "  ✅  done"

# ══════════════════════════════════════════════════
# 7. Player.jsx — animate play/pause button + like
# ══════════════════════════════════════════════════
echo "─── 7/7  Player.jsx ───"
cat > "$REPO_ROOT/src/components/Player.jsx" << 'EOF'
import { useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import { formatTime } from '../data/songs'
import AlbumArt from './AlbumArt'

const EASE = [0.25, 0.46, 0.45, 0.94]

function useScrubber(onSeek) {
  const dragging = useRef(false)
  const calc = (e, el) => {
    const rect = el.getBoundingClientRect()
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left
    return Math.max(0, Math.min(100, (x / rect.width) * 100))
  }
  const onMouseDown = useCallback(e => {
    dragging.current = true
    onSeek(calc(e, e.currentTarget))
    const el = e.currentTarget
    const onMove = ev => { if (dragging.current) onSeek(calc(ev, el)) }
    const onUp   = ()  => { dragging.current = false; window.removeEventListener('mousemove', onMove) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp, { once: true })
  }, [onSeek])
  return { onMouseDown }
}

function Scrubber({ pct, onSeek, width = '100%', accent = 'var(--accent-grad)' }) {
  const { onMouseDown } = useScrubber(onSeek)
  return (
    <div onMouseDown={onMouseDown} style={{ width, height: 4, borderRadius: 4, background: 'rgba(255,255,255,0.08)', cursor: 'pointer', position: 'relative', flexShrink: 0 }}>
      <div style={{ width: `${pct}%`, height: '100%', borderRadius: 4, background: accent, position: 'relative', transition: 'width 0.9s linear' }}>
        <div style={{ position: 'absolute', right: -5, top: '50%', transform: 'translateY(-50%)', width: 12, height: 12, borderRadius: '50%', background: 'white', boxShadow: '0 0 8px rgba(34,211,238,0.85), 0 0 0 2px rgba(34,211,238,0.25)' }} />
      </div>
    </div>
  )
}

function Btn({ children, onClick, size = 32, primary = false, title }) {
  return (
    <motion.button
      title={title} onClick={onClick}
      whileHover={{ scale: primary ? 1.08 : 1.15 }}
      whileTap={{ scale: primary ? 0.93 : 0.85 }}
      style={{ width: size, height: size, borderRadius: '50%', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: primary ? 'var(--accent-grad)' : 'rgba(255,255,255,0.05)', border: primary ? 'none' : '1px solid rgba(255,255,255,0.09)', color: primary ? '#08121f' : 'var(--text-secondary)', fontSize: primary ? 15 : 13, cursor: 'pointer', boxShadow: primary ? '0 4px 16px rgba(34,211,238,0.38)' : 'none' }}
    >{children}</motion.button>
  )
}

function MobilePlayer({ onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, togglePlay, playNext } = usePlayer()
  return (
    <div style={{ fontFamily: 'var(--font-body)', background: 'rgba(8,12,20,0.95)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
      <div style={{ height: 2, background: 'rgba(255,255,255,0.06)' }}>
        <motion.div
          style={{ height: '100%', background: 'var(--accent-grad)' }}
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.9, ease: 'linear' }}
        />
      </div>
      <div onClick={onNowPlayingClick} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px', cursor: 'pointer' }}>
        {/* Album art cross-fades on track change */}
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id} initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.25, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>
        {/* Track info cross-fades */}
        <AnimatePresence mode="wait">
          <motion.div key={`title-${currentSong.id}`} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }} transition={{ duration: 0.2 }} style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentSong.title}</p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>
        <Btn primary size={34} onClick={e => { e.stopPropagation(); togglePlay() }} title={isPlaying ? 'Pause' : 'Play'}>{isPlaying ? '\u23F8' : '\u25B6'}</Btn>
        <Btn size={30} onClick={e => { e.stopPropagation(); playNext() }} title="Next">&#9197;</Btn>
      </div>
    </div>
  )
}

export default function Player({ mobile = false, onNowPlayingClick }) {
  const { currentSong, isPlaying, progress, volume, togglePlay, playNext, playPrev, seek, setVolume, toggleLike, liked } = usePlayer()
  const isLiked    = liked.has(currentSong.id)
  const currentSec = Math.floor((progress / 100) * currentSong.duration)

  if (mobile) return <MobilePlayer onNowPlayingClick={onNowPlayingClick} />

  return (
    <div style={{ height: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', alignItems: 'center', padding: '0 22px', background: 'rgba(8,12,20,0.92)', backdropFilter: 'blur(30px)', borderTop: '1px solid rgba(255,255,255,0.06)', fontFamily: 'var(--font-body)' }}>

      {/* Left: track info — cross-fades on song change */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <AnimatePresence mode="wait">
          <motion.div key={currentSong.id} initial={{ opacity: 0, scale: 0.85 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.85 }} transition={{ duration: 0.25, ease: EASE }}>
            <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
          </motion.div>
        </AnimatePresence>
        <AnimatePresence mode="wait">
          <motion.div key={`title-${currentSong.id}`} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }} transition={{ duration: 0.2, ease: EASE }} style={{ minWidth: 0 }}>
            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 140 }}>{currentSong.title}</p>
            <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0 }}>{currentSong.artist}</p>
          </motion.div>
        </AnimatePresence>
        <motion.button
          onClick={() => toggleLike(currentSong.id, currentSong)}
          whileHover={{ scale: 1.25 }} whileTap={{ scale: 0.75 }}
          style={{ background: 'none', border: 'none', flexShrink: 0, fontSize: 16, cursor: 'pointer', color: isLiked ? 'var(--accent-primary)' : 'var(--text-muted)', filter: isLiked ? 'drop-shadow(0 0 6px rgba(34,211,238,0.6))' : 'none', transition: 'color 0.2s, filter 0.2s' }}
        >{isLiked ? '\u2665' : '\u2661'}</motion.button>
      </div>

      {/* Centre: controls + scrubber */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <Btn title="Shuffle">&#8700;</Btn>
          <Btn title="Previous" onClick={playPrev}>&#9198;</Btn>
          <Btn primary size={38} title={isPlaying ? 'Pause' : 'Play'} onClick={togglePlay}>
            <AnimatePresence mode="wait">
              <motion.span key={isPlaying ? 'pause' : 'play'} initial={{ scale: 0, rotate: -30 }} animate={{ scale: 1, rotate: 0 }} exit={{ scale: 0, rotate: 30 }} transition={{ duration: 0.15 }}>
                {isPlaying ? '\u23F8' : '\u25B6'}
              </motion.span>
            </AnimatePresence>
          </Btn>
          <Btn title="Next" onClick={playNext}>&#9197;</Btn>
          <Btn title="Repeat">&#8635;</Btn>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', maxWidth: 340 }}>
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSec)}</span>
          <Scrubber pct={progress} onSeek={seek} />
          <span style={{ fontSize: 10, color: 'var(--text-muted)', minWidth: 28, fontVariantNumeric: 'tabular-nums' }}>{formatTime(currentSong.duration)}</span>
        </div>
      </div>

      {/* Right: volume */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, justifyContent: 'flex-end' }}>
        {['\u2630', '\u229E'].map(icon => (
          <motion.button key={icon} whileHover={{ scale: 1.15 }} whileTap={{ scale: 0.9 }} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 14, cursor: 'pointer', transition: 'color 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
          >{icon}</motion.button>
        ))}
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{volume === 0 ? '\uD83D\uDD07' : volume < 40 ? '\uD83D\uDD08' : '\uD83D\uDD0A'}</span>
          <Scrubber pct={volume} onSeek={setVolume} width="80px" accent="linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))" />
        </div>
      </div>
    </div>
  )
}
EOF
echo "  ✅  done"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅  All animation patches applied!          ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  What's now animated:                        ║"
echo "║  • Page transitions (fade+slide between nav) ║"
echo "║  • Song rows stagger in on load/search       ║"
echo "║  • Collection cards stagger in               ║"
echo "║  • Album art cross-fades on track change     ║"
echo "║  • Track title slides in on track change     ║"
echo "║  • Play/pause icon morphs with rotate anim   ║"
echo "║  • Like button bounces on tap                ║"
echo "║  • All control buttons have spring press     ║"
echo "║  • Close button rotates 90° on hover         ║"
echo "║  • Up Next rows stagger in                   ║"
echo "║  • Header/search bar fade in on mount        ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Run:  npm run dev                           ║"
echo "╚══════════════════════════════════════════════╝"
