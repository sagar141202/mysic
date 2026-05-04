#!/usr/bin/env bash
# fix-playlists-dynamic.sh
# ─────────────────────────────────────────────────────────────────────────────
# Replaces the static PlaylistsPage with a fully dynamic version that fetches
# real songs from YouTube via the same ytSearch proxy used by search/discover.
#
# What this does:
#   1. Backs up the existing PlaylistsPage (if any)
#   2. Writes the new dynamic PlaylistsPage.jsx
#   3. Verifies ytSearch exports searchYouTube (adds alias if missing)
#
# Usage:
#   chmod +x fix-playlists-dynamic.sh
#   ./fix-playlists-dynamic.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

PAGES_DIR="src/pages"
TARGET="$PAGES_DIR/PlaylistsPage.jsx"
YT_SEARCH="src/utils/ytSearch.js"

echo "🎵  Mysic — Dynamic Playlists Fix"
echo "───────────────────────────────────────"

# ── 0. Ensure we're in the project root ──────────────────────────────────────
if [ ! -f "package.json" ]; then
  echo "❌  Run this script from the Mysic project root (where package.json lives)."
  exit 1
fi

# ── 1. Backup existing PlaylistsPage ─────────────────────────────────────────
if [ -f "$TARGET" ]; then
  cp "$TARGET" "${TARGET}.bak"
  echo "✅  Backed up existing PlaylistsPage → ${TARGET}.bak"
fi

mkdir -p "$PAGES_DIR"

# ── 2. Write new PlaylistsPage.jsx ───────────────────────────────────────────
cat > "$TARGET" << 'PLAYLIST_EOF'
/**
 * PlaylistsPage.jsx — Dynamic playlists powered by live YouTube search.
 *
 * Each playlist has a curated search query that fetches real tracks
 * from YouTube via the same ytSearch proxy used everywhere else in Mysic.
 * Songs are lazy-loaded when the user opens a playlist.
 *
 * State is persisted to localStorage so songs survive page refreshes.
 */
import { useState, useEffect, useCallback, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayer } from '../hooks/usePlayer.jsx'
import SongList from '../components/SongList'
import GlassCard from '../components/GlassCard'
import { searchYouTube } from '../utils/ytSearch'

const EASE = [0.25, 0.46, 0.45, 0.94]

/* ── Playlist definitions — each maps to a live YT search query ── */
const PLAYLISTS = [
  {
    id: 'late-night-drive',
    name: 'Late Night Drive',
    description: 'Dark, moody beats for the road',
    icon: '🌙',
    color: '#6366f1',
    gradient: 'linear-gradient(135deg, #1a1040 0%, #0f0a28 100%)',
    query: 'lofi late night drive chill music 2024',
    count: 12,
  },
  {
    id: 'workout-beast',
    name: 'Workout Beast',
    description: 'High energy tracks to crush your session',
    icon: '⚡',
    color: '#f59e0b',
    gradient: 'linear-gradient(135deg, #2d1a00 0%, #1a0f00 100%)',
    query: 'workout motivation high energy gym music 2024',
    count: 12,
  },
  {
    id: 'chill-sunday',
    name: 'Chill Sunday',
    description: 'Slow mornings, warm coffee, good vibes',
    icon: '☀️',
    color: '#10b981',
    gradient: 'linear-gradient(135deg, #001a10 0%, #00100a 100%)',
    query: 'sunday morning chill acoustic indie music 2024',
    count: 12,
  },
  {
    id: 'bollywood-fire',
    name: 'Bollywood Fire',
    description: 'Desi bangers — old and new',
    icon: '🎆',
    color: '#ef4444',
    gradient: 'linear-gradient(135deg, #2d0000 0%, #1a0000 100%)',
    query: 'bollywood hits 2024 top songs trending',
    count: 12,
  },
  {
    id: 'deep-focus',
    name: 'Deep Focus',
    description: 'Flow state, zero distractions',
    icon: '🎯',
    color: '#22d3ee',
    gradient: 'linear-gradient(135deg, #00141a 0%, #000d12 100%)',
    query: 'deep focus study music ambient concentration 2024',
    count: 12,
  },
  {
    id: 'hip-hop-essentials',
    name: 'Hip Hop Essentials',
    description: 'The classics and the new wave',
    icon: '🎤',
    color: '#a855f7',
    gradient: 'linear-gradient(135deg, #1a0028 0%, #0f0019 100%)',
    query: 'hip hop essentials rap hits 2024',
    count: 12,
  },
  {
    id: 'indie-vibes',
    name: 'Indie Vibes',
    description: "Underground gems you haven't heard yet",
    icon: '🎸',
    color: '#f97316',
    gradient: 'linear-gradient(135deg, #1a0e00 0%, #100800 100%)',
    query: 'indie alternative underground music 2024',
    count: 12,
  },
  {
    id: 'jazz-and-soul',
    name: 'Jazz & Soul',
    description: 'Timeless grooves that move you',
    icon: '🎷',
    color: '#eab308',
    gradient: 'linear-gradient(135deg, #1a1600 0%, #100e00 100%)',
    query: 'jazz soul classics smooth music 2024',
    count: 10,
  },
]

const CACHE_KEY = 'mysic:playlist-cache'

function loadCache() {
  try {
    return JSON.parse(localStorage.getItem(CACHE_KEY) || '{}')
  } catch { return {} }
}

function saveCache(cache) {
  try { localStorage.setItem(CACHE_KEY, JSON.stringify(cache)) } catch {}
}

/* ── Playlist Card ────────────────────────────────────────── */
function PlaylistCard({ playlist, onClick, isActive }) {
  return (
    <motion.div
      onClick={onClick}
      whileHover={{ y: -6, scale: 1.02 }}
      whileTap={{ scale: 0.97 }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.30, ease: EASE }}
      style={{
        cursor: 'pointer',
        borderRadius: 18,
        overflow: 'hidden',
        background: playlist.gradient,
        border: `1px solid ${isActive ? playlist.color + '55' : 'rgba(255,255,255,0.07)'}`,
        boxShadow: isActive
          ? `0 0 0 2px ${playlist.color}40, 0 16px 40px ${playlist.color}20`
          : '0 4px 20px rgba(0,0,0,0.30)',
        transition: 'border-color 0.25s, box-shadow 0.25s',
        position: 'relative',
      }}
    >
      {/* Ambient glow orb */}
      <div style={{
        position: 'absolute', top: -20, right: -20,
        width: 100, height: 100, borderRadius: '50%',
        background: `radial-gradient(circle, ${playlist.color}30 0%, transparent 70%)`,
        pointerEvents: 'none',
      }} />

      <div style={{ padding: '20px 18px 18px' }}>
        <div style={{
          width: 48, height: 48, borderRadius: 14, marginBottom: 14,
          background: `${playlist.color}22`,
          border: `1px solid ${playlist.color}40`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 22,
          boxShadow: `0 4px 16px ${playlist.color}25`,
        }}>
          {playlist.icon}
        </div>

        <p style={{
          fontSize: 15, fontWeight: 700, color: 'var(--text-primary)',
          margin: '0 0 4px', fontFamily: 'var(--font-display)',
          letterSpacing: '-0.2px',
        }}>
          {playlist.name}
        </p>
        <p style={{
          fontSize: 11, color: 'rgba(255,255,255,0.45)',
          margin: '0 0 14px', lineHeight: 1.4,
        }}>
          {playlist.description}
        </p>

        <div style={{
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <div style={{
            width: 6, height: 6, borderRadius: '50%',
            background: playlist.color,
            boxShadow: `0 0 6px ${playlist.color}`,
          }} />
          <span style={{ fontSize: 11, color: playlist.color, fontWeight: 500 }}>
            ~{playlist.count} songs
          </span>
        </div>
      </div>

      {/* Active indicator */}
      {isActive && (
        <motion.div
          layoutId="active-playlist"
          style={{
            position: 'absolute', bottom: 0, left: 0, right: 0, height: 3,
            background: `linear-gradient(90deg, ${playlist.color}, ${playlist.color}55)`,
          }}
        />
      )}
    </motion.div>
  )
}

/* ── Skeleton loader ─────────────────────────────────────── */
function LoadingRows() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      {Array.from({ length: 6 }).map((_, i) => (
        <motion.div
          key={i}
          initial={{ opacity: 0 }}
          animate={{ opacity: [0.3, 0.6, 0.3] }}
          transition={{ duration: 1.4, delay: i * 0.08, repeat: Infinity }}
          style={{
            height: 56, borderRadius: 12,
            background: 'rgba(255,255,255,0.04)',
          }}
        />
      ))}
    </div>
  )
}

/* ── Main Page ────────────────────────────────────────────── */
export default function PlaylistsPage({ screenSize }) {
  const { playSong } = usePlayer()
  const [selected, setSelected] = useState(null)
  const [songsMap, setSongsMap]  = useState({})
  const [loading, setLoading]    = useState(false)
  const [error, setError]        = useState(null)
  const [refreshing, setRefreshing] = useState(false)
  const cacheRef = useRef(loadCache())

  const isMobile = screenSize === 'mobile'

  const fetchPlaylist = useCallback(async (playlist, force = false) => {
    const cached = cacheRef.current[playlist.id]
    if (!force && cached && Date.now() - cached.ts < 30 * 60 * 1000) {
      setSongsMap(prev => ({ ...prev, [playlist.id]: cached.songs }))
      return
    }

    setLoading(true)
    setError(null)
    try {
      const songs = await searchYouTube(playlist.query)
      const sliced = songs.slice(0, playlist.count)
      cacheRef.current[playlist.id] = { songs: sliced, ts: Date.now() }
      saveCache(cacheRef.current)
      setSongsMap(prev => ({ ...prev, [playlist.id]: sliced }))
    } catch (e) {
      setError('Failed to load songs. Check your connection and try again.')
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => {
    if (!selected) return
    fetchPlaylist(selected)
  }, [selected, fetchPlaylist])

  const handleRefresh = () => {
    if (!selected || loading) return
    setRefreshing(true)
    fetchPlaylist(selected, true)
  }

  const selectedSongs = selected ? (songsMap[selected.id] || []) : []

  return (
    <div style={{
      height: '100%',
      display: 'flex',
      flexDirection: isMobile ? 'column' : 'row',
      overflow: 'hidden',
      fontFamily: 'var(--font-body)',
    }}>

      {/* ── Left: Playlist Grid ── */}
      <div style={{
        width: isMobile ? '100%' : selected ? 320 : '100%',
        flexShrink: 0,
        overflowY: 'auto',
        overflowX: 'hidden',
        padding: isMobile ? '18px 16px' : '28px 22px',
        borderRight: !isMobile && selected ? '1px solid rgba(255,255,255,0.06)' : 'none',
        transition: 'width 0.35s cubic-bezier(0.25,0.46,0.45,0.94)',
        scrollbarWidth: 'none',
        height: isMobile && selected ? '50%' : '100%',
      }}>
        <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} style={{ marginBottom: 22 }}>
          <h2 style={{
            fontFamily: 'var(--font-display)',
            fontSize: isMobile ? 20 : 24,
            fontWeight: 800, color: 'var(--text-primary)',
            margin: '0 0 4px', letterSpacing: '-0.5px',
          }}>
            Your Playlists
          </h2>
          <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0 }}>
            {PLAYLISTS.length} curated collections · powered by YouTube
          </p>
        </motion.div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: selected && !isMobile
            ? '1fr'
            : isMobile
              ? 'repeat(2, 1fr)'
              : 'repeat(auto-fill, minmax(200px, 1fr))',
          gap: selected && !isMobile ? 10 : 14,
        }}>
          {PLAYLISTS.map((pl, i) => (
            <motion.div
              key={pl.id}
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.04, duration: 0.28, ease: EASE }}
            >
              {selected && !isMobile ? (
                <motion.div
                  onClick={() => setSelected(pl)}
                  whileHover={{ x: 3 }}
                  whileTap={{ scale: 0.98 }}
                  style={{
                    display: 'flex', alignItems: 'center', gap: 12,
                    padding: '10px 12px', borderRadius: 12, cursor: 'pointer',
                    background: selected?.id === pl.id ? `${pl.color}14` : 'transparent',
                    border: `1px solid ${selected?.id === pl.id ? pl.color + '30' : 'transparent'}`,
                    transition: 'all 0.2s',
                  }}
                >
                  <div style={{
                    width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                    background: `${pl.color}18`,
                    border: `1px solid ${pl.color}30`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 16,
                  }}>
                    {pl.icon}
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <p style={{
                      fontSize: 13, fontWeight: selected?.id === pl.id ? 600 : 400,
                      color: selected?.id === pl.id ? pl.color : 'var(--text-primary)',
                      margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                    }}>
                      {pl.name}
                    </p>
                    <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0 }}>
                      ~{pl.count} songs
                    </p>
                  </div>
                </motion.div>
              ) : (
                <PlaylistCard
                  playlist={pl}
                  isActive={selected?.id === pl.id}
                  onClick={() => setSelected(selected?.id === pl.id ? null : pl)}
                />
              )}
            </motion.div>
          ))}
        </div>
      </div>

      {/* ── Right: Song List Panel ── */}
      <AnimatePresence mode="wait">
        {selected && (
          <motion.div
            key={selected.id}
            initial={{ opacity: 0, x: isMobile ? 0 : 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: isMobile ? 0 : 40 }}
            transition={{ duration: 0.30, ease: EASE }}
            style={{
              flex: 1,
              overflowY: 'auto',
              overflowX: 'hidden',
              scrollbarWidth: 'none',
              padding: isMobile ? '14px 16px 80px' : '28px 22px',
              display: 'flex',
              flexDirection: 'column',
              minWidth: 0,
            }}
          >
            {/* Playlist header */}
            <div style={{
              display: 'flex', alignItems: 'flex-start',
              justifyContent: 'space-between', marginBottom: 20, flexShrink: 0,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{
                  width: 52, height: 52, borderRadius: 14, flexShrink: 0,
                  background: selected.gradient,
                  border: `1px solid ${selected.color}40`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 24,
                  boxShadow: `0 6px 20px ${selected.color}25`,
                }}>
                  {selected.icon}
                </div>
                <div>
                  <h3 style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: 800, color: 'var(--text-primary)',
                    margin: '0 0 3px', letterSpacing: '-0.3px',
                  }}>
                    {selected.name}
                  </h3>
                  <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0 }}>
                    {selectedSongs.length > 0
                      ? `${selectedSongs.length} songs · live from YouTube`
                      : selected.description}
                  </p>
                </div>
              </div>

              <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexShrink: 0 }}>
                <motion.button
                  onClick={handleRefresh}
                  disabled={loading}
                  whileHover={{ scale: 1.08 }}
                  whileTap={{ scale: 0.92 }}
                  title="Refresh songs"
                  style={{
                    width: 36, height: 36, borderRadius: '50%',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.09)',
                    color: 'var(--text-muted)', fontSize: 14,
                    cursor: loading ? 'not-allowed' : 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    opacity: loading ? 0.5 : 1,
                  }}
                >
                  ↻
                </motion.button>

                {selectedSongs.length > 0 && (
                  <motion.button
                    onClick={() => playSong(selectedSongs[0], selectedSongs)}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    style={{
                      height: 36, padding: '0 16px', borderRadius: 20,
                      background: `linear-gradient(135deg, ${selected.color}, ${selected.color}aa)`,
                      border: 'none', color: '#08121f', fontSize: 12,
                      fontWeight: 700, cursor: 'pointer',
                      fontFamily: 'var(--font-body)',
                      boxShadow: `0 4px 16px ${selected.color}40`,
                      display: 'flex', alignItems: 'center', gap: 6,
                    }}
                  >
                    ▶ Play All
                  </motion.button>
                )}

                {isMobile && (
                  <motion.button
                    onClick={() => setSelected(null)}
                    whileTap={{ scale: 0.88 }}
                    style={{
                      width: 36, height: 36, borderRadius: '50%',
                      background: 'rgba(255,255,255,0.05)',
                      border: '1px solid rgba(255,255,255,0.09)',
                      color: 'var(--text-muted)', fontSize: 14,
                      cursor: 'pointer',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}
                  >
                    ✕
                  </motion.button>
                )}
              </div>
            </div>

            {/* Live badge */}
            <motion.div
              initial={{ opacity: 0 }} animate={{ opacity: 1 }}
              style={{
                display: 'inline-flex', alignItems: 'center', gap: 6,
                padding: '5px 12px', borderRadius: 20, marginBottom: 16, alignSelf: 'flex-start',
                background: `${selected.color}12`,
                border: `1px solid ${selected.color}25`,
              }}
            >
              <motion.div
                animate={{ opacity: [1, 0.3, 1] }}
                transition={{ duration: 1.8, repeat: Infinity }}
                style={{
                  width: 6, height: 6, borderRadius: '50%',
                  background: selected.color,
                  boxShadow: `0 0 6px ${selected.color}`,
                }}
              />
              <span style={{ fontSize: 10, color: selected.color, fontWeight: 600, letterSpacing: '0.08em' }}>
                LIVE FROM YOUTUBE
              </span>
            </motion.div>

            {error && !loading && (
              <motion.div
                initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}
                style={{
                  padding: '20px', borderRadius: 14, textAlign: 'center',
                  background: 'rgba(239,68,68,0.07)',
                  border: '1px solid rgba(239,68,68,0.18)',
                  marginBottom: 16,
                }}
              >
                <p style={{ fontSize: 13, color: '#f87171', margin: '0 0 10px' }}>{error}</p>
                <button
                  onClick={handleRefresh}
                  style={{
                    padding: '7px 18px', borderRadius: 20,
                    background: 'rgba(239,68,68,0.15)',
                    border: '1px solid rgba(239,68,68,0.30)',
                    color: '#f87171', fontSize: 12, cursor: 'pointer',
                    fontFamily: 'var(--font-body)',
                  }}
                >
                  Try Again
                </button>
              </motion.div>
            )}

            {loading && selectedSongs.length === 0 ? (
              <LoadingRows />
            ) : (
              <SongList songs={selectedSongs} showIndex />
            )}

            {refreshing && selectedSongs.length > 0 && (
              <motion.div
                initial={{ opacity: 0 }} animate={{ opacity: 1 }}
                style={{ position: 'sticky', bottom: 16, left: 0, right: 0, display: 'flex', justifyContent: 'center' }}
              >
                <div style={{
                  padding: '8px 16px', borderRadius: 20,
                  background: 'rgba(8,12,20,0.92)',
                  border: '1px solid rgba(255,255,255,0.12)',
                  backdropFilter: 'blur(16px)',
                  fontSize: 12, color: 'var(--text-muted)',
                  display: 'flex', alignItems: 'center', gap: 8,
                }}>
                  <motion.span
                    animate={{ rotate: 360 }}
                    transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
                    style={{ display: 'inline-block' }}
                  >
                    ↻
                  </motion.span>
                  Fetching fresh songs…
                </div>
              </motion.div>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
PLAYLIST_EOF

echo "✅  Wrote new PlaylistsPage → $TARGET"

# ── 3. Ensure ytSearch exports searchYouTube ─────────────────────────────────
# The new page imports { searchYouTube } from ytSearch.js.
# Most versions of ytSearch already export a function that does a YouTube
# search by keyword.  We check for common export names and add an alias if
# the named export doesn't exist yet.

if [ -f "$YT_SEARCH" ]; then
  if ! grep -q "searchYouTube" "$YT_SEARCH"; then
    # Detect existing export name — common variants
    EXISTING=$(grep -oP "export (async )?function \K\w+" "$YT_SEARCH" | head -1)
    if [ -z "$EXISTING" ]; then
      EXISTING=$(grep -oP "export (const|let) \K\w+" "$YT_SEARCH" | head -1)
    fi

    if [ -n "$EXISTING" ]; then
      echo "" >> "$YT_SEARCH"
      echo "// Alias added by fix-playlists-dynamic.sh" >> "$YT_SEARCH"
      echo "export const searchYouTube = $EXISTING" >> "$YT_SEARCH"
      echo "✅  Added searchYouTube alias → $EXISTING (in $YT_SEARCH)"
    else
      echo "⚠️  Could not auto-detect export in $YT_SEARCH."
      echo "    Please add manually:  export { yourSearchFn as searchYouTube }"
    fi
  else
    echo "✅  ytSearch.js already exports searchYouTube — no changes needed."
  fi
else
  echo "⚠️  $YT_SEARCH not found. Make sure ytSearch exports:"
  echo "    export async function searchYouTube(query) { ... }"
fi

echo ""
echo "───────────────────────────────────────"
echo "🚀  Done! Restart the dev server:"
echo "    npm run dev"
echo ""
echo "How it works:"
echo "  • Click any playlist card → songs are fetched live from YouTube"
echo "  • Results are cached in localStorage for 30 minutes"
echo "  • Hit ↻ to force-refresh with fresh songs"
echo "  • 'Play All' loads the entire playlist into the queue"
echo "  • 8 curated playlists with genre-specific search queries"
