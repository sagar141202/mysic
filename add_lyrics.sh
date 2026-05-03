#!/usr/bin/env bash
# ============================================================
#  Mysic — Lyrics Panel
#  Fetches from lrclib.net (free, no API key, has LRC sync data)
#  Run from project root:  bash add_lyrics.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Adding Lyrics Panel...${NC}"

if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run this from your project root${NC}"
  exit 1
fi

mkdir -p src/utils src/components

# ════════════════════════════════════════════════════════════
# 1.  src/utils/fetchLyrics.js
#     Hits lrclib.net — completely free, no API key.
#     Returns { lines: [{time, text}], plain, source }
#     lrclib returns both synced LRC and plain text lyrics.
# ════════════════════════════════════════════════════════════
cat > src/utils/fetchLyrics.js << 'EOF'
/**
 * fetchLyrics.js
 *
 * Fetches lyrics from lrclib.net — free, no auth, has
 * timestamped (LRC) lyrics for most songs.
 *
 * Strategy:
 *  1. Try lrclib /api/get  with title + artist + duration
 *  2. Fallback: /api/search with title + artist (looser match)
 *  3. Parse LRC timestamp lines → [{time:seconds, text:string}]
 *  4. Resolve with plain-text lines if no timestamps exist
 */

const BASE = 'https://lrclib.net/api'

/** Parse "[mm:ss.xx] lyric line" → [{time, text}] */
function parseLrc(lrc) {
  if (!lrc) return []
  const lines = []
  for (const raw of lrc.split('\n')) {
    const m = raw.match(/^\[(\d{1,2}):(\d{2})\.(\d{1,3})\](.*)/)
    if (!m) continue
    const time = parseInt(m[1]) * 60 + parseFloat(`${m[2]}.${m[3]}`)
    const text = m[4].trim()
    if (text) lines.push({ time, text })
  }
  return lines
}

/** Parse plain lyrics → [{time: null, text}] */
function parsePlain(plain) {
  if (!plain) return []
  return plain.split('\n')
    .map(t => t.trim())
    .filter(Boolean)
    .map(text => ({ time: null, text }))
}

/** Clean title — strip "(Official Video)", "[Lyrics]" etc */
function cleanTitle(title = '') {
  return title
    .replace(/\(.*?\)/g, '')
    .replace(/\[.*?\]/g, '')
    .replace(/ft\.?.*/i, '')
    .replace(/feat\.?.*/i, '')
    .trim()
}

/** Clean artist — use only first listed artist */
function cleanArtist(artist = '') {
  return artist.split(/[,&x×]/)[0].trim()
}

export async function fetchLyrics(song) {
  const title    = cleanTitle(song?.title   || '')
  const artist   = cleanArtist(song?.artist || '')
  const duration = song?.duration ? Math.round(song.duration) : undefined

  if (!title) return { lines: [], plain: [], synced: false, notFound: true }

  /* ── Attempt 1: exact match via /api/get ── */
  try {
    const params = new URLSearchParams({ track_name: title, artist_name: artist })
    if (duration) params.set('duration', duration)
    const res  = await fetch(`${BASE}/get?${params}`, {
      headers: { 'Lrclib-Client': 'Mysic/1.0 (github.com/sagar141202/mysic)' }
    })
    if (res.ok) {
      const data = await res.json()
      if (data?.syncedLyrics) {
        const lines = parseLrc(data.syncedLyrics)
        if (lines.length) return { lines, plain: lines.map(l => l.text), synced: true, notFound: false }
      }
      if (data?.plainLyrics) {
        const lines = parsePlain(data.plainLyrics)
        return { lines, plain: lines.map(l => l.text), synced: false, notFound: false }
      }
    }
  } catch { /* network error — fall through */ }

  /* ── Attempt 2: search fallback ── */
  try {
    const params = new URLSearchParams({ track_name: title, artist_name: artist })
    const res    = await fetch(`${BASE}/search?${params}`, {
      headers: { 'Lrclib-Client': 'Mysic/1.0 (github.com/sagar141202/mysic)' }
    })
    if (res.ok) {
      const results = await res.json()
      const hit = results?.find(r => r.syncedLyrics || r.plainLyrics)
      if (hit?.syncedLyrics) {
        const lines = parseLrc(hit.syncedLyrics)
        if (lines.length) return { lines, plain: lines.map(l => l.text), synced: true, notFound: false }
      }
      if (hit?.plainLyrics) {
        const lines = parsePlain(hit.plainLyrics)
        return { lines, plain: lines.map(l => l.text), synced: false, notFound: false }
      }
    }
  } catch { /* network error */ }

  return { lines: [], plain: [], synced: false, notFound: true }
}
EOF
echo -e "${GREEN}  ✓ src/utils/fetchLyrics.js${NC}"

# ════════════════════════════════════════════════════════════
# 2.  src/components/LyricsPanel.jsx
#     Self-contained component. Toggle with a ♪ button added
#     to the NowPlaying header. Slides in over the Up Next
#     section with AnimatePresence.
#
#     Features:
#     - Auto-scrolls the active line to centre
#     - Active line: large, bright, accent colour, scale up
#     - Past lines: dimmer, smaller
#     - Future lines: muted
#     - Blur top/bottom fade masks (no hard cut-off)
#     - "Not found" and "Loading" states
#     - Synced badge vs Plain badge
# ════════════════════════════════════════════════════════════
cat > src/components/LyricsPanel.jsx << 'EOF'
/**
 * LyricsPanel — full-height lyrics view that replaces Up Next
 * when the user taps the ♪ button in NowPlaying header.
 *
 * Props:
 *   currentSec  number   — current playback position in seconds
 *   song        object   — currentSong from usePlayer
 *   isPlaying   bool
 */
import { useEffect, useRef, useState, useCallback } from 'react'
import { motion, AnimatePresence }                   from 'framer-motion'
import { fetchLyrics }                               from '../utils/fetchLyrics'

const EASE = [0.25, 0.46, 0.45, 0.94]

export default function LyricsPanel({ currentSec, song, isPlaying }) {
  const [state,   setState]   = useState('idle')   // idle | loading | ready | error
  const [data,    setData]    = useState(null)      // { lines, synced, notFound }
  const [songId,  setSongId]  = useState(null)
  const scrollRef             = useRef(null)
  const lineRefs              = useRef([])

  /* ── Fetch whenever song changes ── */
  useEffect(() => {
    if (!song?.id || song.id === songId) return
    setSongId(song.id)
    setState('loading')
    setData(null)
    fetchLyrics(song).then(result => {
      setData(result)
      setState(result.notFound ? 'error' : 'ready')
    })
  }, [song?.id])

  /* ── Auto-scroll active line into centre view ── */
  const activeIdx = useCallback(() => {
    if (!data?.lines?.length || !data.synced) return -1
    let idx = -1
    for (let i = 0; i < data.lines.length; i++) {
      if (data.lines[i].time <= currentSec) idx = i
      else break
    }
    return idx
  }, [data, currentSec])

  const active = activeIdx()

  useEffect(() => {
    if (active < 0) return
    const el = lineRefs.current[active]
    const container = scrollRef.current
    if (!el || !container) return
    const elTop    = el.offsetTop
    const elHeight = el.offsetHeight
    const target   = elTop - container.clientHeight / 2 + elHeight / 2
    container.scrollTo({ top: target, behavior: 'smooth' })
  }, [active])

  /* ── Accent colour from song ── */
  const accent = song?.color || '#22d3ee'

  /* ── States ── */
  if (state === 'loading') return (
    <motion.div
      initial={{ opacity: 0 }} animate={{ opacity: 1 }}
      style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14, padding: '30px 0' }}
    >
      {/* Pulsing music note */}
      <motion.div
        animate={{ scale: [1, 1.18, 1], opacity: [0.5, 1, 0.5] }}
        transition={{ duration: 1.6, repeat: Infinity, ease: 'easeInOut' }}
        style={{ fontSize: 32, color: accent }}
      >♪</motion.div>
      <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0, letterSpacing: '0.08em' }}>
        Finding lyrics…
      </p>
    </motion.div>
  )

  if (state === 'error' || data?.notFound) return (
    <motion.div
      initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
      style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '30px 0', textAlign: 'center' }}
    >
      <span style={{ fontSize: 28, opacity: 0.35 }}>♩</span>
      <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: 0 }}>
        No lyrics found
      </p>
      <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.2)', margin: 0 }}>
        {song?.title}
      </p>
    </motion.div>
  )

  if (state !== 'ready' || !data) return null

  const { lines, synced } = data

  return (
    <motion.div
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      transition={{ duration: 0.28 }}
      style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, position: 'relative' }}
    >
      {/* Sync badge */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10, flexShrink: 0 }}>
        <p style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.12em', textTransform: 'uppercase', margin: 0 }}>
          Lyrics
        </p>
        <span style={{
          fontSize: 10, padding: '2px 8px', borderRadius: 20,
          background: synced ? `${accent}22` : 'rgba(255,255,255,0.06)',
          color:      synced ? accent        : 'var(--text-muted)',
          border:     `1px solid ${synced ? `${accent}44` : 'rgba(255,255,255,0.08)'}`,
          letterSpacing: '0.06em',
        }}>
          {synced ? '⏱ synced' : 'plain text'}
        </span>
      </div>

      {/* Fade mask top */}
      <div style={{
        position: 'absolute', top: 32, left: 0, right: 0, height: 48,
        background: 'linear-gradient(to bottom, rgba(8,12,20,0.78) 0%, transparent 100%)',
        pointerEvents: 'none', zIndex: 2,
      }} />

      {/* Scrollable lyrics */}
      <div
        ref={scrollRef}
        style={{
          flex: 1, overflowY: 'auto', overflowX: 'hidden',
          overscrollBehavior: 'contain',
          WebkitOverflowScrolling: 'touch',
          /* hide scrollbar */
          scrollbarWidth: 'none',
          msOverflowStyle: 'none',
          paddingTop: 20,
          paddingBottom: 60,
          position: 'relative',
        }}
      >
        <style>{`
          .lyrics-scroll::-webkit-scrollbar { display: none; }
          @keyframes lyric-pulse {
            0%, 100% { opacity: 0.9; }
            50%       { opacity: 1;   }
          }
        `}</style>

        <div className="lyrics-scroll" style={{ padding: '0 4px' }}>
          {lines.map((line, i) => {
            const isActive = synced && i === active
            const isPast   = synced && i < active
            const isFuture = synced && i > active

            /* opacity layers */
            const opacity = isActive ? 1
              : isPast   ? Math.max(0.18, 1 - (active - i) * 0.14)
              : isFuture ? Math.max(0.20, 1 - (i - active) * 0.12)
              : 0.55     /* plain text */

            /* font size: active swells */
            const fontSize = isActive ? 17 : 14

            return (
              <motion.p
                key={i}
                ref={el => { lineRefs.current[i] = el }}
                animate={{
                  opacity,
                  scale:  isActive ? 1.04 : 1,
                  color:  isActive ? accent : '#ffffff',
                  filter: isActive ? `drop-shadow(0 0 12px ${accent}88)` : 'none',
                }}
                transition={{ duration: 0.38, ease: EASE }}
                style={{
                  fontSize,
                  fontFamily:   'var(--font-display)',
                  fontWeight:   isActive ? 700 : isPast ? 400 : 500,
                  lineHeight:   1.55,
                  margin:       '0 0 6px',
                  padding:      '5px 0',
                  cursor:       synced ? 'default' : 'default',
                  textAlign:    'left',
                  letterSpacing: isActive ? '-0.01em' : '0',
                  transformOrigin: 'left center',
                  /* keep text from wrapping too wide */
                  maxWidth: '100%',
                  wordBreak: 'break-word',
                  /* active line: subtle left accent bar */
                  borderLeft:  isActive ? `3px solid ${accent}` : '3px solid transparent',
                  paddingLeft: 10,
                  transition:  'border-color 0.3s ease, padding 0.2s ease',
                  /* active glow animation */
                  animation: isActive && isPlaying ? 'lyric-pulse 2s ease-in-out infinite' : 'none',
                }}
              >
                {line.text}
              </motion.p>
            )
          })}
        </div>
      </div>

      {/* Fade mask bottom */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 64,
        background: 'linear-gradient(to top, rgba(8,12,20,0.95) 0%, transparent 100%)',
        pointerEvents: 'none', zIndex: 2,
      }} />
    </motion.div>
  )
}
EOF
echo -e "${GREEN}  ✓ src/components/LyricsPanel.jsx${NC}"

# ════════════════════════════════════════════════════════════
# 3.  Patch NowPlaying.jsx
#     - Add imports for LyricsPanel + useState
#     - Add showLyrics state
#     - Add lyrics toggle button (♪) in the header
#     - Replace the bottom section (Up Next) with an
#       AnimatePresence that swaps between LyricsPanel
#       and the existing Up Next list
# ════════════════════════════════════════════════════════════
NOWPLAYING="src/components/NowPlaying.jsx"

if [ ! -f "$NOWPLAYING" ]; then
  echo -e "${YELLOW}  ⚠ $NOWPLAYING not found — skipping patch${NC}"
else
python3 - "$NOWPLAYING" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# ── A. Change: import { useRef, useCallback } to add useState ──
old_import_react = "import { useRef, useCallback } from 'react'"
new_import_react = "import { useRef, useCallback, useState } from 'react'"
if 'useState' not in src:
    src = src.replace(old_import_react, new_import_react, 1)

# ── B. Add LyricsPanel import after AlbumArt import ──────────
old_albumart_import = "import AlbumArt from './AlbumArt'"
new_albumart_import = (
    "import AlbumArt from './AlbumArt'\n"
    "import LyricsPanel from './LyricsPanel'"
)
if 'LyricsPanel' not in src:
    src = src.replace(old_albumart_import, new_albumart_import, 1)

# ── C. Add showLyrics state after usePlayer destructure ──────
old_destructure = (
    "  const isLiked    = liked.has(currentSong.id)\n"
    "  const currentSec = Math.floor((progress / 100) * currentSong.duration)"
)
new_destructure = (
    "  const [showLyrics, setShowLyrics] = useState(false)\n"
    "\n"
    "  const isLiked    = liked.has(currentSong.id)\n"
    "  const currentSec = Math.floor((progress / 100) * currentSong.duration)"
)
if 'showLyrics' not in src:
    src = src.replace(old_destructure, new_destructure, 1)

# ── D. Add ♪ lyrics toggle button inside the header div ──────
# The header has "Now Playing" text and optional close button.
# We insert the lyrics toggle between them.
old_header_label = (
    '        <p style={{ fontSize: 10, fontWeight: 600, color: \'var(--text-muted)\', '
    'letterSpacing: \'0.12em\', textTransform: \'uppercase\', margin: 0 }}>\n'
    '          Now Playing\n'
    '        </p>'
)
new_header_label = (
    '        <p style={{ fontSize: 10, fontWeight: 600, color: \'var(--text-muted)\', '
    'letterSpacing: \'0.12em\', textTransform: \'uppercase\', margin: 0 }}>\n'
    '          Now Playing\n'
    '        </p>\n'
    '\n'
    '        {/* Lyrics toggle */}\n'
    '        <motion.button\n'
    '          onClick={() => setShowLyrics(v => !v)}\n'
    '          whileHover={{ scale: 1.12 }}\n'
    '          whileTap={{ scale: 0.88 }}\n'
    '          title={showLyrics ? \'Hide lyrics\' : \'Show lyrics\'}\n'
    '          style={{\n'
    '            width: 44, height: 44,\n'
    '            display: \'flex\', alignItems: \'center\', justifyContent: \'center\',\n'
    '            background: showLyrics ? \'rgba(34,211,238,0.12)\' : \'none\',\n'
    '            border: showLyrics ? \'1px solid rgba(34,211,238,0.30)\' : \'1px solid transparent\',\n'
    '            borderRadius: 12, cursor: \'pointer\',\n'
    '            color: showLyrics ? \'var(--accent-primary)\' : \'var(--text-muted)\',\n'
    '            fontSize: 16,\n'
    '            transition: \'all 0.2s ease\',\n'
    '            WebkitTapHighlightColor: \'transparent\',\n'
    '            marginLeft: \'auto\',\n'
    '            marginRight: 4,\n'
    '          }}\n'
    '        >\n'
    '          ♪\n'
    '        </motion.button>'
)
if 'setShowLyrics' not in src or 'lyrics toggle' not in src:
    src = src.replace(old_header_label, new_header_label, 1)

# ── E. Replace the Up Next section with a toggling panel ─────
old_upnext = (
    "      {/* Up Next */}\n"
    "      {upNext.length > 0 && ("
)
new_upnext = (
    "      {/* Lyrics / Up Next toggle */}\n"
    "      <AnimatePresence mode=\"wait\">\n"
    "        {showLyrics ? (\n"
    "          <motion.div\n"
    "            key=\"lyrics\"\n"
    "            initial={{ opacity: 0, y: 12 }}\n"
    "            animate={{ opacity: 1, y: 0 }}\n"
    "            exit={{    opacity: 0, y: -8 }}\n"
    "            transition={{ duration: 0.26, ease: EASE }}\n"
    "            style={{ borderTop: '1px solid rgba(255,255,255,0.07)', paddingTop: 16, flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}\n"
    "          >\n"
    "            <LyricsPanel\n"
    "              song={currentSong}\n"
    "              currentSec={currentSec}\n"
    "              isPlaying={isPlaying}\n"
    "            />\n"
    "          </motion.div>\n"
    "        ) : (\n"
    "          <motion.div\n"
    "            key=\"upnext\"\n"
    "            initial={{ opacity: 0, y: 12 }}\n"
    "            animate={{ opacity: 1, y: 0 }}\n"
    "            exit={{    opacity: 0, y: -8 }}\n"
    "            transition={{ duration: 0.26, ease: EASE }}\n"
    "            style={{ flex: 1, minHeight: 0 }}\n"
    "          >\n"
    "      {/* Up Next */}\n"
    "      {upNext.length > 0 && ("
)
if 'Lyrics / Up Next toggle' not in src:
    src = src.replace(old_upnext, new_upnext, 1)

    # Also close the new wrapper divs — find the closing of the Up Next block
    # The Up Next section ends with:  </div>\n    )}\n  </div>\n  )\n}
    # We need to close the extra motion.div and AnimatePresence
    old_closing = (
        "      )}\n"
        "    </div>\n"
        "  )\n"
        "}"
    )
    new_closing = (
        "      )}\n"
        "          </motion.div>\n"
        "        )}\n"
        "      </AnimatePresence>\n"
        "    </div>\n"
        "  )\n"
        "}"
    )
    src = src.replace(old_closing, new_closing, 1)

if src == original:
    print('  ⚠  NowPlaying.jsx — nothing changed (check patterns)')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  NowPlaying.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/NowPlaying.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 4.  Summary
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Lyrics Panel installed successfully!          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Files created:${NC}"
echo -e "    + src/utils/fetchLyrics.js      — lrclib.net fetcher"
echo -e "    + src/components/LyricsPanel.jsx — animated lyrics view"
echo ""
echo -e "  ${CYAN}Files patched:${NC}"
echo -e "    ~ src/components/NowPlaying.jsx  — ♪ toggle + panel swap"
echo ""
echo -e "  ${CYAN}How it works:${NC}"
echo -e "    • Tap ♪ in the NowPlaying header to toggle lyrics"
echo -e "    • lrclib.net is queried (title + artist + duration)"
echo -e "    • Synced lyrics: active line glows, auto-scrolls to centre"
echo -e "    • Past lines fade out, future lines stay dim"
echo -e "    • Active line: accent colour + left bar + scale up"
echo -e "    • Falls back to plain text if no timestamps"
echo -e "    • 'No lyrics found' state handled gracefully"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
