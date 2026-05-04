#!/usr/bin/env bash
# ============================================================
#  Mysic — Mini-Player v2 (fixed patch targets)
#  Run from project root:  bash add_mini_player_v2.sh
# ============================================================
set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}[Mysic] Adding Mini-Player (v2)...${NC}"

if [ ! -f "package.json" ]; then
  echo -e "${RED}  ✗ Run this from your project root${NC}"
  exit 1
fi

mkdir -p src/components

# ════════════════════════════════════════════════════════════
# 1.  src/components/MiniPlayer.jsx  (unchanged from v1)
# ════════════════════════════════════════════════════════════
cat > src/components/MiniPlayer.jsx << 'EOF'
import { useRef, useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence }                   from 'framer-motion'
import { usePlayer }                                 from '../hooks/usePlayer.jsx'
import AlbumArt                                      from './AlbumArt'

const EASE   = [0.25, 0.46, 0.45, 0.94]
const W      = 300
const H      = 76
const MARGIN = 18

function PillBtn({ children, onClick, primary = false, title }) {
  const [hov, setHov] = useState(false)
  return (
    <button
      title={title}
      onClick={onClick}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        width: 34, height: 34, borderRadius: '50%', border: 'none',
        flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: primary
          ? 'var(--accent-grad)'
          : hov ? 'rgba(255,255,255,0.10)' : 'rgba(255,255,255,0.04)',
        color:  primary ? '#08121f' : 'var(--text-secondary)',
        fontSize: primary ? 13 : 11,
        cursor: 'pointer',
        transition: 'background 0.15s',
        WebkitTapHighlightColor: 'transparent',
        touchAction: 'manipulation',
        boxShadow: primary ? '0 3px 12px rgba(34,211,238,0.40)' : 'none',
      }}
    >
      {children}
    </button>
  )
}

export default function MiniPlayer({ onClose, onExpand }) {
  const {
    currentSong, isPlaying, progress,
    togglePlay, playNext, playPrev,
  } = usePlayer()

  const startPos = useCallback(() => ({
    x: window.innerWidth  - W - MARGIN,
    y: window.innerHeight - H - MARGIN - 80,
  }), [])

  const [pos,      setPos]      = useState(startPos)
  const [dragging, setDragging] = useState(false)
  const dragStart = useRef({ mx: 0, my: 0, px: 0, py: 0 })

  const clamp = useCallback((x, y) => ({
    x: Math.max(MARGIN, Math.min(window.innerWidth  - W - MARGIN, x)),
    y: Math.max(MARGIN, Math.min(window.innerHeight - H - MARGIN, y)),
  }), [])

  const onPointerDown = useCallback(e => {
    if (e.target.closest('button')) return
    e.currentTarget.setPointerCapture(e.pointerId)
    setDragging(true)
    dragStart.current = { mx: e.clientX, my: e.clientY, px: pos.x, py: pos.y }
  }, [pos])

  const onPointerMove = useCallback(e => {
    if (!dragging) return
    const dx = e.clientX - dragStart.current.mx
    const dy = e.clientY - dragStart.current.my
    setPos(clamp(dragStart.current.px + dx, dragStart.current.py + dy))
  }, [dragging, clamp])

  const onPointerUp = useCallback(e => {
    e.currentTarget?.releasePointerCapture?.(e.pointerId)
    setDragging(false)
  }, [])

  useEffect(() => {
    const onResize = () => setPos(p => clamp(p.x, p.y))
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [clamp])

  useEffect(() => { setPos(startPos()) }, [startPos])

  const accentHex = currentSong.color || '#22d3ee'

  return (
    <motion.div
      initial={{ opacity: 0, y: 40, scale: 0.92 }}
      animate={{ opacity: 1, y: 0,  scale: 1    }}
      exit={{    opacity: 0, y: 40, scale: 0.92 }}
      transition={{ duration: 0.30, ease: EASE }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      style={{
        position: 'fixed',
        left: pos.x, top: pos.y,
        width: W, height: H,
        zIndex: 300,
        cursor: dragging ? 'grabbing' : 'grab',
        userSelect: 'none',
        background:           'rgba(8,12,20,0.92)',
        backdropFilter:       'blur(28px)',
        WebkitBackdropFilter: 'blur(28px)',
        border:               '1px solid rgba(255,255,255,0.10)',
        borderRadius:         22,
        boxShadow: `0 16px 48px rgba(0,0,0,0.55), 0 0 0 1px ${accentHex}18, inset 0 1px 0 rgba(255,255,255,0.06)`,
        fontFamily: 'var(--font-body)',
        overflow: 'hidden',
        display: 'flex', flexDirection: 'column',
      }}
    >
      {/* Ambient glow */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(ellipse 80% 60% at 10% 50%, ${accentHex}14 0%, transparent 70%)`,
        transition: 'background 0.8s ease',
      }} />

      {/* Main row */}
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center',
        gap: 10, padding: '0 10px 0 12px',
        position: 'relative', zIndex: 1,
      }}>
        {/* Album art */}
        <div onClick={onExpand} title="Open Now Playing" style={{ cursor: 'pointer', flexShrink: 0 }}>
          <AnimatePresence mode="wait">
            <motion.div
              key={currentSong.id}
              initial={{ opacity: 0, scale: 0.80 }}
              animate={{ opacity: 1, scale: 1    }}
              exit={{    opacity: 0, scale: 0.80 }}
              transition={{ duration: 0.20, ease: EASE }}
            >
              <AlbumArt song={currentSong} size="sm" isPlaying={isPlaying} />
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Track info */}
        <div onClick={onExpand} style={{ flex: 1, minWidth: 0, cursor: 'pointer' }}>
          <AnimatePresence mode="wait">
            <motion.div
              key={`t-${currentSong.id}`}
              initial={{ opacity: 0, y: 4  }}
              animate={{ opacity: 1, y: 0  }}
              exit={{    opacity: 0, y: -4 }}
              transition={{ duration: 0.18 }}
            >
              <p style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-primary)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {currentSong.title}
              </p>
              <p style={{ fontSize: 10, color: 'var(--text-muted)', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {currentSong.artist}
              </p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 2, flexShrink: 0 }}>
          <PillBtn title="Previous" onClick={e => { e.stopPropagation(); playPrev() }}>&#9198;</PillBtn>
          <PillBtn primary title={isPlaying ? 'Pause' : 'Play'} onClick={e => { e.stopPropagation(); togglePlay() }}>
            {isPlaying ? '\u23F8' : '\u25B6'}
          </PillBtn>
          <PillBtn title="Next" onClick={e => { e.stopPropagation(); playNext() }}>&#9197;</PillBtn>
        </div>

        {/* Dismiss */}
        <motion.button
          title="Close mini-player"
          onClick={e => { e.stopPropagation(); onClose() }}
          whileHover={{ scale: 1.18, rotate: 90 }}
          whileTap={{ scale: 0.85 }}
          style={{
            position: 'absolute', top: 6, right: 8,
            width: 18, height: 18, borderRadius: '50%',
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.12)',
            color: 'var(--text-muted)', fontSize: 9,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', WebkitTapHighlightColor: 'transparent',
          }}
        >✕</motion.button>
      </div>

      {/* Progress bar */}
      <div style={{ height: 3, background: 'rgba(255,255,255,0.06)', flexShrink: 0, position: 'relative', zIndex: 1 }}>
        <motion.div
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.9, ease: 'linear' }}
          style={{ height: '100%', background: 'var(--accent-grad)', borderRadius: '0 2px 2px 0' }}
        />
      </div>
    </motion.div>
  )
}
EOF
echo -e "${GREEN}  ✓ src/components/MiniPlayer.jsx${NC}"

# ════════════════════════════════════════════════════════════
# 2.  Patch Player.jsx — confirmed exact current file state
#     Add onMiniPlayer prop + pop-out button in the right toolbar
# ════════════════════════════════════════════════════════════
PLAYER="src/components/Player.jsx"

if [ ! -f "$PLAYER" ]; then
  echo -e "${YELLOW}  ⚠ $PLAYER not found${NC}"
else
python3 - "$PLAYER" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# A. Props line — confirmed exact text from file read
old_props = "export default function Player({ mobile = false, onNowPlayingClick, screenSize = 'desktop' }) {"
new_props  = "export default function Player({ mobile = false, onNowPlayingClick, onMiniPlayer, screenSize = 'desktop' }) {"
src = src.replace(old_props, new_props, 1)

# B. Insert pop-out button right before the closing of the right-col div
# Confirmed exact block from file — the right col ends with volume scrubber then </div> twice
# We target the LAST </div> before </div> (closing the !isTablet block)
# Most surgical: insert before the volume <div> closing tag
old_vol_end = (
    "          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>\n"
    "            <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>"
    "{volume === 0 ? '\\uD83D\\uDD07' : volume < 40 ? '\\uD83D\\uDD08' : '\\uD83D\\uDD0A'}</span>\n"
    "            <Scrubber pct={volume} onSeek={setVolume} width=\"80px\" "
    "accent=\"linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))\" />\n"
    "          </div>"
)
new_vol_end = (
    "          {/* Mini-player pop-out button */}\n"
    "          {onMiniPlayer && (\n"
    "            <motion.button\n"
    "              title=\"Pop out mini-player\"\n"
    "              onClick={onMiniPlayer}\n"
    "              whileHover={{ scale: 1.18 }}\n"
    "              whileTap={{ scale: 0.88 }}\n"
    "              style={{\n"
    "                background: 'none', border: 'none',\n"
    "                color: 'var(--text-muted)',\n"
    "                fontSize: 16, cursor: 'pointer',\n"
    "                display: 'flex', alignItems: 'center', justifyContent: 'center',\n"
    "                width: 32, height: 32, borderRadius: 8,\n"
    "                transition: 'color 0.18s',\n"
    "                WebkitTapHighlightColor: 'transparent',\n"
    "              }}\n"
    "              onMouseEnter={e => e.currentTarget.style.color = 'var(--accent-primary)'}\n"
    "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}\n"
    "            >\n"
    "              ⊟\n"
    "            </motion.button>\n"
    "          )}\n"
    "          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>\n"
    "            <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>"
    "{volume === 0 ? '\\uD83D\\uDD07' : volume < 40 ? '\\uD83D\\uDD08' : '\\uD83D\\uDD0A'}</span>\n"
    "            <Scrubber pct={volume} onSeek={setVolume} width=\"80px\" "
    "accent=\"linear-gradient(90deg, var(--accent-secondary), var(--accent-primary))\" />\n"
    "          </div>"
)
if 'Mini-player pop-out button' not in src:
    if old_vol_end in src:
        src = src.replace(old_vol_end, new_vol_end, 1)
    else:
        print('  ⚠  Player.jsx — volume block pattern not matched, using line-based insert')
        # Fallback: find the line with Scrubber width=80px and insert before its parent div
        lines = src.split('\n')
        insert_idx = None
        for i, line in enumerate(lines):
            if 'width="80px"' in line:
                # go back to find the opening div
                for j in range(i, max(0, i-3), -1):
                    if lines[j].strip().startswith('<div style={{ display'):
                        insert_idx = j
                        break
                break
        if insert_idx:
            popup_lines = [
                "          {/* Mini-player pop-out button */}",
                "          {onMiniPlayer && (",
                "            <motion.button",
                "              title=\"Pop out mini-player\"",
                "              onClick={onMiniPlayer}",
                "              whileHover={{ scale: 1.18 }}",
                "              whileTap={{ scale: 0.88 }}",
                "              style={{",
                "                background: 'none', border: 'none',",
                "                color: 'var(--text-muted)', fontSize: 16, cursor: 'pointer',",
                "                display: 'flex', alignItems: 'center', justifyContent: 'center',",
                "                width: 32, height: 32, borderRadius: 8,",
                "                transition: 'color 0.18s',",
                "                WebkitTapHighlightColor: 'transparent',",
                "              }}",
                "              onMouseEnter={e => e.currentTarget.style.color = 'var(--accent-primary)'}",
                "              onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}",
                "            >",
                "              \u229f",
                "            </motion.button>",
                "          )}",
            ]
            lines[insert_idx:insert_idx] = popup_lines
            src = '\n'.join(lines)

if src == original:
    print('  ⚠  Player.jsx — no changes made')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Player.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/Player.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 3.  Patch Layout.jsx — direct line-based rewrite
#     Confirmed exact current file: no keyboard shortcuts,
#     no prior mini-player patches. Pure original Layout.jsx.
# ════════════════════════════════════════════════════════════
LAYOUT="src/components/Layout.jsx"

if [ ! -f "$LAYOUT" ]; then
  echo -e "${YELLOW}  ⚠ $LAYOUT not found${NC}"
else
python3 - "$LAYOUT" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f: src = f.read()
original = src

# ── A. Add MiniPlayer import after PlaylistsPage import ──────
old_last_import = "import PlaylistsPage from '../pages/PlaylistsPage'"
new_last_import = (
    "import PlaylistsPage from '../pages/PlaylistsPage'\n"
    "import MiniPlayer    from './MiniPlayer'"
)
if 'MiniPlayer' not in src:
    src = src.replace(old_last_import, new_last_import, 1)

# ── B. Add showMini state after activePage state ─────────────
old_activepage = "  const [activePage,     setActivePage]     = useState('Home')"
new_activepage = (
    "  const [activePage,     setActivePage]     = useState('Home')\n"
    "  const [showMini,       setShowMini]       = useState(false)"
)
if 'showMini' not in src:
    src = src.replace(old_activepage, new_activepage, 1)

# ── C. Desktop <Player /> — inject onMiniPlayer prop ─────────
# Confirmed exact line 97 from file read:
#   <Player />
# inside the gridColumn '1/-1' div
old_desktop_player = "            <Player />"
new_desktop_player = "            <Player onMiniPlayer={() => setShowMini(true)} />"
if 'onMiniPlayer' not in src:
    src = src.replace(old_desktop_player, new_desktop_player, 1)

# ── D. Tablet <Player /> — inject onMiniPlayer prop ──────────
# Confirmed exact line 124:
#   <Player onNowPlayingClick={() => setNowPlayingOpen(true)} />
old_tablet_player = "            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} />"
new_tablet_player = "            <Player onNowPlayingClick={() => setNowPlayingOpen(true)} onMiniPlayer={() => setShowMini(true)} />"
src = src.replace(old_tablet_player, new_tablet_player, 1)

# ── E. Mobile <Player /> — inject onMiniPlayer prop ──────────
# Confirmed exact line 155:
#   <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} />
old_mobile_player = "          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} />"
new_mobile_player = "          <Player mobile onNowPlayingClick={() => setNowPlayingOpen(true)} onMiniPlayer={() => setShowMini(true)} />"
src = src.replace(old_mobile_player, new_mobile_player, 1)

# ── F. Render MiniPlayer + AnimatePresence at root level ─────
# Insert just before the closing </div> of the root div
# The root div closing is the very last two lines: "    </div>\n  )\n}"
old_closing = "    </div>\n  )\n}"
new_closing = (
    "\n"
    "      {/* Floating mini-player — renders over everything */}\n"
    "      <AnimatePresence>\n"
    "        {showMini && (\n"
    "          <MiniPlayer\n"
    "            onClose={() => setShowMini(false)}\n"
    "            onExpand={() => setShowMini(false)}\n"
    "          />\n"
    "        )}\n"
    "      </AnimatePresence>\n"
    "    </div>\n"
    "  )\n"
    "}"
)
if 'showMini &&' not in src:
    src = src.replace(old_closing, new_closing, 1)

if src == original:
    print('  ⚠  Layout.jsx — no changes made')
else:
    with open(path, 'w') as f: f.write(src)
    print('  ✓  Layout.jsx patched')
PYEOF
  echo -e "${GREEN}  ✓ src/components/Layout.jsx patched${NC}"
fi

# ════════════════════════════════════════════════════════════
# 4.  Verify patches applied correctly
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}  Verifying patches...${NC}"

python3 << 'PYEOF'
import sys

errors = []

# Check Layout.jsx
with open('src/components/Layout.jsx') as f: layout = f.read()
checks_layout = {
    'MiniPlayer import':    "import MiniPlayer    from './MiniPlayer'",
    'showMini state':       'const [showMini,       setShowMini]',
    'desktop onMiniPlayer': 'onMiniPlayer={() => setShowMini(true)}',
    'AnimatePresence wrap': 'showMini &&',
    'MiniPlayer render':    '<MiniPlayer',
}
for name, pat in checks_layout.items():
    if pat in layout:
        print(f'    Layout.jsx — {name} ✓')
    else:
        errors.append(f'    Layout.jsx — {name} MISSING')

# Check Player.jsx
with open('src/components/Player.jsx') as f: player = f.read()
checks_player = {
    'onMiniPlayer prop':   'onMiniPlayer,',
    'pop-out button':      'Mini-player pop-out button',
}
for name, pat in checks_player.items():
    if pat in player:
        print(f'    Player.jsx — {name} ✓')
    else:
        errors.append(f'    Player.jsx — {name} MISSING')

# Check MiniPlayer exists
import os
if os.path.exists('src/components/MiniPlayer.jsx'):
    print(f'    MiniPlayer.jsx — file exists ✓')
else:
    errors.append('    MiniPlayer.jsx — file MISSING')

if errors:
    print('\n  WARNINGS:')
    for e in errors: print(e)
    sys.exit(1)
else:
    print('\n  All checks passed ✓')
PYEOF

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Mini-Player installed successfully!            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Files created:${NC}"
echo -e "    + src/components/MiniPlayer.jsx"
echo ""
echo -e "  ${CYAN}Files patched:${NC}"
echo -e "    ~ src/components/Player.jsx    — ⊟ pop-out button added"
echo -e "    ~ src/components/Layout.jsx    — showMini state + MiniPlayer render"
echo ""
echo -e "  ${CYAN}How to use:${NC}"
echo -e "    • Click ⊟ button in player bar right side (near volume)"
echo -e "    • Pill appears bottom-right, fully draggable"
echo -e "    • Prev / Play-Pause / Next inside the pill"
echo -e "    • Progress bar along pill bottom edge"
echo -e "    • Click album art or title to dismiss + return to main"
echo -e "    • × top-right of pill to close"
echo ""
echo -e "  ${CYAN}Restart dev server:${NC}  npm run dev"
